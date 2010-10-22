use strict;
use VN::HASP::HASPHL qw ( Attached EncodeData DecodeData LastError GetHaspInfo WriteBlock ReadBlock );

my $id = 723193772; # 0

my $data1 = 'qwertyuiopasdfghjklzxcvbnm';
my $data2 = 'qwerty';
my $buff;

sub main {
	my $res = Attached($id);
	print "Key is " . ($res ? "attached" : "not attached") . "\n";
	return 0 unless $res;

	print qq|Encoding string "$data1"...|;
	$res = EncodeData($data1, $id);
	print ($res ? 'successful' : 'not successful'); print "\n";
	return 0 unless $res;
	print "Length of encoded data is " . length($data1) . "\n";

	$res = DecodeData($data1, $id);
	print 'Decode long data is ' . ($res ? 'successful' : 'not successful') . "\n";
	return 0 unless $res;
	print qq|Decoded string is: "$data1"\n|;

	print qq|Encoding string "$data2"...|;
	$res = EncodeData($data2, $id);
	print ($res ? 'successful' : 'not successful'); print "\n";
	return 0 unless $res;
	print "Length of encoded data is " . length($data2) . "\n";

	$res = DecodeData($data2, $id);
	print 'Decode short data is ' . ($res ? 'successful' : 'not successful') . "\n";
	return 0 unless $res;
	print qq|Decoded string is: "$data2"\n|;

	my $hasp_info;
	print 'Getting HASP info...';
	$res = GetHaspInfo($hasp_info);
	print ($res ? 'successful' : 'not successful'); print "\n";
	return 0 unless $res;
	print "HASP info:\n$hasp_info";

	$res = WriteBlock($data1, 5, $id);
	print 'Write data to HASP at offset 5 is ' . ($res ? 'successful' : 'not successful') . "\n";
	return 0 unless $res;

	$res = ReadBlock($buff, 5, 5, $id);
	print 'Read data from HASP at offset 5, length 5 is ' . ($res ? 'successful' : 'not successful') . "\n";
	return 0 unless $res;
	print "Data read from hasp: $buff\n";

	$res = ReadBlock($buff, 10, 7, $id);
	print 'Read data from HASP at offset 10, length 7 is ' . ($res ? 'successful' : 'not successful') . "\n";
	return 0 unless $res;
	print "Data read from hasp: $buff\n";

	return 1;
}

print main() ? 'OK' : 'NOT OK - last error is ' . LastError();
print "\n";
