use strict;
use warnings;

package XPAN::Archiver::Test;

use base qw(XPAN::Archiver);

use File::Temp ();
use Test::More ();

sub new {
  my $class = shift;
  my %p = @_;
  $p{path} ||= File::Temp::tempdir(CLEANUP => 1);
  my $self = $class->SUPER::new(%p);
  $self->inject_test_distributions;
  return $self;
}

sub test_distribution_files {
  return <t/dist/*.tar.gz>
}

sub inject_test_distributions {
  my $self = shift;
  $self->inject(-File => [ $self->test_distribution_files ]);
}

sub contains_dist_ok {
  my ($self, $name, $version) = @_;
  my $info = $name;
  $info .= "-$version" if @_ > 2;
  my $description = "test archiver contains $info";
  my $dist = eval { $self->find_dist($info) };
  Test::More::ok(
    $dist &&
    $dist->name eq $name &&
    @_ > 2 ? ($dist->version eq $version) : 1,
    $description,
  );
}

1;

