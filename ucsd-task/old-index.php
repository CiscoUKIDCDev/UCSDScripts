<?php
include_once "ucsd_api.php";

# Print the html headers etc:
?>
<!doctype html>
<html><head>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
<title>Request Catalog Item</title>

<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap-theme.min.css">
</head>
<body>
<h1>Select Catalog Item</h1>
<?php

# Get a list of all available catalog items:
$query_string = 'opName=userAPIGetAllCatalogs&opData=%7B%&D';
$catalog_items = ucsd_api_call($query_string);

# Loop through them all
foreach ($catalog_items->{'serviceResult'}->{'rows'} as $row) {
	# For now only pull out advanced catalog items:
	if ($row->{'Catalog_Type'} == "Advanced") {
#		print var_dump($row);
		# Assume this catalog item is both supported and clear the output buffer:
		$out = "";
		$supported = 1;
		$out .= '<div style="border: 1px solid #000080; margin-left: 10%; margin-right: 10%; padding: 1.5em; margin-bottom: 2em;">';
		# Print the icon and name:
		$out .= '<h3><img src="http://10.52.208.38/'.$row->{'Icon'}.'" /> '.$row->{'Catalog_Name'}.'</h3>'."\n";
		$out .= '<p>'.$row->{'Catalog_Description'}.'</p>';
		# HTML Form:
		$out .= '<form action="submit_api_request" method="post">'."\n";
		$out .= '<input type="hidden" name="Catalog_ID" value="'.$row->{'Catalog_ID'}.'" />'."\n";
		$out .= '<input type="hidden" name="Catalog_Name" value="'.$row->{'Catalog_Name'}.'" />'."\n";
		# Format in a table:
		$out .= '<table>';
		# Get catalog item detail:
		$query_string = 'formatType=json&opName=userAPIWorkflowInputDetails&opData=%7Bparam0:%22'. \
			rawurlencode($row->{'Catalog_Name'}).'%22%7D';
		$catalog_item = ucsd_api_call($query_string);
		# Loop through inputs required
		foreach ($catalog_item->{'serviceResult'}->{'details'} as $input) {
			if ($input->{'type'} == "gen_text_input") {
				$out .= '<tr><td>';
				# Print out input form:
				$out .= '<label for="'.$input->{'name'}.'">'.$input->{'label'}.': &nbsp;  </label>'."\n";
				$out .= '</td><td>';
				# Hack for a number picker for certain tasks... Could be done with custom input on UCSD or some other way to match certain inputs
				if ((preg_match('/^Number of /', $input->{'label'})) && ($row->{'Catalog_Name'} == "Create Three Tier Web App")) {
					$out .= create_number_picker($input->{'name'}, 1, 5);
				}
				else {
					$out .= '<input type="text" name="'.$input->{'name'}.'" id="'.$input->{'name'}.'" />'."\n";
				}
				$out .= '</td></tr>'."\n";
			}
			#Broken WiP - need to pass the VM to UCSD and not sure of the format
			else if ($input->{'type'} == "vm") {
				# Needs fixing
				$out .= '<tr><td><label for="'.$input->{'name'}.'">'.$input->{'label'}.': &nbsp;  </label></td><td>'."\n";
				$out .= create_list_of_vms($input->{'name'});
				$out .= '</td></tr>';
			}
			else if ($input->{'type'} == 'vCPUCount') {
				$out .= '<tr><td><label for="'.$input->{'name'}.'">'.$input->{'label'}.': &nbsp;  </label></td><td>'."\n";
				$out .= create_number_picker($input->{'name'}, 1, 8);
				$out .= '</td></tr>';
			}
			else {
				# If the input type isn't supported break out of both loops and move to next item:
				print '<!-- Warning: '.$row->{'Catalog_Name'}." unsupported due to ".$input->{'type'}." input field expected for ".$input->{'name'}." -->\n";
				$supported = 0;
				continue(2);
			}
		}
		print $out;
		print '<tr><td>&nbsp;</td><td><input type="submit" value="Go" />'."\n";
		print '</td></tr></table></form></div>'."\n";
	
	}
}

?>
</body></html>
