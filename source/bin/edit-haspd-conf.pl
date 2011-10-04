#!/usr/bin/perl -w
use strict;
use Tie::File;
use Data::Dumper;

my $HEAD = 	"USAGE: $0 [-h] [-v] [--config=/file] (add <service> <cmd> = <script> | del [<service> [<cmd>])\n";
my $EXAMPLES = 	"  $0 add aksusbd start = /etc/init.d/aksusbd start\n".
		"  $0 add aksusbd stop = 'killall aksusbd >/dev/null 2>&1'\n".
		"  $0 del aksusbd stop\n".
		"  $0 del aksusbd\n";
my $OPTIONS = 	"  -h       - show this\n".
		"  -v       - be verbose\n".
		"  --config - config file to edit, creates it if not exists, default is ~mmp/usr/local/conf/haspd.conf\n";
my $ADD = 	"  add - add records to config file, creates new <service> section if needed\n".
		"        <service>  - service daemon name (or any unique string:)\n".
		"        <cmd>      - (start|stop|restart)\n".
		"        <script>   - bash <service> launcher string, may be quoted if needed\n";
my $DEL = 	"  del - removes records from config file\n".
		"        <service>  - service daemon name (or any unique string:)\n".
		"        <cmd>      - (start|stop|restart)\n".
		"        if only '<service>' is given - removes whole <service> section\n".
		"        if full '<service> <cmd>' is given - remove <cmd> record in <service> section\n";
sub USAGE{
	return 	$HEAD.
		"EXAMPLES:\n$EXAMPLES".
		"OPTIONS:\n$OPTIONS".
		"COMMANDS:\n${ADD}${DEL}".
		"options goes first!".
		"order is important!\n";
}		

my ($CFG_FILE,$VERBOSE,$ARGS);
while(my $arg = shift @ARGV){
	if($arg =~ /^\s*-h\s*$/){
		print USAGE;
		exit;
	}
	elsif($arg =~ /\s*-v\s*$/){
		$VERBOSE = 1;
	}
	elsif($arg =~ /^\s*--config=(\S+)\s*$/){
		$CFG_FILE = $1;
	}
	else{
		$ARGS = join(' ',($arg,@ARGV));
		last;
	}
}

unless($CFG_FILE){
	my $mmphome = $ENV{MMPHOME} ? $ENV{MMPHOME} : glob('~mmp');
	$CFG_FILE = "$mmphome/conf/haspd.conf";
}

eval { 
	my $services = read_config($CFG_FILE);
	edit_config_file($services);
	write_config($CFG_FILE,$services);
};
die "error: $@" if $@;
print "ok\n" if $VERBOSE;

sub edit_config_file{
	my $services = shift;
	if($ARGS =~ /^\s*add\s+(.*)\s*$/){
		my $args = $1;
		unless($args =~ /^(\S+)\s+(start|stop|restart)\s*=\s*(.*?)\s*$/){
			print STDERR "unrecognized 'add' cmd args: '$args'\n\n";
			print STDERR $ADD;
			exit 1;
		}
		my ($service,$action,$script) = ($1,$2,$3);
		$script =~ s/^'(.*?)'$//;
		$script =~ s/^"(.*?)"$//;
		print "set $service $action = '$script'... " if $VERBOSE;
		$services->{$service}->{$action} = $script;
	}
	elsif($ARGS =~ /^\s*del\s+(.*)\s*$/){
		my $args = $1;
		unless($args =~ /^(\S+)(?:\s+(start|stop|restart))?\s*?$/){
			print STDERR "unrecognized 'del' cmd args: '$args'\n\n";
			print STDERR $DEL;
			exit 1;
		}
		my $service = $1;
		my $action = $2;
		unless($action){
			print "remove $service... " if $VERBOSE;
			delete $services->{$service};
		}
		else{
			print "remove $service $action... " if $VERBOSE;
			delete $services->{$service}->{$action};
		}
	}
	else{
		print STDERR "unrecognized cmd line format\n\n";
		print STDERR USAGE;
		exit 1;
	}
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

sub write_config{
	my $cfg_file = shift;
	my $services = shift;
	open CFG_FILE, ">$cfg_file" || die "failed write $cfg_file: $!";
	print CFG_FILE Data::Dumper->Dump([$services],[qw($services)]);
	close CFG_FILE;
}
