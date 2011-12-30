#!/usr/bin/perl -w

use strict;
use FindBin;
use Getopt::Long;
use Pod::Usage;

our ($hid,$pid,$fid,$help);
our %CFG = ();
GetOptions(
   'haspID|hid=s'    => \$CFG{hid},
   'productID|pid=s'    => \$CFG{pid},
   'featureID|fid=s'    => \$CFG{fid},
);

pod2usage(-verbose=>1)
	unless defined($CFG{hid}) or defined($CFG{pid}) or defined($CFG{fid});
print "Setting the values:\n";
for( qw(hid pid fid) ) {
	$CFG{$_} = 0 unless defined( $CFG{$_} );
	print "\t$_ = ", $CFG{$_}, "\n";
}

my $dir = $FindBin::Bin;
# patch HASP.pm
my $file = "$dir/lib/VN/HASP.pm";
my $cmd = "perl -pi -e '";
$cmd .= "s/my \\\$HID = \\d+;/my \\\$HID = $CFG{hid};/; ";
$cmd .= "s/my \\\$PID = \\d+;/my \\\$PID = $CFG{pid};/; ";
$cmd .= "s/my \\\$FID = \\d+;/my \\\$FID = $CFG{fid};/; ";
$cmd .= "' $file";
print "Patching file '$file' ... "; 
system($cmd) == 0 || die "Cannot patch $file: $!\n";
print "ok\n";

$file = "$dir/lib/VN/HASP/HASP4/VNHASP.h";
$cmd = "perl -pi -e '";
$cmd .= "s/#define HASPID \\d+/#define HASPID $CFG{hid}/; ";
$cmd .= "' $file";
print "Patching file '$file' ... "; 
system($cmd) == 0 || die "Cannot patch $file: $!\n";
print "ok\n";

__END__

=head1 NAME

set_params.pl - Configure VN::HASP module 

=head1 SYNOPSIS

set_params.pl [options] 

=end
 Options:
   -hid=N	    set decimal HASP ID. 0 for no check (only new HASPHL).
   -pid=N	    set decimal Product ID. 0 for no ckeck. 
   -fid=N		set decimal Feature ID. 0 for no check.
   -h			show help
=cut

=head1 OPTIONS

=over 8

=item B<-hid=N>

Set decimal HASP ID. 0 for no check (only new HASPHL).
For HASP4 - this must be set.

=item B<-pid=N>

Set decimal Product ID. 0 for no ckeck. 

=item B<-fid=N>

Set decimal Feature ID. 0 for no check.

=back

=head1 DESCRIPTION

B<This program> will patch HASP modules with given HASP, Product and Feature
IDs. It have to be envoked before making the modules.

=cut
