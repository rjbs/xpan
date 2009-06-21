use strict;
use warnings;

package XPAN::ResultSource;

use Moose::Role;
use XPAN::Result;

sub throw_result {
  my $self = shift;
  die $self->make_result(@_);
}

sub make_result {
  my $self = shift;
  my $res_class = 'XPAN::Result::' . shift;
  return $res_class->new(warning => {}, @_);
}

1;
