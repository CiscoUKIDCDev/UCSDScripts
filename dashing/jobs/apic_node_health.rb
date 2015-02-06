# Copyright Matt Day
# Copying and distribution of this file, with or without modification,
# are permitted in any medium to Cisco Systems Employees without royalty
# provided the copyright notice and this notice are preserved. This
# file is offered as-is, without any warranty.

# This script reports the health scores for the bottom 5 nodes in an ACI
# infrastructure

require 'net/http'
require 'json'
show = 5

uri = URI('http://10.52.208.38/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%22551%22,param1:%22APIC-BEDFONT%22,param2:%22NODES-HEALTH-T52%22%7D')

SCHEDULER.every '30s' do
	tenant_count = 0

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
		response = JSON.parse(res.body)
		# hahes to store results
		node_list = Hash.new(0)
		status = Hash.new(0)
		# Loop through all tenants
		response["serviceResult"]["rows"].each do |node|
			# Add entry to hash:
			node_list[node["Node_Name"]] = node["Health_Score"]
		end
		shown = 0;
		# Sort nodes by health %
		node_list.keys.sort_by { |key| node_list[key] }.each do |key|
			status[key] = { label: key, value: (node_list[key].to_i) }
			shown += 1
			# Only show top 'n'
			if (shown > show) then
				break
			end
		end
		# Send event to dashing:
		send_event('apic_node_list', { items: status.values } )
	end
end
