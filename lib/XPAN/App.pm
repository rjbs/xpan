use strict;
use warnings;

package XPAN::App;

use base qw(App::Cmd);
use Rose::Object::MakeMethods::Generic (
  'scalar --get_set_init' => 'archiver',
);

use XPAN::Archiver;

sub global_opt_spec {
  return (
    [ 'path|p=s', 'path to archive', { required => 1 } ],
  );
}

sub init_archiver {
  my $self = shift;
  return XPAN::Archiver->new(
    path => $self->global_options->{path},
  );
}

1;
