use strict;
use warnings;

package XPAN::Injector;

use base qw(XPAN::Object::HasArchiver);

use Scalar::Util ();
use Carp ();

sub arg_to_filename {
  my ($self, $arg) = @_;
  Carp::croak "$self must implement arg_to_filename ($arg)";
}

sub inject {
  my $self = shift;
  warn "inject: $self @_\n";
  for my $arg (@_) {
    warn "$self => $arg\n";
    eval { 
      $self->archiver->dist_from_file(
        $self->arg_to_filename($arg)
      )->save;
    };
    if ($@) {
      warn "error processing '$arg': $@";
    }
  }
}

1;
