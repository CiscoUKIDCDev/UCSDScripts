require 'json'

points = []
(1..10).each do |i|
  points << { x: i, y: rand(50) }
end

vm_cost_per_hour = 0.05

last_cost = 0

SCHEDULER.every '20s' do
	vm_list = JSON.parse(`http_proxy="" proxy="" curl -s -X "GET" "http://10.52.208.38/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%221%22,param1:%22UKIDCV-VC%22,param2:%22VMS-T0%22%7D" -H "x-cloupia-request-key: D47D6DD47B99423D9E499848DDF6D0A9"`)
	
	vm_count = 1
	counted_vm_count = 1
	total_cpu = 0

	vm_list["serviceResult"]["rows"].each do |vm|
		cmd = "http_proxy=\"\" curl -s -X \"GET\" \"http://10.52.208.38/app/api/rest?formatType=json&opName=userAPIGetHistoricalReport&opData=%7Bparam0:%22vm%22,param1:%22" + vm_count.to_s + "%22,param2:%22TREND-CPU-USAGE-(MHZ)-H0%22,param3:%22hourly%22%7D\" -H \"x-cloupia-request-key: D47D6DD47B99423D9E499848DDF6D0A9\""
		request = `#{cmd}`
		if (!request.match(/REMOTE_SERVICE_EXCEPTION/)) then
			history_graph = JSON.parse(request)
			if (history_graph["serviceResult"]["series"][0]["values"].any?) then
				total_cpu += history_graph["serviceResult"]["series"][0]["values"][0]["avg"]
				counted_vm_count += 1
			end
		end
		vm_count += 1
	end
	cpu_average = (total_cpu / counted_vm_count)
	powered_on_percent = counted_vm_count
	send_event('powered', { value: powered_on_percent })
	cpu_average = cpu_average.round()
	points << { x: (counted_vm_count / 10), y: cpu_average }
	send_event('convergence', points: points)

	current_cost = (vm_cost_per_hour * counted_vm_count).round(2)
	send_event('valuation', { current: current_cost, last: last_cost })
	send_event('karma', { current: current_cost, last: last_cost })

	last_cost = current_cost


end

