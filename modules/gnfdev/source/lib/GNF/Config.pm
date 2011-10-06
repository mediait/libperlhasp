#!/usr/bin/perl -w
#
# $Id$
#
# GNF MMP Configuration parser library
# Copyright (C) 2004 MeditProfi
#
# Configuration file format
# -------------------------
#
# configuration file := [OPERATOR OPERATOR ... OPERATOR] PAIR PAIR ... PAIR
# PAIR		:= KEYWORD = VALUE
# VALUE		:= SCALAR | ARRAY | HASH
# HASH		:= { PAIR PAIR ... PAIR }
# ARRAY		:= [ VALUE VALUE ... VALUE ]
# SCALAR	:= identifier | "string with spaces"
# KEYWORD	:= identifier
# OPERATOR 	:= %%include "conf_file_name"
#
# Configuration example
# ---------------------
#
# ATTRIBUTES = [
#   { NAME=Название	TYPE=STRING	SYSTEM=0 VALUES=[] }
#   { NAME=Комментарий	TYPE=TEXT	SYSTEM=0 VALUES=[] }
#   { NAME=Тип		TYPE=LIST	SYSTEM=0 VALUES=[Draft Сюжет Реклама] }
# ]
#
# Usage
# -----
# 
# use MMP::Config;
#
# # load configuration file
# my $cfg->new MMP::Config($filename, $log);
#
# # dump configuration
# $cfg->Dump();
#
# # print all attributes names
# if(exists $cfg->{ATTRIBUTES} && ref($cfg->{ATTRIBUTES}) eq 'ARRAY') {
#	for my $attr (@{$cfg->{ATTRIBUTES}}) {
#		if(ref($attr) eq 'HASH' && exists $attr->{NAME}) {
#			print $attr->{NAME}, "\n";
#		}
#	}
# }
#

package GNF::Config;

use strict;
#use Carp qw ( shortmess );
use Carp qw ( shortmess longmess );
use Fcntl ':flock';
use GNF::Flock ':all';
use Encode;

sub new {
	my $proto = shift;
	my $filename = shift;
	my $log = shift;
        my $fh = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		'__CONFIG_PATH'		=> "", # be cosmopolite
		'__HFILE'		=> $fh,
		'__FILENAME'		=> $filename,
		'__LINE_NUMBER'		=> 0,
		'__LINE_POS'		=> 0,
		'__LINE'		=> '',
		'__LAST_TOKEN_POS'	=> -1,
		'__LINES'		=> [],
		'__LOG'			=> $log,
	};
	bless($self, $class);
        if(defined($fh))
         {
           $self->_parse_hash($self);
         }
        else
         {
	   $self->_parse_file() if($filename);
         }
	return $self;
}

sub _parse_error {
	my($self,$msg) = @_;
	my $txt = shortmess(
			"$msg".
			" at line ".$self->{__LINE_NUMBER}.
			" col ".($self->{__LINE_POS}+1).
			($self->{__FILENAME} ? 
					" file ".$self->{__FILENAME} :
				" string: \n".$self->{__STRING}
			)
		);
	if( defined($self->{'__LOG'}) ) {
		$self->{'__LOG'}->Msg('ERROR_LEVEL', "MLP0010W $txt");
	} else {
		print STDERR $txt, "\n";
	}
}

sub _parse_get_next_line {
	my $self = shift;
	$self->{__LINE_NUMBER}++;
	$self->{__LINE_POS} = 0;
	$self->{__LAST_TOKEN_POS} = -1;
	if( $self->{__HFILE} ) {
		$self->{__LINE} = readline($self->{__HFILE});
	} else {
		$self->{__LINE} = shift @{$self->{__LINES}};
	}
	return unless(defined($self->{__LINE}));
	chomp($self->{__LINE});

	$self->{__LINE} = decode("utf8", $self->{__LINE});
}

