use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $arch = ($^O =~ /^(linux|darwin)$/) ? 
		( `uname -p | grep x86_64` ? 'x86_64' : 'x86' ) :
		( 'unknown' ); 

WriteMakefile(
    NAME              => 'VN::HASP::HASP4',
    VERSION_FROM      => 'lib/VN/HASP/HASP4.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VN/HASP/HASP4.pm', # retrieve abstract from module
       AUTHOR         => 'root <support@mediaitpro.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    ($^O eq 'MSWin32' ?
	  ('OBJECT'		=> '$(O_FILES) hasp\vnhasp.lib') :
	  (( $arch eq 'x86_64' ) ?
		('OBJECT'		=> '$(O_FILES)' ) :
		('OBJECT'		=> '$(O_FILES) hasp/libhasplnx.a')),
    ),
	($arch eq 'x86_64' ?
      ('DEFINE'         => '-D_HASPEMU_' ) : 
      ('DEFINE'         => '' )
    ),
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'VN::HASP::HASP4',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
