<?php
/*
Copyright Matt Day

Copying and distribution of this file, with or without modification,
are permitted in any medium to Cisco Sytems Employees without royalty
provided the copyright notice and this notice are preserved.  This
file is offered as-is, without any warranty.
*/

include_once "ucsd_api.php";

if ($_POST['Catalog_Name'] == "") {
	header("Location: http://10.52.208.8/ucsd-task/");
	exit;
}

# Loop through POST requests to get Input variables:

# Construct URL:
$query_string = 'formatType=json&opName=userAPISubmitVAppServiceRequest&opData=%7Bparam0:%22'. \
	rawurlencode($_POST['Catalog_Name']).'%22,param1:%7B%22list%22:%5B';
$i = 0;

# Very bad way to do this... :( - but search http POST keys for anything prefixed with input_
foreach (array_keys($_POST) as $req) {
	if (preg_match('/^input_/', $req)) {
		# Gross hack as I need to put a ',' after each item but cannot be on last - as input array size is
		# unknown I'm basically hacking it... :(
		$input_array[$i++] = '%7B%22name%22:%22'.rawurlencode($req).'%22,%22value%22:%22'.rawurlencode($_POST[$req]).'%22%7D';
	}
}
# Due to hack above need to loop back through - probably a more elegant solution using PHP libraries!
for ($i = 0; $i < sizeof($input_array); $i++) {
	$query_string .= $input_array[$i];
	# Append a ',' only if not last item
	if ($i < (sizeof($input_array) - 1)) {
		$query_string .= ',';
	}
}

$query_string .= '%5D%7D,param2:1000%7D';

# Call the API:
$response = ucsd_api_call($query_string);
$sr_no = $response->{'serviceResult'};

# Redirect to status page:
header('Location: http://10.52.208.8/ucsd-task/request_status?id='.$sr_no.'&name='.$_POST['Catalog_Name'].'#current');





?>
