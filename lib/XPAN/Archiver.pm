use strict;
use warnings;

package XPAN::Archiver;

use Carp;
use base qw(Rose::Object);
use Rose::Object::MakeMethods::Generic (
  'scalar --get_set_init' => [qw(analyzer analyzer_class)],
);
use Path::Class ();
use File::Copy ();
use XPAN::DB;

sub path {
  my $self = shift;
  if (@_) {
    $self->{path} = Path::Class::dir(shift);
  }
  return $self->{path} || Carp::croak("'path' is required");
}

sub init_analyzer_class { 'XPAN::Analyzer' }

sub init_analyzer {
  my $class = shift->analyzer_class;
  eval "require $class";
  die $@ if $@;
  $class->new;
}

sub init_db {
  my $self = shift;
  my $db_path = $self->path->file('xpan.db');
  XPAN::DB->register_db(
    driver => 'SQLite',
    database => $db_path,
  );
  my $exists = -e $db_path;
  my $db = XPAN::DB->new;
  $db->create_tables unless $exists;
  return $db;
}

sub db {
  my ($self) = @_;
  return $self->{db} ||= $self->init_db;
}

sub dist   { 'XPAN::Dist' }
sub module { 'XPAN::Module' }

sub do_transaction { shift->db->do_transaction(@_) }

sub injector {
  my ($self, $name) = @_;
  $name = "XPAN::Injector::$name" if $name =~ s/^-//;
  eval "require $name";
  die $@ if $@;
  return $self->{injector}{$name} ||= $name->new(
    archiver => $self,
  );
}

# should this return something useful?
sub inject {
  my $self = shift;
  my @args = @_;
  $self->do_transaction(sub {
    while (@args) {
      my ($name, $args) = splice @args, 0, 2;

      my $injector = $self->injector($name);
      warn "injecting: $name => $injector -> @$args\n";
      $injector->inject(@$args);
    }
  });
  die $self->db->error if $self->db->error;
}

sub dist_from_file {
  my ($self, $filename) = @_;

  my $dir = $self->path->subdir('dist');
  $dir->mkpath;

  my $dist_file = Path::Class::file($filename)->basename;
  my $dist = $self->dist->new(
    %{ $self->analyzer->analyze($filename) },
    file => $dist_file,
  );

  File::Copy::copy(
    $filename,
    $dir->file($dist_file),
  );

  return $dist;
}

1;
