#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd;
use File::Spec;

use FindBin;
use lib "$FindBin::Bin/source/lib";

sub usage{
	print 	"USAGE\n".
		"  $0 ( --haspid=NOHASP | (--hasp=HASPHL | (--hasp=HASP4 --haspid=[0-9A-Za-z]+) --pid=\\d+) ) (other options)\n".
		"OPTIONS\n".
		"  --haspid=(NOHASP|[0-9A-Za-z]+) 	- HASP ID or 'NOHASP' to use HASPemu, default is 'NOHASP'\n".
		"  --hasp=(HASP4|HASPHL) 		- what kinf of HASP to use, default is HASPHL\n".
		"  --pid=\\d+ 				- HASP Program ID, mandatory if --haspid != NOHASP\n".
		"  --fid=\\d+ 				- HASP Function ID, default is 1\n".
		"  --prj-dir=/some/path 		- libperlhasp project  home dir, default is \$FindBin::Bin\n".
		"  --tmp-dir=/some/path 		- tmp dir - where to do all dirty things, default is `cwd`/tmp\n".
		"  --dest-dir=/some/path 		- destination dir - where to put result, default is --tmp-dir/redist\n".
		"  --help 				- shows this\n".
		"DESCRIPTION\n".
		"  puts redist/aksusbd-*.rpm in --dest-dir/redist if --haspid ne NOHASP\n".
		"  puts redist/VN-HASP/.../libhasp_linux_*108230.so in --dest-dir/usr/local/lib(64)? if --haspid ne NOHASP\n".
		"  puts VN-HASP or HASPemu in --tmp-dir/(VN-HASP|HASPemu)\n".
		"  configure and build it there and install libs in --tmp-dir/lib\n".
		"  puts source/bin/ source/etc in --dest-dir/\n".
		"  puts source/sbin/haspd.pl in --tmp-dir/usr/local/sbin, builds it there\n".
		"  and puts binary to --dest-dir/usr/local/sbin\n".
		"  create any needed dirs\n";
}

my %OPTS;
$OPTS{arch} = get_host_arch();
$OPTS{slesno} = get_host_slesno();
$OPTS{fid} = 1;
$OPTS{"prj-dir"} = $FindBin::Bin;
$OPTS{"tmp-dir"} = cwd."/tmp";
$OPTS{"dest-dir"} = $OPTS{"tmp-dir"}."/redist";
{
	my $warn;
	local $SIG{__WARN__} = sub {$warn = join " ", @_};
	unless(GetOptions( \%OPTS,
			"haspid=s",
			"hasp=s",
			"pid=i",
			"prj-dir=s",
			"dest-dir=s",
			"tmp-dir=s",
			"help"
		)){
		usage;
		exit 1;
	}
}
usage, exit if $OPTS{help};

if(not defined $OPTS{haspid}){
	die "please give me '--haspid=[0-9a-zA-Z]' options" if defined $OPTS{hasp} and $OPTS{hasp} eq "HASP4";
	$OPTS{haspid} = "NOHASP" if not defined $OPTS{hasp};
}
if(defined $OPTS{hasp}){
	die "please, give me '--pid=\\d+' option" unless defined $OPTS{pid};
}

#my $PRJ_DIR = $FindBin::Bin;
$OPTS{$_} = File::Spec->rel2abs($OPTS{$_}) foreach grep { /-dir$/ } keys %OPTS;

#print "$_ => $OPTS{$_}\n" foreach keys %OPTS;

main();

