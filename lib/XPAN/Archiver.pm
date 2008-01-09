use strict;
use warnings;

package XPAN::Archive;

use Carp;
use base qw(Rose::Object);
use Rose::Object::MakeMethods::Generic (
);
use Path::Class ();

sub path {
  my $self = shift;
  if (@_) {
    $self->{path} = Path::Class::dir(shift);
  }
  return $self->{path} || Carp::croak("'path' is required");
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

sub injector {
  my ($self, $name) = @_;
  $name = "XPAN::Injector::$name" if $name =~ s/^-//;
  return $name->new({
    archiver => $self,
  });
}

sub inject {
  my $self = shift;
  my @args = @_;
  while (@args) {
    my ($injector_class, $args) = splice @args, 0, 2;



1;
