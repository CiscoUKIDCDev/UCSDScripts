# Copyright Matt Day
# Copying and distribution of this file, with or without modification,
# are permitted in any medium to Cisco Systems Employees without royalty
# provided the copyright notice and this notice are preserved. This
# file is offered as-is, without any warranty.

# This script queries UCS Director at specific intervals to provide various stats including cost per hour,
# average CPU usage and the % powered up

require 'json'

# Init the graph with some random values to make it look good :)
points = []
(1..10).each do |i|
  points << { x: i, y: rand(50) }
end

# Stolen from Amazon, 5p an hour seems to be about the going rate for a basic VM
vm_cost_per_hour = 0.05
# Why not? :) - still uses storaage...
powered_off_vm_cost_per_hour = 0.01

last_cost = 0

SCHEDULER.every '20s' do
	# Lazy way to get this, should use libraries rather than syscalls to curl...
	vm_list = JSON.parse(`http_proxy="" proxy="" curl -s -X "GET" "http://10.52.208.38/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%220%22,param1:%22All%20Clouds%22,param2:%22VMS-T0%22%7D" -H "x-cloupia-request-key: D47D6DD47B99423D9E499848DDF6D0A9"`)

	
	vm_count = 1
	counted_vm_count = 1
	total_cpu = 0
	vm_powered_on = 0

	# Iterate through list of VMs procured from above REST call
	vm_list["serviceResult"]["rows"].each do |vm|
		# Construct a cURL command to pull down specific info on the VM (the VM ID) - some VMs 
		# may not exist and this is an exceptionally lazy way to get the info (but functional)
		cmd = "http_proxy=\"\" curl -s -X \"GET\" \"http://10.52.208.38/app/api/rest?formatType=json&opName=userAPIGetHistoricalReport&opData=%7Bparam0:%22vm%22,param1:%22" + vm_count.to_s + "%22,param2:%22TREND-CPU-USAGE-(MHZ)-H0%22,param3:%22hourly%22%7D\" -H \"x-cloupia-request-key: D47D6DD47B99423D9E499848DDF6D0A9\""
		# Again very lazy
		request = `#{cmd}`
		# Error checking due to above laziness:
		if (!request.match(/REMOTE_SERVICE_EXCEPTION/)) then
			history_graph = JSON.parse(request)
			# If we've gotten this far, it's possible there's no CPU stats (values) for the VM
			# we check here (.any?) and if it exists we add the current average CPU utilisation to the running
			# total
			if (history_graph["serviceResult"]["series"][0]["values"].any?) then
				total_cpu += history_graph["serviceResult"]["series"][0]["values"][0]["avg"]
				counted_vm_count += 1
			end
		end
		if (vm["Power_State"] == "ON") then
			vm_powered_on += 1
		end
		vm_count += 1
	end
	# Calculate mean CPU average and how many VMs are powered up (or at least giving us stats)
	powered_on_percent = vm_powered_on
	cpu_average = (total_cpu / counted_vm_count)
	# Round to nearest whole decimal, Ruby uses floating point logic and it can go wrong...
	cpu_average = cpu_average.round()

	# Send the events to the dashboards, the graph is sent as a set of x,y coordinates - plotting powered-up VMs
	# against CPU usage
	send_event('powered', { value: powered_on_percent })
	points << { x: (counted_vm_count / 10), y: cpu_average }
	send_event('convergence', points: points)

	# Calculate rough cost to 2 decimal places - should sprintf this to x.xx
	current_cost = (vm_cost_per_hour * counted_vm_count).round(2)
	send_event('valuation', { current: current_cost, last: last_cost })
	send_event('karma', { current: current_cost, last: last_cost })

	last_cost = current_cost
end

