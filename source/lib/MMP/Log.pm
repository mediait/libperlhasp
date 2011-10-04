#
# Media Managment Daemon logging tool
# $Id$
# Copyright (C) 2003 MeditProfi
#

package MMP::Log;
use strict;

use Fcntl ':flock';
use VIDI::Flock ':all';

use Encode;

use FindBin;
use lib "$FindBin::Bin/..";
use Filter::MMP;

# log rotate constants #########################################################
use constant MAX_LOG_SIZE => 4000000; 	   # max size for other *.log files
use constant MAX_MMP_LOG_SIZE => 10000000; # max size for mmp.log file
use constant MAX_LOG_FILE => 9; 	   # initial max depth for log-rotate
use constant LOG_LEVEL => 2;  		   # initial LOG_LEVEL. this is used if no other value set

use vars qw($LOG_LEVEL $MAX_LOG_SIZE $MAX_MMP_LOG_SIZE $MAX_LOG_FILE);
$LOG_LEVEL = LOG_LEVEL; # higher values => more details
$MAX_LOG_SIZE = MAX_LOG_SIZE;
$MAX_MMP_LOG_SIZE = MAX_MMP_LOG_SIZE;
$MAX_LOG_FILE = MAX_LOG_FILE;
################################################################################
BEGIN {
	for( 2 .. 7 ) {
		my $level = $_ - 1;
		eval(qq|
sub Msg$_ {
	my \$self = shift;
	if( \$LOG_LEVEL > $level ) {
		\$self->msg(\@_);
	}
}
		|);
	}
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $home = shift || (defined($ENV{MMPHOME}) ? $ENV{MMPHOME} : '');

	my $self = { MMPHOME => $home };
	bless($self, $class);

	$self->{PROFILE} = {};
	
	return $self;
}

sub _rotate_log {
	my $self = shift();
	my $log_file = shift();

	if(-f "$log_file.log") {
		my $max_size = $MAX_LOG_SIZE;
		$max_size = $MAX_MMP_LOG_SIZE if( $log_file eq $self->{MMPHOME}."/var/log/mmp" );
		my $max_log = $MAX_LOG_FILE;
	
		if((stat("$log_file.log"))[7] > $max_size) {
			while($max_log>1) {
				rename "$log_file.".($max_log-1), "$log_file.$max_log";
				$max_log--;
			}
			rename "$log_file.log", "$log_file.1";
		}
	}
}

sub Msg {
	my $self = shift;
	$self->msg(@_);
}

sub msg {
	my $self = shift();
	my $type;
	my $msg;

	# processing parameters
	if(@_ > 1) {
		$type = shift();
		$msg = join(" ", @_);
	} elsif(@_) {
		($type, $msg) = ('MESSAGE_LEVEL', shift());
	} else {
		($type, $msg) = ('MESSAGE_LEVEL', '');
	}
	chomp($msg);

	# format log string
	my @t = localtime();
	my $log_string;



#	$msg = $self->escape($msg);
#	$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s %s# Caller(%s:%d)\n", 
#			$t[3], $t[4] + 1, ($t[5] > 100) ? ($t[5] - 100) : $t[5], 
#			$t[2], $t[1], $t[0], $$, (caller(1))[0], (caller(1))[2], $msg);

	# set log file name
	my $log_file = $self->{MMPHOME} . "/var/log";
	if($type eq 'MESSAGE_LEVEL') {
		$log_file .= "/mmp";
#		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s(%s:%d): %s\n", 
#			$t[3], $t[4] + 1, ($t[5] > 100) ? ($t[5] - 100) : $t[5], 
#			$t[2], $t[1], $t[0], $$, (caller())[0], (caller())[1], (caller())[2], $msg);
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $$, $msg);
#		$msg = $self->escape($msg);
#		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s %s# Caller(%s:%d)\n", 
#			$t[3], $t[4] + 1, ($t[5] > 100) ? ($t[5] - 100) : $t[5], 
#			$t[2], $t[1], $t[0], $$, (caller(1))[0], (caller(1))[2], $msg);
	} elsif($type eq 'HASPD_LEVEL') {
		$log_file .= "/vidihaspd";
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d: %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $msg);
	} elsif($type eq 'UI_LEVEL') {
=ifndef WITH_MOD_MONITORING
		return 0;
=endif
		$log_file .= "/ui";
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $$, $msg);

	} elsif($type eq 'TIVOLI_LEVEL') {
		$log_file .= "/tivoli";
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d: %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $msg);
################################################################################
# PATCH: test loglevel for output special events to separate log-file
#
	} elsif($type eq 'TEST_LEVEL') {
		$log_file .= "/test";
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $$, $msg);
# END PATCH
################################################################################
	} elsif($type eq 'WATCHDOG_LEVEL') {
		$log_file .= "/watchdog";
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $$, $msg);
	} elsif($type eq 'LRVFARM_LEVEL') {
		$log_file .= "/lrvfarmd";
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s:%d: %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $$, (caller(1))[0], (caller(1))[2], $msg);
	} elsif($type eq 'DALETIMPORT_LEVEL') {
		$log_file .= "/daletimport";
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $$, $msg);
	} else {
		$log_file .= "/error";
#		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s(%s:%d): %s\n", 
#			$t[3], $t[4] + 1, ($t[5] > 100) ? ($t[5] - 100) : $t[5], 
#			$t[2], $t[1], $t[0], $$, (caller())[0], (caller())[1], (caller())[2], $msg);
		$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s\n", 
			$t[3], $t[4] + 1, 1900 + $t[5], 
			$t[2], $t[1], $t[0], $$, $msg);
	}

	$self->_write_log($log_file, $log_string);

}

