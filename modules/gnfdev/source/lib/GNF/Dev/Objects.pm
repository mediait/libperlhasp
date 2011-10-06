package GNF::Dev::Objects;
use strict;

use GNF::Dev::Utils qw(cmd);

use File::Basename;
use Tie::File;
use File::Find::Rule;
use Cwd;
use IPC::System::Simple qw(system);

use Data::Dumper;

# just 2 rm __PACKAGE__::find from unpolite File::Find::Rule::Procedural
BEGIN{
	no strict "refs";
	my $package = __PACKAGE__."::";
	my ($sub) = grep { $package->{$_} =~ /::find$/ } keys %$package;
	delete $package->{$sub};
}
	
# creates objs with from list of paths
sub are{
	my $class = shift;
	my @objs = @_;
	chomp @objs;
	my $self = \@objs;
	foreach (@$self){
		warn "obj '$_' not exists" unless -e $_;
	}
#	return bless $self, $class;
	$self = bless $self, $class;
	$self->show("$class fresh") if $ENV{DEBUG};
	return $self;
}

# creates objs with list of childs of from
sub from{
	my $class = shift;
	my $from = shift;
	$from =~ s/\/$//;
	return $class->are( map { "$from/$_" } `ls "$from/"`);
}

# creates objs with just one item, same shit as 'are':)
sub at{
	my $class = shift;
	my $at = shift;
	return $class->are($at);
}

sub as{
	my $self = shift;
	my $class = shift;
	return bless $self, $class;
}

sub each{
	my $self = shift;
	my $class = ref $self;
	my $action = shift || return $self;
	my $a;
	my @objs;
	if(ref $action eq "CODE"){
		# TODO: test
		$a = sub { 
			$action->(@_); 
		};
	}
	elsif(ref $action eq ""){
		$a = sub { 
			printf "cwd: %s\n", cwd;
			system sprintf $action, @_; 
			return; 
		}
	}
	else{
		die "arg must be CODE or SCALAR with cmd";
	}
	foreach my $obj (@$self){
		my $obj = $a->($obj);
		push @objs, $obj if defined $obj;
	}
	if(ref $action eq "CODE"){
		return GNF::Dev::Objects->are(@objs);
	}
	return $self;
}

sub find{
	my $self = shift;
	my $class = ref $self;
	my $rule = shift || return $self;
	return $class->are($rule->extras({follow => 1})->in(@$self));
}

sub files{
	my $self = shift;
	return $self->find(File::Find::Rule->file) unless @_;
	return $self->find(File::Find::Rule->file->name(@_));
}

sub dirs{
	my $self = shift;
	return $self->find(File::Find::Rule->directory) unless @_;
	return $self->find(File::Find::Rule->directory->name(@_));
}

sub dir{
	my $self = shift;
	my $dirname = shift;
	return $self->find(File::Find::Rule->directory->maxdepth(1)->name($dirname));
}

sub cp{
	my $self = shift;
	my $class = ref $self;
	my $to = shift;
	system "mkdir -p $to" unless -e $to;
	my @objs;
	foreach (@$self){
		my $name = basename $_;
		warn "file $to/$name already exists" if -f "$to/$name";
		_cp($_,$to);
		push @objs, "$to/$name";
	}
	return $class->are(@objs);
}

sub mv{
	my $self = shift;
	my $class = ref $self;
	my $to = shift;
	my @objs;
	foreach (@$self){
		system "mkdir -p $to" unless -e $to;
		my $name = basename $_;
		warn "$to/$name already exists" if -e "$to/$name";
		system "mv $_ $to";
		push @objs, "$to/$name";
	}
	return $class->are(@objs);
}

# ?????????????
# copy with prefixes 
# modules/libperlhasp/source
sub graft{
	my $self = shift;
	$self->show("GRAFT");
	my $class = ref $self;
	my $cut_at = shift;
	$cut_at =~ s/\/$//;
#	$cut_at = qr($cut_at);
	my $to = shift;
	$to =~ s/\/$//;
	my @objs;
	foreach my $obj (@$self){
		my $obj_dir = dirname $obj;
		(my $dir = $obj_dir) =~ s/^$cut_at//;
		$dir = "$to/$dir";
		$dir =~ s/\/$//;
#		print "F: $obj, OBJ: $obj, DIR: $dir\n";
		system "mkdir -p $dir" unless -e $dir;
		_cp($obj,$dir);
		my $obj_name = basename $obj;
		push @objs, "$dir/$obj_name";
	}
	return $class->are(@objs);
}

sub _cp{
	system sprintf "cp -f%s $_[0] $_[1]", -d $_[0] ? "r" : "";
}

sub patch{
	my $self = shift;
	_patch_file($_,@_) foreach @$self;
	return $self;
}

sub _patch_file{
	my $file = shift;
	my $what = shift || die "nothing to replace";
	my $with = shift || die "with what to replace";
	tie my @lines, "Tie::File", $file or die "failed tie $file: $!";
	foreach (@lines){
		if(s/$what/$with/){
			print "  patched $file:'$_'\n";
		}
	}
	untie @lines;
}

sub show{
	my $self = shift;
	my $msg = shift;
	print "    $msg\n" if $msg;
	print "     --> $_\n" foreach @$self;
	return $self;
}

package GNF::Dev::CprogDirs;
use base "GNF::Dev::Objects";
use File::Basename;
use IPC::System::Simple qw(system);

sub from{
	my $class = shift;
	my $from = shift;
	return $class->are(File::Find::Rule
		->directory
		->exec( sub{
				return 1 if -e "$_[0]/Makefile";
				return 0;
			})
		->in($from)
	);
}

sub make{
	my $self = shift;
	my $args = shift;
	my $make = "make -C %s".($args ? " $args" : "");
	return $self->each($make)->find(File::Find::Rule
		->file
		->executable
		->exec( sub{
				my $dir = basename $_[1];
				return 1 if $_[0] eq $dir;
				return 0;
			})
	);
}

package GNF::Dev::Pprogs;
use base "GNF::Dev::Objects";
use File::Basename;
use IPC::System::Simple qw(system);

sub from{
	my $class = shift;
	my $from = shift;
	return $class->are(File::Find::Rule->file->name('*.pl')->maxdepth(1)->in($from));
}

sub compile{
	my $self = shift;
	my $args = shift;
	return $self->each(sub {
			my ($path) = @_;
			my $name = basename $path, ".pl";
			my $dir = dirname $path;
			print "perlapp $args --exe $dir/$name $path\n";
			system "perlapp $args --exe $dir/$name $path";
			unless(-e "$dir/$name"){
				warn "result binary file $dir/$name not found\nMay be u give me '--exe'?\nI don't need it:)";
				return;
			}
			return "$dir/$name";
	});
}


1;

