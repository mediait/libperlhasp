#
# VIDI MMP
#
# Filter for branch control
#
# $Id$
#
# Copyright (c) 2003-2005, MeditProfi

package Filter::MMP;
use strict;

use Filter::Util::Call;

my %defines =
(
# modules configuration
	'WITH_MOD_ARCHIVE' => 1,	# Archive (TSM)
	'WITH_MOD_EXTENDER' => 1,	# Disk Extender ("Archive2")
	'WITH_MOD_GEOSYNC' => 1,	# Automatic clip replication ("GeoSync") + New manual transmit FolderIndex::DeviceGeoSync
	'WITH_MOD_EXTERNAL_CLIPS' => 1,	# "External" clip type - special type for geo-clips
	'WITH_MOD_ADVANCED_TEXT_SEARCH' => 1,
	'WITH_MOD_LIQUID' => 1,		# DeviceLiquid (Online Network Cutting with Avid Liquid)
	'WITH_MOD_NLEOFF' => 1,    	# DeviceNLEOFF (Any delivery NLE device)
	'WITH_MOD_NLEFCP' => 1,    	# DeviceFinalCutPro
	'WITH_MOD_GENERIC_VS' => 1,	# DeviceVS
#	'WITH_MOD_ECLIPS_VS' => 1,
#	'WITH_MOD_VN_OMNEON' => 1,	# VIDI News Omneon ( for Playout )
	'WITH_MOD_VN_DDR' => 1,		# New multi-VIDI.News support module
#	'WITH_MOD_PLACES' => 1,
#	'WITH_MOD_ITEMS' => 1, 		# Items (готовые сюжеты)
#	'WITH_MOD_SOURCES_DATES' => 1,	# Sources/Dates
#	'WITH_MOD_REPORTERS' => 1,	# Sources/Reporters

#	'WITH_MOD_TRANSMIT' => 1,	# Transmit module folders & logic

	'WITH_MOD_LISTINDEX' => 1, 	# Configurable folder index module

	'WITH_MOD_ARCHIVESROUCES' => 1, # ArchiveSources
#	'WITH_MOD_VNDRAFT' => 1,	# VIDI News Stories
	'WITH_MOD_AUDIODUBBING' => 1,	# Device Fodler for Audio Dubbing
	'WITH_MOD_OMNEON' => 1,		# Device Omneon ( for PlayoutAIR )
	'WITH_MOD_TRAFFICMANAGER' => 1,	# Playout integration with traffic management systems. uses WITH_MOD_OMNEON (must be defined)
	'WITH_MOD_WATHCER_ARCHIVEREQUEST' => 1,
#	'WITH_MOD_NEW' => 1,
#	'WITH_MOD_HIDDEN' => 1, # FolderIndexHidden; implies WITH_HIDDEN
	'WITH_AUTOMERGE' => 1,

	'WITH_SPELLCHECKER' => 1, 	# Spell-cheking through 'aspell'

	'WITH_MORPHGEN' => 1, 		# Use morphem generator for search 
					# terms highlighting

	'WITH_MOD_MONITORING' => 1,	# VMMP.Monitoring

	'WITH_MOD_QUALITY_CONTROL' => 1,	# VMMP.Quality Control integration

# database type
	'WITH_POSTGRESQL' => 1, 	# Use PostgreSQL DB + tsearch2 FTI
# attribute logic
	'WITH_ATTR_DURATION' => 1,	# Autoupdate DURATION attribute from CLIPIN & CLIPOUT
#	'WITH_ATTR_STATUS' => 1,
	'WITH_ATTR_CLIPTYPE' => 1,	# Use sTYPE attribute logic
	'WITH_ATTR_VN_PATH' => 1,
	'WITH_ATTR_SMEDIA_ERROR' => 1,	# Auto-update sMEDIA_ERROR attriubute from sMEDIA_ERROR_* attrs
	'WITH_ATTR_MEDIA_VERSION' => 1,	# Auto-updated sMEDIA_XXX_VERSION counter for every MEDIA layer
# functions
	'WITH_TABLEVIEW' => 1,		# enable SUBTYPE=TABLE for clip views
	'WITH_MANUAL_CLIP_ADDING' => 1,
	'WITH_MANUAL_CLIP_REMOVING' => 1,
	'WITH_CLIPBOARD' => 1,
	'WITH_PRINT' => 1,		# enable printing
	'WITH_HIDDEN' => 1,

#	'WITH_NEW' => 1,
#	'WITH_STATUS' => 1, # implies WITH_MOD_NEW, WITH_MOD_ARCHIVE, WITH_MOD_HIDDEN and WITH_ATTR_STATUS
#	'WITH_ATTR_EXPANDER' => 1,   # hiddable & expandable clip attributes
	'WITH_CLIP_CLONE' => 1,		# enable creating clip copies using hardlinks
# limits
	'LIMIT_INTMEDIA_CLIPS' => 1,
	'LIMIT_DB_SIZE' => 1,
	'LIMIT_EXTMEDIA_CLIPS' => 1,
	'LIMIT_TOTAL_CLIPS' => 1,
	'HASP4TIME' => 1,		# limit usage time with HASP4TIME
# logging and backup
	'SAVE_OLD_META' => 1,
# DEVELOPMENT
#	'DEVEL_HOME' => 1,
#	'WITH_TSM_EMU' => 1,
#	'WITH_ARCHIVE_MANAGE_EMU' => 1,
#	'WITH_ATTR_MEDIATYPE' => 1,
);

