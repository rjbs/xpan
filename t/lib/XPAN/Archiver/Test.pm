use strict;
use warnings;

package XPAN::Archiver::Test;

use base qw(XPAN::Archiver);

use File::Temp ();

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

1;

