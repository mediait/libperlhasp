#!/usr/bin/perl -w
use strict;
# config files is perl code (dumped with Data::Dumper)

use FindBin;
use lib "$FindBin::Bin/../../VN-HASP/lib";
use lib "$FindBin::Bin/../lib";
require VN::HASP; 
use MMP::Log;

$| = 1;

my $USAGE = "USAGE: $0 [--mmphome=~mmp] [--config=~mmp/conf/haspd.conf] [-v] [-h]";

my ($MMPHOME, $CFG_FILE, $VERBOSE);
while(my $arg = shift @ARGV){
	if($arg =~ /^\s*--mmphome=(\S+)\s*$/){
		$MMPHOME = $1;
	}
	elsif($arg =~ /^\s*--config=(\S+)\s*/){
		$CFG_FILE = $1;
	}
	elsif($arg =~ /^\s*-v\s*/){
		$VERBOSE = 1;
	}
	elsif($arg =~ /^\s*-h\s*/){
		print $USAGE."\n";
		exit;
	}
	else{
		print STDERR "unknown arg: '$arg'\n";
		print STDERR $USAGE."\n";
		exit 1;
	}
}
unless ($MMPHOME){
	$MMPHOME = $ENV{MMPHOME} ? $ENV{MMPHOME} : glob('~mmp');
}
$CFG_FILE = "$MMPHOME/conf/haspd.conf" unless $CFG_FILE;
die "MMP home dir $MMPHOME not exists" unless -e $MMPHOME;
print "reading config at $CFG_FILE... " if $VERBOSE;
my %SERVICES = %{fix_config(read_config($CFG_FILE))};

print "ok\n" if $VERBOSE;

my $AKSUSBD = {
	name => "aksusbd",
	start => "/etc/init.d/aksusbd start",
	stop => "/etc/init.d/aksusbd stop",
	restart => "/etc/init.d/aksusbd restart",
};

if($VERBOSE){
	print "MMPHOME  = $MMPHOME\n";
	print "CFG_FILE = $CFG_FILE\n";
	foreach my $service ($AKSUSBD, sort services_by_name values %SERVICES){
		print "$service->{name}\n";
		foreach(sort keys %$service){
			print "\t$_ => $service->{$_}\n";
		}
	}
}

$VIDI::Log::LOG_LEVEL = 1;
my $LOG = new VIDI::Log($MMPHOME);

my $CONTINUE = 1;

$SIG{INT} = $SIG{TERM} = $SIG{HUP} = \&signal_handler;
$SIG{PIPE} = 'IGNORE';

eval { restart_service($AKSUSBD); };
if($@){
	$LOG->Msg('HASPD_LEVEL', "Failed to restart service aksusbd: $@");
}
sleep 2;
foreach my $service (sort services_by_name values %SERVICES){
	eval { restart_service($service); };
	if($@){
		$LOG->Msg('HASPD_LEVEL', "Failed to restart service $service->{name}: $@");
	}
}

while($CONTINUE) {
	my $hasp_error_33_counter = 0;
	$LOG->Msg3('HASPD_LEVEL', "MLP0630I Checking HASP");
	my $att = VN::HASP::Attached();
	if($att) {
		do {
			if( $att == 33 ) {
				$hasp_error_33_counter += 1;
				$LOG->Msg('HASPD_LEVEL', "HASP error 33 encountered! Total: $hasp_error_33_counter");
			}
			if( $att != 33 || $hasp_error_33_counter > 5 ) {
				$LOG->Msg('HASPD_LEVEL', "MLP0330N No HASP found: $att");
				eval { restart_service($AKSUSBD); };
				if($@){
					$LOG->Msg('HASPD_LEVEL', "Failed to restart service $_: $@");
				}
				$hasp_error_33_counter = 0;
			}
			foreach (1 .. 5){
				sleep 2;
				last unless $CONTINUE;
			}
			last unless $CONTINUE;
			$att = VN::HASP::Attached();
		} while( $att );
		last unless $CONTINUE;
		foreach my $service (sort services_by_name values %SERVICES){
			eval { stop_start_service($service, 2); };
			if($@){
				$LOG->Msg('HASPD_LEVEL', "Failed to stop-start service $service->{name}: $@");
			}
		}
	}
	$LOG->Msg3('HASPD_LEVEL', "MLP0635I Checking HASP: OK");
	sleep(5);
}

foreach my $service (sort services_by_name values %SERVICES){
	eval { stop_service($service); };
	if($@){
		$LOG->Msg('HASPD_LEVEL', "Failed to stop service $service->{name}: $@");
	}
}

$LOG->Msg('HASPD_LEVEL', "Exiting...");
exit 0;

sub restart_service{
	my $service = shift;
	if($service->{restart}){
		$LOG->Msg('HASPD_LEVEL', "MLP0550I Restarting $service->{name} ...");
		cmd("$service->{restart} >/dev/null 2>&1");
	}
	else{
		stop_start_service($service, 2);
	}
}

sub stop_start_service{
	my $service = shift;
	my $gap = shift || undef;
	stop_service($service);
	sleep $gap if $gap;
	start_service($service);
}

sub stop_service{
	my $service = shift;
	die "there isn't stop cmd 4 service $service->{name}, fix $CFG_FILE" unless $service->{stop};
	$LOG->Msg('HASPD_LEVEL', "MLP0560I Stopping $service->{name} ...");
	cmd("$service->{stop} >/dev/null 2>&1");
}

sub start_service{
	my $service = shift;
	die "there isn't start cmd 4 service $service->{name}, fix $CFG_FILE" unless $service->{start};
	$LOG->Msg('HASPD_LEVEL', "MLP0565I Starting $service->{name} ...");
	cmd("$service->{start} >/dev/null 2>&1");
}

sub cmd{
#	print join(" ",@_)."\n" if $VERBOSE;
	system @_;
	if(my $err = ($? >> 8)){
		die sprintf("failed($err) to do cmd '%s'",join(" ",@_));
	}
}

sub services_by_name{
	$a->{name} cmp $b->{name};
}

sub timestamp {
	my @t = localtime(time());
	return sprintf("%02d:%02d:%02d %02d:%02d:%04d", $t[2], $t[1], $t[0], $t[3], $t[4]+1, $t[5]+1900); 
}

sub signal_handler {
	$CONTINUE = 0;
}

sub read_config{
	my $cfg_file = shift;
	if(-e $cfg_file){
		no strict 'vars';
		open CFG_FILE, "<$cfg_file" || die "failed read $cfg_file: $!";
		my $services = eval join('',<CFG_FILE>);
		if($@){
			die "failed parse $cfg_file: $@";
		}
		close CFG_FILE;
		return $services if ref($services) eq 'HASH';
	}
	return {};
}

# TODO: i'm stupid bastard
sub fix_config{
	my $services = shift;
	$services->{$_}->{name} = $_ foreach keys %$services;
	return $services;
}

