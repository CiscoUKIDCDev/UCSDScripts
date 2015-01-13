#!/usr/bin/perl
$content = `http_proxy="" proxy="" curl -s -X "GET" "http://10.52.208.38/app/api/rest?opName=userAPIGetTabularReport&opData=%7Bparam0:%221%22,param1:%22UKIDCV-VC%22,param2:%22VMS-T0%22%7D" -H "x-cloupia-request-key: D47D6DD47B99423D9E499848DDF6D0A9"`;

$content =~ s/\{/\{\n/g;
$content =~ s/\}/\}\n/g;
@lines = split(/\n/, $content);

foreach (@lines) {
	if (/"Guest_OS_Type":"(.*?)"/g) {
		$count{$1} += 1;
	}
}

foreach (sort { $count{$b} <=> $count{$a} } keys(%count)) {
	print $_.' = '.$count{$_}."\n";
}
