#!/usr/bin/perl -w
use strict;

use FindBin;
use lib "$FindBin::Bin/modules/vididev/source/lib";
use VIDI::Dev::Utils qw(get_host_slesno);

my $SLESNO = get_host_slesno; 
while(my $arg = shift @ARGV){
	if($arg =~ /^--slesno=(\d+)/){
		$SLESNO = $1; 
	}
	else{
		print "USAGE\n";
		print "  $0 [--slesno=9|10|11]\n";
		print "    prints at stdout choosed rpm file path\n";
		print "OPTIONS\n";
		print "  --slesno=<sles maj. version number> default is same as yours ($SLESNO)\n";
		exit 1;
	}
}

if($SLESNO >= 10){
	print "$FindBin::Bin/redist/aksusbd-1.15-1.i386-x86_64.rpm\n";
}
else{
	print "$FindBin::Bin/redist/aksusbd-suse-1.14-3.i386.rpm\n";
}	

