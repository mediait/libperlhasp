#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd;

use FindBin;
use lib "$FindBin::Bin/source/lib";
use lib "$FindBin::Bin/modules/gnfdev/source/lib";

use GNF::Dev::libperlhasp;
use GNF::Dev::Utils qw(get_host_arch get_host_slesno);

# 
# prepare next dir structure 4 u 2 use as u wish
#

sub usage{
	print 	"USAGE\n".
		"  $0 [OPTIONS]\n".
		"OPTIONS\n".
		"  --help    - shows this\n";	
}

my %OPTS = (
	arch => get_host_arch,
	slesno => get_host_slesno,
	fid => 1,
	dest_dir => cwd
);
{
	my $warn;
	local $SIG{__WARN__} = sub {$warn = join " ", @_};
	unless(GetOptions( \%OPTS,
			"haspid=s",
			"hasp=s",
			"pid=i",
			"arch=s",
			"slesno=i",
			"dest_dir=s",
			"verbose",
			"help"
		)){
		usage;
		exit 1;
	}
}
usage, exit if $OPTS{help};

foreach('haspid', 'pid'){
	unless(defined $OPTS{$_}){
		die "option '--$_' must be";
	}
}

main();

sub main{
	my $home_dir = $FindBin::Bin;
	my $tmp_dir = "$home_dir/tmp";
	my $dest_dir = $OPTS{dest_dir};
	
	print "Prepare aksusbd...\n";
	my $libperlhasp = GNF::Dev::libperlhasp->at($home_dir);
	$libperlhasp
		->choose_aksusbd(\%OPTS) 
		->cp($dest_dir);
	
	print "Prepare hasp...\n";
	$libperlhasp
		->choose_hasp( \%OPTS )
		->cp($tmp_dir)
		->fry( \%OPTS )		
		->cp($dest_dir);
	
	print "Compile haspd...\n";
	$libperlhasp->files('haspd.pl')->as("GNF::Dev::Pprogs")->compile("--lib $dest_dir --lib $home_dir/source/lib --force")->cp($dest_dir);
	
	print "Copy other files...\n";
	$libperlhasp->dir("source")->files(
		'haspd.conf',
		'hasp',
		'edit-haspd-conf.pl')->cp($dest_dir);

	system "rm -fr $tmp_dir";
}
