require 'json'

vm_cost_per_hour = 0.05
current_cost = 0
last_cost = 0

SCHEDULER.every '30s' do
	response = JSON.parse(`http_proxy="" proxy="" curl -s -X "GET" "http://10.52.208.38/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%221%22,param1:%22UKIDCV-VC%22,param2:%22VMS-T0%22%7D" -H "x-cloupia-request-key: D47D6DD47B99423D9E499848DDF6D0A9"`)

	status = Hash.new(0)
	vm_count = 0

	response["serviceResult"]["rows"].each do |vm|
		vm_count += 1
	end
	current_cost = vm_count * vm_cost_per_hour
	current_cost = current_cost.round(2)

	send_event('valuation', { current: current_cost, last: last_cost })
	send_event('karma', { current: current_cost, last: last_cost })

	last_cost = current_cost

end

