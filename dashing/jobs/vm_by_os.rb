require 'json'

SCHEDULER.every '120s' do
	response = JSON.parse(`http_proxy="" proxy="" curl -s -X "GET" "http://10.52.208.38/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%221%22,param1:%22UKIDCV-VC%22,param2:%22VMS-T0%22%7D" -H "x-cloupia-request-key: D47D6DD47B99423D9E499848DDF6D0A9"`)

	vm_count = Hash.new(0)
	status = Hash.new(0)

	response["serviceResult"]["rows"].each do |vm|
		vm_count[vm["Guest_OS_Type"]] += 1
	end

        vm_count.keys.sort_by { |key| vm_count[key] }.reverse.each do
        |key|
        	status[key] = { label: key, value: (vm_count[key].to_i) }
        end
	send_event('vm_by_os', { items: status.values } )

end