sub _write_log {
	my $self = shift;
	my $log_file = shift;
	my $log_string = shift;

	# write mesage to log
	my $lock = $self->{MMPHOME}. "/var/tmp/.lock.Log";
	if(open(L_LOCK, ">$lock")) {
		vflock(*L_LOCK, LOCK_EX);
		$self->_rotate_log($log_file);
		if(open(LOG, ">>$log_file.log")) {
			if( utf8::is_utf8($log_string) ) {
				$log_string = encode("utf8", $log_string);
			}
			print LOG $log_string;
			close(LOG);
		}
		unlink $lock;
		close L_LOCK;
	}
}

sub escape {
	my $self = shift();
	my $msg = shift();

	$msg =~ s/\r//g;
	$msg =~ s/\n/\\n/g;
	return $msg;
}

sub MsgNew2 {
	my $self = shift;
	if( $LOG_LEVEL > 1 ) {
		$self->msg_new(@_);
	}
}
sub MsgNew {
	my $self = shift;
	$self->msg_new(@_);
}

sub msg_new {
	my $self = shift();
#	my $msg_code = shift();
	my $type = shift();
	if( $type !~ /^(MESSAGE|ERROR|UI|TIVOLI|HASPD|LRVFARM|WATCHDOG)_LEVEL$/ ) {
		unshift @_, $type;
		$type = 'MESSAGE_LEVEL';
	}
	my $msgcode = shift();
	my $msg = join(" ", @_);
	chomp($msg);
	$msg = $self->escape( $msg );

#	my $msg_type = substr($msg_code, length($msg_code)-1);
#	if( $msg_type eq 'I' ) {
#	} elsif( $msg_type eq 'N' ) {
#	} elsif( $msg_type eq 'W' ) {
#	} elsif( $msg_type eq 'E' ) {
#	} elsif( $msg_type eq 'F' ) {
#	}

	# format log string
	my @t = localtime();
	my $log_string;
	$log_string = sprintf("%02d.%02d.%04d %02d:%02d:%02d %d %s %s# Caller(%s:%d)\n", 
		$t[3], $t[4] + 1, 1900 + $t[5], 
		$t[2], $t[1], $t[0], $$, $msgcode, $msg, (caller(1))[0], (caller(1))[2], );

	my $log_file = $self->{MMPHOME} . "/var/log";
	if($type eq 'MESSAGE_LEVEL' || $type eq 'ERROR_LEVEL') {
		$log_file .= "/mmp";
	} elsif($type eq 'UI_LEVEL') {
		$log_file .= "/ui";
	} elsif($type eq 'HASPD_LEVEL') {
		$log_file .= "/vidihaspd";
	} elsif($type eq 'TIVOLI_LEVEL') {
		$log_file .= "/tivoli";
	} elsif($type eq 'WATCHDOG_LEVEL') {
		$log_file .= "/watchdog";
	} elsif($type eq 'LRVFARM_LEVEL') {
		$log_file .= "/lrvfarmd";
	}

	$self->_write_log($log_file, $log_string);

}

sub PROFILE_START {
	my $self = shift;
	my $a = shift || 0;
	my $time = shift || Time::HiRes::time();
	$self->{PROFILE}{$a} = $time;
}

sub PROFILE_TICK {
	my $self = shift;
	my $a = shift || 0;
	my $msg = shift || '';

	$self->Msg(sprintf("%s:%s::PROFILE($a) : %.3f sec passed. $msg", (caller())[0], (caller())[2], (Time::HiRes::time() - $self->{PROFILE}{$a})));
}



1;