sub main{
	my $prj_dir = $OPTS{"prj-dir"};
	my $tmp_dir = $OPTS{"tmp-dir"};
	my $dest_dir = $OPTS{"dest-dir"};

	print "Prepare hasp...\n";
	my $hasp = choose_hasp();
	system "mkdir -p $tmp_dir" unless -e $tmp_dir;
	system "cp -r $prj_dir/redist/$hasp $tmp_dir";
	build_hasp("$tmp_dir/$hasp");
	
	if(my $aksusbd = choose_aksusbd()){
		print "Choose aksusbd... $aksusbd\n";
		my $dir = "$dest_dir/redist";
		system "mkdir -p $dir" unless -e $dir;
		system "cp $prj_dir/redist/$aksusbd $dir";
	}

	if(my $hasp_so = choose_hasp_so()){
		print "Choose hasp shared object... $hasp_so\n";
		my $so_dir = "$dest_dir/usr/local/lib".($OPTS{arch} eq "x86_64" ? "64" : "");
		system "mkdir -p $so_dir" unless -e $so_dir;
		system "cp $prj_dir/redist/VN-HASP/lib/VN/HASP/HASPHL/hasp/$hasp_so $so_dir";
	}

	print "Compile haspd...\n";
	my $dir1 = "$tmp_dir/usr/local/sbin";
	system "mkdir -p $dir1" unless -e $dir1;
	system "cp $prj_dir/source/sbin/haspd.pl $dir1";
	my $dir2 = "$dest_dir/usr/local/sbin";
	system "mkdir -p $dir2" unless -e $dir2;
	system "perlapp --force --lib $tmp_dir/lib --exe $dir2/haspd $dir1/haspd.pl";

	print "Copy other files...\n";
	system "cp -r $prj_dir/source/etc $dest_dir";
	my $dir = "$dest_dir/usr/local";
	system "mkdir -p $dir" unless -e $dir;
	system "cp -r $prj_dir/source/bin $dir";
}

sub choose_hasp{
	if((not defined $OPTS{haspid} and not defined $OPTS{hasp}) or 
			defined $OPTS{haspid} and $OPTS{haspid} eq "NOHASP"){
		print "  choosing HASPemu\n";
		return "HASPemu";
	}
	else{
		print "  choosing VN-HASP\n";
		return "VN-HASP";
	}
}

sub choose_aksusbd{
	return if not defined $OPTS{haspid} or $OPTS{haspid} eq "NOHASP";
	my $slesno = $OPTS{slesno} || get_host_slesno();
	if($slesno >= 10){
		return "aksusbd-1.15-1.i386-x86_64.rpm";
	}
	else{
 		return "aksusbd-suse-1.14-3.i386.rpm";
	}	
}

sub choose_hasp_so{
	return if defined $OPTS{haspid} and $OPTS{haspid} eq "NOHASP";
	my $arch = $OPTS{arch} || get_host_arch();
	if($arch =~ /^x86_64$/){
		return "libhasp_linux_x86_64_108230.so";
	}
	elsif($arch =~ /^i\d86$/){
		return "libhasp_linux_108230.so";
	}
	else{
		die "unknown arch '$OPTS{arch}'";
	}
}

sub build_hasp{
	my $source_dir = shift;
	my $tmp_dir = $OPTS{"tmp-dir"};
	my @objs;
	if($source_dir =~ /VN-HASP$/){
		my $target_dir = "$tmp_dir/lib";
		system "rm -fr $target_dir" if -e $target_dir;
		my $dec_hid = $OPTS{hasp} eq "HASP4" ? hex $OPTS{haspid} : 0;
		system "$source_dir/set_params.pl -hid=$dec_hid -pid=$OPTS{pid} -fid=$OPTS{fid}";
		system "make -C $source_dir";
		system "make -C $source_dir LIB=$target_dir dist";
	}
	elsif($source_dir =~ /HASPemu$/){
		my $target_dir = $tmp_dir;
		system "cd $source_dir && perl Makefile.PL PREFIX=$target_dir";
		system "make -C $source_dir";
		system "make -C $source_dir install";
		system "rm -fr $target_dir/man";
		system "rm -f $target_dir/lib/perllocal.pod"; # it's a shit in any case
	}
	else{
		die "unknown HASP type";
	}
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

sub get_host_arch{
	my $arch = `uname -m`;
	chomp $arch;
	return $arch;
}

