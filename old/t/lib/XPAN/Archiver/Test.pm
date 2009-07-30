use strict;
use warnings;

package XPAN::Archiver::Test;

use Moose;
extends 'XPAN::Archiver';

use XPAN::Context::Test;

has inject_tests => (
  is => 'ro',
  isa => 'Bool',
  default => 1,
);

has '+path' => (
  default => sub { File::Temp::tempdir(CLEANUP => 1) },
);

has '+context' => (
  default => sub { XPAN::Context::Test->new }
);

has '+config' => (
  default => sub { XPAN::Config->read_file('t/xpan.ini') },
);

use File::Temp ();
use Module::Faker ();
use Test::More ();
use File::Copy ();

sub BUILD {
  my ($self) = @_;
  $self->inject_test_distributions if $self->inject_tests;
  File::Copy::copy(
    't/xpan.ini',
    $self->path->file('xpan.ini'),
  );
}

sub test_distribution_files {
  my $tmp_archive_dir = File::Temp::tempdir(CLEANUP => 1);
  Module::Faker->make_fakes({
    source => 't/dist/',
    dest   => $tmp_archive_dir,
  });

  return <$tmp_archive_dir/*.tar.gz>
}

sub inject_test_distributions {
  my $self = shift;
  $self->batch_auto_inject(
    (map { "file://$_" } $self->test_distribution_files),
    { no_deps => 1 },
  );
}

sub contains_dist_ok {
  my ($self, $name, $version) = @_;
  my $label = $name;
  $label .= "-$version" if @_ > 2;
  my $description = "test archiver contains $label";
  my $dist = $self->find_dist([ $name, @_ > 2 ? $version : () ]);
  Test::More::ok(
    $dist &&
    $dist->name eq $name &&
    (@_ > 2 ? ($dist->version eq $version) : 1) &&
    $dist->authority &&
    $dist->origin,
    $description,
  );
  return $dist;
}

1;

