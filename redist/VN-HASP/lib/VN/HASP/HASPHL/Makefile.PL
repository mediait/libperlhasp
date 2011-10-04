use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if( $^O =~ /^(linux|darwin)$/ &&
	system('./install_lib.sh') != 0 ) {
	exit $?;	
}

my $arch = ($^O =~ /^(linux|darwin)$/) ? 
		( `uname -p | grep x86_64` ? 'x86_64' : 'x86' ) :
		( 'unknown' ); 

WriteMakefile(
    NAME              => 'VN::HASP::HASPHL',
    VERSION_FROM      => 'lib/VN/HASP/HASPHL.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VN/HASP/HASPHL.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@suse.de>') : ()),
    ($^O eq 'MSWin32' ?
	  ('OBJECT'		=> '$(O_FILES) hasp\libhasp_windows.lib') :
	  (( $arch eq 'x86_64' ) ?
#		('OBJECT'		=> '$(O_FILES) hasp/libhasp_linux_x86_64_108230.a') :
		('OBJECT'		=> '$(O_FILES)' ) :
		('OBJECT'		=> '$(O_FILES) hasp/libhasp_linux_108230.a'))
    ),
	($arch eq 'x86_64' ?
      ('LIBS'           => [ '-lhasp_linux_x86_64_108230' ] ) : 
#     ('LIBS'           => [ '-lhasp_linux_108230' ] )
      ('LIBS'           => [ '' ] )
    ),
   #PERL_INSTALL_ROOT	=> './build',
   DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
   INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'VN::HASP::HASPHL',
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
