use strict;
use warnings;

package XPAN::ArchiveCmd;

use Moose;
extends 'App::Cmd';

use XPAN::Archiver;

sub global_opt_spec {
  return (
    [ noise => [
      [ 'verbose|v',   'print debugging' ],
      [ 'quiet|q',     'only print errors' ],
    ] ],
    [],
    [ 'archive|a=s', 'path to XPAN archive (required)',
      { required => 1 },
    ],
  );
}

has archiver => (
  is => 'ro',
  isa => 'XPAN::Archiver',
  lazy => 1,
  default => sub {
    XPAN::Archiver->new(
      path => shift->global_options->{archive},
    );
  },
  handles => [qw(log)],
);

my %NOISE = (
  verbose => 'debug',
  quiet   => 'warning',
);

sub execute_command {
  my ($self, $cmd, $opt, @args) = @_;
  if ($self->global_options->{noise}) {
    $self->log->replace(
      [ screen => { min_level => $NOISE{$self->global_options->{noise}} }]
    );
  }
  $self->SUPER::execute_command($cmd, $opt, @args);
}

1;
