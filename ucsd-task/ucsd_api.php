<?php
/*
Copyright Matt Day

Copying and distribution of this file, with or without modification,
are permitted in any medium to Cisco Sytems Employees without royalty
provided the copyright notice and this notice are preserved.  This
file is offered as-is, without any warranty.
*/

function ucsd_api_call ($query_string) {
	# UCSD API Key
	$ucsd_api_key = 'D47D6DD47B99423D9E499848DDF6D0A9';
	# URL for requests
	$ucsd_api_url = 'http://10.52.208.38/app/api/rest?';
	# cURL standard command:
	$curl_cmd = 'http_proxy="" curl -X "GET" -s ';
	$ucsd_api_cmd = ' -H "X-Cloupia-Request-Key: '.$ucsd_api_key.'"';
	$cmd = $curl_cmd.'"'.$ucsd_api_url.$query_string.'"'.$ucsd_api_cmd;
	$response = `http_proxy="" $cmd`;
	return json_decode($response);
}

function ucsd_input_supported($type) {
	if (($type == "gen_text_input") || ($type == "vm") || ($type == "vCPUCount") || ($type == 'memSizeMB')) {
		return true;
	}
	return false;
}

function return_custom_form($input) {
	$type = $input->{'type'};
	switch ($type) {
		case gen_text_input:
			return create_plain_text_form($input);
		case vm:
			return create_vm_picker($input);
		case memSizeMB:
			return create_memory_picker($input);
		case vCPUCount:
			return create_cpu_picker($input);
		default:
			return "Unsupported field type: ".$type;

	}
}

function create_cpu_picker($input) {
	$name = $input->{'name'};
	$out = '<tr><td><label for="'.$name.'">'.$input->{'label'}.':&nbsp; &nbsp;</label></td><td>';
	$out .= create_number_picker($name, 1, 8);
	$out .= '</td></tr>';
	
	return $out;
}


function create_plain_text_form($input) {
	$name = $input->{'name'};
	$out = '<tr><td><label for="'.$name.'">'.$input->{'label'}.':&nbsp; &nbsp;</label></td><td>';
	# Hack for a number picker for certain tasks... Could be done with custom input on UCSD or some other way to match certain inputs
	if ((preg_match('/^Number of /', $input->{'label'}))) {
		$out .= create_number_picker($input->{'name'}, 1, 5);
	}
	else {
		$out .= '<input type="text" name="'.$input->{'name'}.'" id="'.$input->{'name'}.'" />'."\n";
	}
	$out .= '</td></tr>';
	
	return $out."\n";
}

function create_memory_picker($input) {
	$name = $input->{'name'};
	$out = '<tr><td><label for="'.$name.'">'.$input->{'label'}.':&nbsp; &nbsp;</label></td>';
	$out .= '<td><select name="'.$name.'" id="'.$name.'">';
	$out .= '<option value="256">256 MiB</option>';
	$out .= '<option value="512">512 MiB</option>';
	# Lazy...
	for ($i = 1024; $i <= 8192; $i += 256) {
		$out .= '<option value="'.$i.'">'.($i / 1024).' GiB</option>';
	}
	$out .= '<option value="16384">16 GiB</option>';
	$out .= '</select></td></tr>';
	return $out."\n";

}
function create_vm_picker ($input) {
	$name = $input->{'name'};
	$query_string = 'opName=userAPIGetTabularReport&opData='.rawurlencode('{param0:"0",param1:"All Clouds",param2:"VMS-T0"}');
	$response = ucsd_api_call($query_string)->{'serviceResult'};
	$out = '<tr><td><label for="'.$name.'">'.$input->{'label'}.':&nbsp; &nbsp;</label></td>';
	$out .= '<td><select name="'.$name.'" id="'.$name.'">';
	foreach ($response->{'rows'} as $row) {
		$out .= '<option value="'.$row->{'VM_ID'}.'">'.$row->{'VM_Name'}.'</option>';
	}
	$out .= '</select></td></tr>';
	return $out."\n";
}


# Creates a number picker (e.g. how many VMs)
function create_number_picker ($name, $start, $end) {
	$out = '';
	$out .= '<select name="'.$name.'" id="'.$name.'">';
	for ($i = $start; $i <=  $end; $i++) {
		$out .= '<option value="'.$i.'">'.$i.'</option>';
	}
	$out .= '</select>';
	return $out."\n";
}

?>