my %define_sets = 
(
	'OFF' => [],
	'PRO' => [],
	'CE' => [],
);

my $VER = '';

sub import {
	my $type = @_ ;

	if(ref($define_sets{$VER}) eq 'ARRAY') {
		for(@{$define_sets{$VER}}) {
			$defines{$_} = 1;
		}
	}

	filter_add(bless []) ;
}

sub filter {
	my $self = @_;
	my $status;

	my @stack = ( 1 );
	my $res = "";
	do {
		if($status = filter_read() > 0) {
			if(/^\s*=\s*define\s+([\w\-]+)\s*(.*)$/i) {
				if(defined($2)) {
					$defines{$1} = $2;
				} else {
					$defines{$1} = 1;
				}
				$res .= "## filtered # ".$_;
			} elsif(/^\s*=\s*undef\s+([\w\-]+)/i) {
				delete $defines{$1};
				$res .= "## filtered # ".$_;
			} elsif(/^\s*=\s*ifdef\s+(.+)$/i) {
				my $cond = $1;
				$cond =~ s/([\w\-]+)/(defined($defines{$1}) ? 1 : 0)/ge;
				if($stack[$#stack]) {
					push @stack, ((eval($cond) and !$@) ? 1 : 0);
				} else {
					push @stack, 0;
				}
				$res .= "## filtered # ".$_;
			} elsif(/^\s*=\s*ifndef\s+(.+)$/i) {
				my $cond = $1;
				$cond =~ s/([\w\-]+)/(defined($defines{$1}) ? 1 : 0)/ge;
				if($stack[$#stack]) {
					push @stack, ((eval($cond) and !$@) ? 0 : 1);
				} else {
					push @stack, 0;
				}
				$res .= "## filtered # ".$_;
			} elsif(/^\s*=\s*if\s+(.+)$/i) {
				my $cond = $1;
				for my $def (sort 
					{ length($b) <=> length($a) } 
					keys(%defines))
				{
					$cond =~ s/$def/$defines{$def})/sg;
				}
				if($stack[$#stack]) {
					push @stack, ((eval($cond) and !$@) ? 1 : 0);
				} else {
					push @stack, 0;
				}
				$res .= "## filtered # ".$_;
			} elsif(/^\s*=\s*else(\s+|$)/i) {
				if($#stack < 1 or $stack[$#stack-1] > 0) {
					$stack[$#stack] = $stack[$#stack] ? 0 : 1;
				}
				$res .= "## filtered # ".$_;
			} elsif(/^\s*=\s*endif(\s+|$)/i) {
				pop @stack;
				$res .= "## filtered # ".$_;
			} else {
				if($stack[$#stack] == 1) {
					$res .= $_;
				} else {
					$res .= "## filtered # ".$_;
				}
			}
		}
		$_ = "";
	} while((@stack > 1) and ($status > 0));

	$_ = $res;
	$status;
}

1;
