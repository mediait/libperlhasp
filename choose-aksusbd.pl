#!/usr/bin/perl -w
use strict;
use FindBin;

my $SLESNO = get_host_slesno(); 
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
	print "$FindBin::Bin/libhasp/aksusbd-1.15-1.i386-x86_64.rpm\n";
}
else{
	print "$FindBin::Bin/libhasp/aksusbd-suse-1.14-3.i386.rpm\n";
}	

sub get_host_slesno{
	die 'file /etc/SuSE-release not exists' unless -e '/etc/SuSE-release';
	my $res = `cat /etc/SuSE-release | grep VERSION`;
	chomp $res;
	if($res =~ /^\s*VERSION\s*=\s*(\d+(\.\d+)?)\s*$/){
		return $1;
	}
	die "unsupported /etc/SuSE-release line format: '$res'";
}
