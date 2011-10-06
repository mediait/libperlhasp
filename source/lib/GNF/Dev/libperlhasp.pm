package GNF::Dev::libperlhasp;
use strict;
use base "GNF::Dev::Objects";

use GNF::Dev::Utils qw(cmd get_host_slesno get_host_arch);

use Cwd;
use File::Basename;
use Data::Dumper;
use IPC::System::Simple;

sub choose_aksusbd{
	my $self = shift;
#	$self->show("choose aksusbd");
	my $cfg = shift;
	my $slesno = $cfg->{slesno} || get_host_slesno;
	if($slesno >= 10){
		print "  choosing aksusbd-1.15-1.i386-x86_64.rpm\n";
		return $self->dir( "redist")->files( 'aksusbd-1.15-1.i386-x86_64.rpm');
	}
	else{
		print "  choosing aksusbd-suse-1.14-3.i386.rpm\n";
 		return $self->dir( "redist")->files( 'aksusbd-suse-1.14-3.i386.rpm');
	}	
}

sub choose_hasp{
	my $self = shift;
	my $class = ref $self;
	my $cfg = shift;
	my $haspid = $cfg->{haspid};
#	$self->show("choose_hasp");
	if($haspid eq "NOHASP"){
		print "  choosing HASPemu\n";
		return $self->dir("redist")->dir("HASPemu");
	}
	else{
		print "  choosing VN-HASP\n";
		return $self->dir("redist")->dir("VN-HASP");
	}
}

sub fry{
	my $self = shift;
	my $cfg = shift;
	my @objs;
	if($self->[0] =~ /VN-HASP$/){
		my $dec_hid = $cfg->{hasp} eq "HASP4" ? hex $cfg->{haspid} : 0;
		system "$self->[0]/set_params.pl -hid=$dec_hid -pid=$cfg->{pid} -fid=1";
		system "make -C $self->[0]";
		system "make -C $self->[0] LIB=dist/ dist";
		# hmm
		my $target_dir = "$self->[0]/dist";
		system "mkdir -p $target_dir" unless -e $target_dir;
		my $dir = "$self->[0]/lib/VN/HASP/HASPHL/hasp";
		my $arch = $cfg->{arch} || get_host_arch;
		if($cfg->{hasp} eq "HASP4"){
			system "cp $self->[0]/lib/VN/HASP/HASP4/hasp/libhasplnx.a $target_dir";
		}
		elsif($cfg->{hasp} eq "HASPHL"){
			if($arch =~ /^x86_64$/){
				system "cp $dir/libhasp_linux_x86_64_108230.so $target_dir";
				system "cp $dir/libhasp_linux_x86_64_108230.a $target_dir";
			}
			elsif($arch =~ /^i\d86$/){
				system "cp $dir/libhasp_linux_108230.so $target_dir";
				system "cp $dir/libhasp_linux_108230.a $target_dir";
			}
			else{
				die "unknown arch '$arch'";
			}
		}
		else{
			die "unknown hasp '$cfg->{hasp}'";
		}
		return GNF::Dev::Objects->from("$self->[0]/dist");
	}
	elsif($self->[0] =~ /HASPemu$/){
		system "cd $self->[0] && perl Makefile.PL PREFIX=dist";
		system "make -C $self->[0]";
		system "make -C $self->[0] install";
		system "rm -f $self->[0]/dist/lib/perllocal.pod";
		return GNF::Dev::Objects->from("$self->[0]/dist/lib");
	}
	else{
		die "something went very wrong";
	}
}

1;

# my pray 4 laziness...       
