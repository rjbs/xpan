use strict;
use warnings;

package XPAN::App::Pinset::Command::create;

use base qw(XPAN::ArchiveCmd::Command);

=head1 NAME

XPAN::App::Pinset::Command::create - create a new pinset

=cut

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error("pinset name is required") unless @$args;
}

sub run {
  my ($self, $opt, $args) = @_;

  my $ps = $self->archiver->pinset->new(
    name => $args->[0]
  );
  if ($ps->load(speculative => 1)) {
    $self->log->warning("pinset $args->[0] already exists");
    exit 1;
  }
  $ps->save;
  $self->log->info("created pinset $args->[0]");
}

1;
