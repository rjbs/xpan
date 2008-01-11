use strict;
use warnings;

package XPAN::Injector;

use base qw(Rose::Object);
use Rose::Object::MakeMethods::Generic (
  'scalar --get_set_init' => [qw(archiver)],
);

use Scalar::Util ();
use Carp ();

sub init_archiver { Carp::croak "'archiver' is required" }

sub new {
  my $self = shift->SUPER::new(@_);
  Scalar::Util::weaken($self->{archiver}) if exists $self->{archiver};
  return $self;
}

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
