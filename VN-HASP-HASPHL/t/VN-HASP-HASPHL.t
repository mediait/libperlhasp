# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VN-HASP-HASPHL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('VN::HASP::HASPHL') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok( VN::HASP::HASPHL::Attached() );
ok( VN::HASP::HASPHL::LastError() == 0 );

