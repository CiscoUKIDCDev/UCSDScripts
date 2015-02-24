# Copyright Matt Day
# Copying and distribution of this file, with or without modification,
# are permitted in any medium to Cisco Systems Employees without royalty
# provided the copyright notice and this notice are preserved. This
# file is offered as-is, without any warranty.

# This script probes UCS Director for accurate hourly costing using the
# built-in charge-back features

require 'net/http'
require 'json'

# UCS Director API Call URL:
uri = URI('http://10.52.208.38/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%226%22,param1:%22%22,param2:%22CHARGEBACK-T12%22%7D')

# Keep track of the last cost value:
last_cost = 0
current_cost = 0

SCHEDULER.every '120s' do
	# http request
	req = Net::HTTP::Get.new(uri.request_uri)
	# Add API key
	req.add_field "X-Cloupia-Request-Key", "D47D6DD47B99423D9E499848DDF6D0A9"
	# Fetch Request
	res = Net::HTTP.start(uri.hostname, uri.port) {|http|
		http.request(req)
	}
	# If we get a HTTP 200 (OK) response then parse:
	if (res.code == "200") then
		# Parse JSON response (assume it's valid)
		vm_list = JSON.parse(res.body)
		current_cost = 0

		# Iterate through list of VMs procured from above REST call
		vm_list["serviceResult"]["rows"].each do |vm|
			if ((vm["Total_Cost"] != 0) && (vm["Active_VM_Hours"] != 0)) then
				total_time = (vm["Active_VM_Hours"].to_f + vm["Inactive_VM_Hours"].to_f)
				total_cost = (vm["Total_Cost"] - vm["One_time_Cost"])
				current_cost += (total_cost / total_time)

			end
		end
		current_cost = current_cost.round(2)
		
		# Calculate rough cost to 2 decimal places - should sprintf this to x.xx
		send_event('realvaluation', { current: current_cost, last: last_cost })
#		send_event('realkarma', { current: current_cost, last: last_cost })

		last_cost = current_cost
	end
end
