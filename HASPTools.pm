package HASPTools;

use 5.008006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	Attached EncodeData DecodeData Id WriteBlock ReadBlock SetDateTime GetDateTime Init
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '2.00';

require VN::HASP::HASP4;
require VN::HASP::HASPHL;

my $used_module;
my $ID;

sub Detect {
	my $tmp;
	my $res = VN::HASP::HASP4::Id($tmp);
	if($res == 0) {
		$used_module = "HASP4";
		return $used_module;
	}
	$res = VN::HASP::HASPHL::GetHaspInfo($tmp);
	if($res == 1) {
		$used_module = "HASPHL";
		$tmp =~ /^.+<hasp id="(\d+)" type="HASP-HL" \/>.+$/s;
		$ID = $1;
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
		VN::HASP::HASPHL::Attached(@args ? @args : $ID);
		return VN::HASP::HASPHL::LastError();
	}
}

sub EncodeData {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::EncodeData(@_)
	} else { # $used_module eq 'HASPHL'
		push @_, $ID if @_ < 2;
		VN::HASP::HASPHL::EncodeData(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub DecodeData {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::DecodeData(@_)
	} else { # $used_module eq 'HASPHL'
		push @_, $ID if @_ < 2;
		VN::HASP::HASPHL::DecodeData(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub WriteBlock {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::WriteBlock(@_)
	} else { # $used_module eq 'HASPHL'
		my @args = @_;
		push @args, $ID if @args < 3;
		VN::HASP::HASPHL::WriteBlock(@args);
		return VN::HASP::HASPHL::LastError();
	}
}

sub ReadBlock {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::ReadBlock(@_)
	} else { # $used_module eq 'HASPHL'
		push @_, $ID if @_ < 4;
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
		push @_, $ID if @_ < 7;
		VN::HASP::HASPHL::GetDateTime(@_);
		return VN::HASP::HASPHL::LastError();
	}
}

sub Id {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		return VN::HASP::HASP4::Id($_[0]);
	} else { # $used_module eq 'HASPHL'
		push @_, $ID if @_ < 2;
		if(VN::HASP::HASPHL::GetHaspInfo(@_)) {
			$_[0] =~ s/^.+<hasp id="(\d+)" type="HASP-HL" \/>.+$/$1/s;
		}
		return VN::HASP::HASPHL::LastError();
	}
}

sub Init {
	Detect unless($used_module);

	if(!$used_module or $used_module eq 'HASP4') {
		VN::HASP::HASP4::Init(@_);
	} else { # $used_module eq 'HASPHL'
		VN::HASP::HASPHL::Init(@_);
	}
}

1;