sub _parse_get_next_token {
	my $self = shift;
	while(1) {
		return undef unless(defined($self->{__LINE}));
		for(;$self->{__LINE_POS} < length($self->{__LINE}) && substr($self->{__LINE}, $self->{__LINE_POS}, 1) =~ /\s/; $self->{__LINE_POS}++) {}
		if($self->{__LINE_POS} >= length($self->{__LINE})) {
			$self->_parse_get_next_line();
			next;
		}
        	my $ch = substr($self->{__LINE}, $self->{__LINE_POS}, 1);
	        if($ch eq '#') {
			$self->_parse_get_next_line();
			next;
	        }
        	if($ch =~ /[\{\}\[\]\=]{1}/) {
	        	$self->{__LAST_TOKEN_POS} = $self->{__LINE_POS}++;
        		return $ch;
	        }
        	if($ch =~ /\"/) {
        		$self->{__LINE_POS}++;
			my $pos = $self->{__LINE_POS};
			while(1) {
				for(;$self->{__LINE_POS} < length($self->{__LINE}) && substr($self->{__LINE}, $self->{__LINE_POS}, 1) ne '"'; $self->{__LINE_POS}++) {}
				if($self->{__LINE_POS} >= length($self->{__LINE})) {
	        		    	$self->_parse_error('Quote expected at the end of line');
        	    			return undef;
	        	    	}
				my $test = $self->{__LINE_POS} + 1;
				if($test < length($self->{__LINE}) && substr($self->{__LINE}, $test, 1) eq '"') {
					$self->{__LINE_POS} = $test + 1;
					next;
				}
				last;
			}
			my $res = substr($self->{__LINE}, $pos, $self->{__LINE_POS}-$pos);
			$res =~ s/\"\"/\"/g;
			$self->{__LAST_TOKEN_POS} = $pos-1;
			$self->{__LINE_POS}++;
			return $res;
		}
		my $pos = $self->{__LINE_POS};
		for(;$self->{__LINE_POS} < length($self->{__LINE}) && substr($self->{__LINE}, $self->{__LINE_POS}, 1) !~ /[\s\"\#\{\}\[\]\=]/; $self->{__LINE_POS}++) {}
		$self->{__LAST_TOKEN_POS} = $pos;
		return substr($self->{__LINE}, $pos, $self->{__LINE_POS}-$pos);
	}
}

sub _parse_return_last_token {
	my $self = shift;
	return if($self->{__LAST_TOKEN_POS} == -1);
	$self->{__LINE_POS} = $self->{__LAST_TOKEN_POS};
	$self->{__LAST_TOKEN_POS} = -1;
}

sub _parse_array {
	my ($self, $res) = @_;
	my $value;
	while(defined($value = $self->_parse_value())) {
		push @$res, $value;
	}
	return 1;
}

sub _parse_value {
	my $self = shift;
	my $token = $self->_parse_get_next_token();
	return undef unless(defined($token));

	if($token eq '[') {
		my $res = [];
		$self->_parse_array($res);
		$token = $self->_parse_get_next_token();
		if((!defined($token)) || $token ne ']') {
			$self->_parse_return_last_token();
			$self->_parse_error('] expected');
			return undef;
		}
		return $res;
	} elsif($token eq '{') {
		my $res = {};
		$self->_parse_hash($res);
		$token = $self->_parse_get_next_token();
		if((!defined($token)) || $token ne '}') {
			$self->_parse_return_last_token();
			$self->_parse_error('} expected');
			return undef;
		}
		return $res;
	} elsif($token =~ /^[\[\]\{\}\=]{1}$/) {
		$self->_parse_return_last_token();
		return undef;
	} else {
		return $token;
	}
}

sub _parse_pair {
	my ($self, $res) = @_;
	my $key = $self->_parse_get_next_token();
	return 0 unless(defined($key));
	if($key =~ /^[\[\]\{\}\=]{1}$/) {
		$self->_parse_return_last_token();
		return 0;
	}
	if(exists $res->{$key}) {
		$self->_parse_return_last_token();
		$self->_parse_error('Duplicate key found');
		return 0;
	}

	my $op = $self->_parse_get_next_token();
	return 0 unless(defined($op));
	if($op ne '=') {
		$self->_parse_return_last_token();
		$self->_parse_error('= expected');
		return 0;
	}

	my $value = $self->_parse_value();
	unless(defined($value)) {
		$self->_parse_error('Value expected');
		return 0;
	}

	$res->{$key} = $value;
	return 1;
}

sub _parse_hash {
	my ($self, $res) = @_;
	while($self->_parse_pair($res)) {}
	return 1;
}

sub _parse_file {
	my $self = shift;
	my $filename = '';
	if($self->{__FILENAME} =~ /[\\\/]+/) {
		$filename = $self->{__FILENAME};
		unless( -f $filename ) {
			my $txt = longmess("Invalid configuration file name: ".$self->{__FILENAME});
			if( defined($self->{'__LOG'}) ) {
				$self->{'__LOG'}->Msg('MMP::Log::ERROR_LEVEL', 
#					shortmess("Invalid configuration file name: ".$self->{__FILENAME}))
					"MLP0020W $txt");
			} else {
				print STDERR $txt, "\n";
			}
			return undef;
		}
	} else {
		if(my $cfg_path = $self->{__CONFIG_PATH}){
			$filename = "$cfg_path/$self->{__FILENAME}";
		}
		else{
			$filename = $self->{__FILENAME};
		}
	}

	unless(open($self->{__HFILE},$filename)) {
		my $txt = shortmess("Can't open configuration file ".$filename.": $!");
		if( defined($self->{'__LOG'}) ) {
			$self->{'__LOG'}->Msg('MMP::Log::ERROR_LEVEL', "MLP0030W $txt");
		} else {
			print STDERR $txt, "\n";
		}
		return undef;
	}
	vflock($self->{__HFILE}, LOCK_EX);
	$self->_parse_hash($self);
	vflock($self->{__HFILE}, LOCK_UN);

	close($self->{__HFILE});
	undef $self->{__HFILE};
}


sub _dump_array {
	my($self, $array, $level) = @_;

	return 'undef' unless(defined($array));

	my $res = '';	
	for my $val (@$array) {
		$res .= "  "x$level;
		$res .= $self->_dump_value($val, $level+1);
		$res .= "\n";
	}
	return $res;
}


sub _dump_value {
	my($self, $value, $level) = @_;

	my $res = '';
	unless(ref($value)) {
		if(defined($value)) {
			$res .= "\"$value\"";
		} else {
			$res .= 'undef';
		}
		return $res;
	}
	if(ref($value) eq 'HASH') {
		$res .= "{\n";
		$res .= $self->_dump_hash($value, $level+1);
		$res .= '  'x$level . "}";
	}
	elsif(ref($value) eq 'ARRAY') {
		$res .= "[\n";
		$res .= $self->_dump_array($value, $level+1);
		$res .= '  'x$level . "]";
	}
	return $res;
}

sub _dump_hash {
	my($self, $hash, $level) = @_;


	return 'undef' unless(defined($hash));

	my $res = '';
	for my $key (sort keys %$hash) {
		next if($key =~ /^__/);
		$res .= "  "x$level . ($key ? $key : "\"\"") . '=';
		$res .= $self->_dump_value($hash->{$key}, $level+1);
		$res .= "\n";
	}
	return $res;
}

sub Dump {
	my $self = shift;
	return $self->_dump_hash($self, 0);
}

sub _parse_path {
	my $self = shift();
	my $path = shift();
	my $res = $self;

	for my $ref (split(/\./, $path)) {
		return undef unless ref($res);
		my $idx = undef;
		$idx = $1 if($ref =~ s/\[(\d+)\]$//);
		$res = $res->{$ref};
		$res = $res->[$idx] if defined($idx);
	}

	return $res;
}

sub _copy_object {
	my $self = shift();
	my $obj = shift();
	my $res = '';

	if(ref($obj) eq 'ARRAY') {
		$res = [];
		push @$res, $self->_copy_object($_) for(@$obj);
	} elsif(ref($obj) eq 'HASH') {
		$res = {};
		$res->{$_} = $self->_copy_object($obj->{$_}) for(keys %$obj);
	} else {
		$res = $obj;
	}

	return $res;
}

sub NodeExist {
	my $self = shift();
	my $path = shift();

	my $obj = $self->_parse_path($path);
	return defined($obj);
}

sub GetNodeSize {
	my $self = shift();
	my $path = shift();

	my $obj = $self->_parse_path($path);
	return 0 unless defined($obj);
}

sub GetNodeValue {
	my $self = shift();
	my $path = shift();
	my $default = shift() || '';

	my $obj = $self->_parse_path($path);
	return $default unless defined($obj);

	return $self->_copy_object($obj);
}

sub ParseString {
	my $self = shift();
	@{$self->{__LINES}} = split(/\n/, join(' ', @_));
	$self->{__STRING} = join("\n", @{$self->{__LINES}});
	return $self->_parse_hash($self);
}

sub WriteConfig
{
        my $self = shift;
        my $newconfig = $self->Dump();
#	$self->{'__LOG'}->Msg('LRVFARM_LEVEL', "Dumping config: $newconfig");
#	$self->{'__LOG'}->Msg('LRVFARM_LEVEL', "Dumping config. __HFILE = $self->{__HFILE}");
#	$self->{'__LOG'}->Msg('LRVFARM_LEVEL', "Dumping config. __FILENAME = $self->{__FILENAME}");
	if( $self->{__HFILE} ) {

	        my $fh = $self->{__HFILE};
	        seek $fh,0,0;
	        truncate $fh, 0;
        	print $fh $newconfig;

	} elsif( $self->{__FILENAME} ) {
		if( open FH, ">$self->{__FILENAME}" ) {
			print FH $newconfig;
			close FH;
		} else {
			my $txt = "Cannot open output file $self->{__FILENAME}";
			if( defined($self->{'__LOG'}) ) {
				$self->{'__LOG'}->Msg('ERROR_LEVEL', "MLP0040W $txt");
			} else {
				print STDERR $txt, "\n";
			}
		}
	}
}

1;
