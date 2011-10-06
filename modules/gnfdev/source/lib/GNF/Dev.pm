package GNF::Dev;
use strict;
use base "Exporter";
our @EXPORT_OK = qw(&read_cfg &roll_dist &clean_dist &print_dists);
use GNF::Config;
use GNF::Dev::Utils qw(get_host_arch get_host_slesno cmd);
use GNF::Dev::Objects;

use IPC::System::Simple qw(system);
use Cwd;

# create hash of dists
sub read_cfg{
	my $prj_cfg = shift;
	my $cfg_file = $prj_cfg->{"cfg-file"};
	die "$cfg_file not exists" unless -e $cfg_file;
	print "reading config from $cfg_file\n";
	my $cfg = new GNF::Config $cfg_file;
	die "failed read $cfg_file" unless defined $cfg;
	my $slug = $cfg->GetNodeValue("SLUG", "");
	my $version = $cfg->GetNodeValue("VERSION", "");
	my $dist_cfgs = $cfg->GetNodeValue("DIST", []);
	unless( @$dist_cfgs ) {
		die "config $cfg_file contains no distibution definations";
	}
	unless( $slug ) {
		die "config $cfg_file contains no SLUG parameter";
	}
	unless( $version ) {
		die "config $cfg_file contains no VERSION parameter";
	}
	my %dists;
	foreach (@$dist_cfgs){
		my $dist = {
			prj => $prj_cfg->{name},
			version => $version,
			slug => $slug,
			arch => get_host_arch,
			slesno => get_host_slesno,
			haspid => $_->{HASPID},
			pid => $prj_cfg->{pid},
			hasp => ($_->{HASP} ? $_->{HASP} : ($_->{SERIAL} ? "HASP4" : "HASPHL")),
			serial => $_->{SERIAL},
			maxproc => $_->{MAXPROC}
		};
		my $name = dist_name($dist);
		$dist->{name} = $name;
		$dist->{dir} = dist_dir($prj_cfg->{"home-dir"}, $dist);
		$dists{$name} = $dist;
	}
	return \%dists;
}

sub dist_name{
	my $dist = shift;
	my $dist_name = sprintf "%s-%s-%s-%s-sles%s", map {$dist->{$_}} qw(prj version slug arch slesno);
	$dist_name .= "-$dist->{maxproc}proc" if $dist->{maxproc};
	if($dist->{haspid} ne "NOHASP"){
		$dist_name .= ".HASPHL" if $dist->{hasp} eq "HASPHL";
		$dist_name .= ".$dist->{serial}" if $dist->{hasp} eq "HASP4";
	}
	return $dist_name;
}

sub dist_dir{
	my $home_dir = shift;
	my $dist = shift;
	my $dist_dir = "dist/$dist->{prj}-$dist->{version}-$dist->{slug}/$dist->{name}";
	return "$home_dir/$dist_dir" if $home_dir;
	return $dist_dir;
}

sub roll_dist{
	my $dist = shift;
	my $cwd = cwd;
	chdir $dist->{dir};
	my $tar_file_name = "$dist->{prj}-$dist->{version}.tar";
	foreach (qw(bin etc lib sbin usr)){
		cmd "tar rf $dist->{prj}-$dist->{version}.tar $_" if -e $_;
	}
	chdir $cwd;
}

sub clean_dist{
	my $dist = shift;
	cmd "rm -fr $_" foreach map { "$dist->{dir}/$_" } qw(bin etc lib sbin usr);
}

sub print_dist{
	my $dist = shift;
	printf " %7s | %16s | %8s | %8s | %16s | %7s | %6s | %6s \n", 
		map {$dist->{$_}} qw(version slug hasp haspid serial maxproc slesno arch);
}

sub print_dists{
	my $dists = shift;
	print "-"x97, "\n";
	print sprintf(" %7s | %16s | %8s | %8s | %16s | %7s | %6s | %6s \n", 
		"VERSION", "SLUG", "HASPTYPE", "HASPID", "SERIAL", "MAXPROC", "SLES", "ARCH"
	);
	print "-"x97, "\n";
	print_dist($dists->{$_}) foreach sort keys %{$dists};
	print "-"x97, "\n";
}

sub slice_dist{
	my $dist = shift;
	my $keys = join "|", @_;
	my %slice;
	foreach (keys %$dist){
		$slice{$_} = $dist->{$_} if /^$keys$/;
	}
	return \%slice;
}

1;

