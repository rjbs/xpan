use strict;
use warnings;

package XPAN::DB::Object::Manager;

use base qw(Rose::DB::Object::Manager);

sub object_class {
  my ($self) = @_;
  my $class = ref $self || $self;
  (my $object = $class) =~ s/::Manager$//;
  return $object;
}

1;
