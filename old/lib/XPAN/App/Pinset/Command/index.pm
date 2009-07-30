use strict;
use warnings;

package XPAN::App::Pinset::Command::index;

use base qw(XPAN::ArchiveCmd::Command);

=head1 NAME

XPAN::App::Pinset::Command::index - build CPAN index files from a pinset

=cut

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error("pinset name is required") unless @$args;
  $self->usage_error("exactly 1 argument is required") unless @$args == 1;
}

sub run {
  my ($self, $opt, $args) = @_;

  my $ps = $self->archiver->find_pinset($args->[0]);

  $self->archiver->indexer(-Pinset => pinset => $ps)->build;
}

1;
