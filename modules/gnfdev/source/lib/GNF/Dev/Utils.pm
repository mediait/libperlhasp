package GNF::Dev::Utils;

use base "Exporter";
our @EXPORT_OK = qw(install_rpm get_host_slesno get_host_arch cmd);

use version;
use POSIX qw(mkfifo);
use File::Temp;
use File::Basename;

# prints itself 2 stdout and run it through IPC::System::Simpler
sub cmd{
	printf "  %s\n", join " ", @_;
	system @_;
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

# first arg - rpm file
# second - regexp which will be ignored in rpm name when checking 4 installed analog
# qr('-suse'), 4 example 
sub install_rpm{
	my $file = shift;
	my $ignore = shift || '';
	die 'second arg must be Regexp' if $ignore and ref($ignore) ne 'Regexp';
	my $file_name = basename($file);
	my $rpm_regex = qr|(.*?)-([0-9\.-]+)|;
	unless($file_name =~ /^$rpm_regex\.(.*)\.rpm$/){
		die "unknown rpm file name format '$file'";
	}
	my $could_name = $1;
	my $could_version = $2;
	my $could_suffix = $3;
	$could_version =~ s/-/_/g;
	$could_version = version->parse($could_version);
	$could_name =~ s/$ignore// if $ignore;
	my $found;
	foreach (`rpm -qa | grep '$could_name'`){
		chomp;
		unless(/^$rpm_regex/){
			die "unknown rpm -qa line '$_'";
		}
		my $was_name = my $has_name = $1;
		my $has_version = $2;
		$has_name =~ s/$ignore// if $ignore;
		next if $has_name ne $could_name;
		$has_version =~ s/-/_/g;
		$has_version = version->parse($has_version);
		if($could_version <= $has_version){
			print "already installed\n";
			return;
		}
		else{
			printf "found $_, uninstalling... ";
			system("rpm -e $was_name >/dev/null");
			print "ok\n";
		}
	}
	print "installing $file_name... ";
	system "rpm -i $file >/dev/null";	
	print "ok\n";
}

1;

