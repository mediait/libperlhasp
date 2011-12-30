# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };
use VN::HASP;
my $rc = VN::HASP::Attached();
if ($rc != 0) {
	print "not ok 1 (rc = $rc)\n";
} else {
	ok(1);
}
my $data = "AttackOfTheClones";
$rc = VN::HASP::EncodeData($data);
if ($rc != 0) {
	print "not ok 2 (rc = $rc)\n";
} else {
	print "Encoded data: $data; ";
	ok(2);
}
$rc = VN::HASP::DecodeData($data);
if ($rc != 0) {
	print "not ok 3 (rc = $rc)\n";
} else {
	print "Decoded data: $data; ";
	ok(3);
}
my $id = 0;
$rc = VN::HASP::Id($id);
if ($rc != 0) {
	print "not ok 4 (rc = $rc)\n";
} else {
	print "HASP id: $id; ";
	ok(4);
}
$rc = VN::HASP::WriteBlock($data, 0);
if ($rc != 0) {
	print "not ok 5 (rc = $rc)\n";
} else {
	ok(5);
}
$rc = VN::HASP::WriteBlock("CloneAttack", 20);
if ($rc != 0) {
	print "not ok 6 (rc = $rc)\n";
} else {
	ok(6);
}
$data = '';
$rc = VN::HASP::ReadBlock($data, 20, 20);
if ($rc != 0) {
	print "not ok 7 (rc = $rc)\n";
} else {
	print "Read from address 20: $data; ";
	ok(7);
}
$rc = VN::HASP::ReadBlock($data, 20, 0);
if ($rc != 0) {
	print "not ok 8 (rc = $rc)\n";
} else {
	print "Read from address 0: $data; ";
	ok(8);
}

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

