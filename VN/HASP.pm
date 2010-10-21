package VN::HASP;

use 5.008006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	Attached EncodeData DecodeData Id WriteBlock ReadBlock SetDateTime GetDateTime CompareTimeWithCurrent
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '2.00';

require VN::HASP::HASP4;
require VN::HASP::HASPHL;

my $used_module;

my $HID = 0;
my $FID = 0;
my $PID = 0;

sub Detect {
	my $tmp;
	my $res = VN::HASP::HASP4::Id($tmp);
	if($res == 0) {
		$used_module = "HASP4";
		return $used_module;
	}
	VN::HASP::HASPHL::SetHID($HID) if $HID;
	VN::HASP::HASPHL::SetPID($PID) if $PID;
	$res = VN::HASP::HASPHL::GetHaspInfo($tmp);
	if($res == 1) {
		$used_module = "HASPHL";
		$tmp =~ /^.+<hasp id="(\d+)" type="HASP-HL">.+?<feature id="$FID"/s;
		VN::HASP::HASPHL::SetFID($FID) if($FID != 0);
		return $used_module;
	}
	return 0;
}

sub Attached {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::Attached(@_)
	} else { # $used_module eq 'HASPHL'
		my @args = @_;
		VN::HASP::HASPHL::Attached(@args);
		return VN::HASP::HASPHL::LastError();
	}
}

sub EncodeData {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::EncodeData(@_)
	} else { # $used_module eq 'HASPHL'
		VN::HASP::HASPHL::EncodeData(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub DecodeData {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::DecodeData(@_)
	} else { # $used_module eq 'HASPHL'
		VN::HASP::HASPHL::DecodeData(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub WriteBlock {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::WriteBlock(@_)
	} else { # $used_module eq 'HASPHL'
		VN::HASP::HASPHL::WriteBlock(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub ReadBlock {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::ReadBlock(@_)
	} else { # $used_module eq 'HASPHL'
		VN::HASP::HASPHL::ReadBlock(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub SetDateTime {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::SetDateTime(@_)
	} else { # $used_module eq 'HASPHL'
		return 0; 
	}
}

sub GetDateTime {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::GetDateTime(@_)
	} else { # $used_module eq 'HASPHL'
		VN::HASP::HASPHL::GetDateTime(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub Id {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::Id($_[0]);
	} else { # $used_module eq 'HASPHL'
		my $tmp;
		if(VN::HASP::HASPHL::GetHaspInfo($tmp)) {
			$tmp =~ /^.+<hasp id="(\d+)" type="HASP-HL">.+?<feature id="$FID"/s;
			$_[0] = $1 || 0;

		}
		return VN::HASP::HASPHL::LastError();
	}
}

sub CompareTimeWithCurrent {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::CompareTimeWithCurrent(@_)
	} else { # $used_module eq 'HASPHL'
		my @args = @_;
		VN::HASP::HASPHL::CompareTimeWithCurrent(@args);
		return VN::HASP::HASPHL::LastError();
	}
}

1;
