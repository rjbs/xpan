use strict;
use warnings;

package XPAN::App::Pinset::Command::view;

use base qw(XPAN::ArchiveCmd::Command);

=head1 NAME

XPAN::App::Pinset::Command::view - view pinset list or single pinset

=cut

sub opt_spec {
  return (
    [ 'hard' => 'only show hard pins' ],
    [ 'manual' => 'only show manually-chosen dists' ],
  );
}

sub run {
  my ($self, $opt, $args) = @_;

  if (@$args) {
    my @ps = map {
      $self->archiver->find_pinset($_)
    } @$args;
    $self->_view($opt, @ps);
  } else {
    $self->_list(@{
      $self->archiver->pinset->manager->get_objects
    });
  }
}

sub _view {
  my $self = shift;
  my $opt  = shift;
  require Text::Table;
  for my $ps (@_) {
    print '+ ', $ps->name, "\n";
    my $table = Text::Table->new(
      \'  ', qw(name version manual install_reason hard_pin_reason)
    );
    for my $pin ($ps->pins) {
      next if $opt->{hard}   and not $pin->hard_pin_reason;
      next if $opt->{manual} and not $pin->manual;
      $table->add(map { $pin->$_ }
        qw(name version manual install_reason hard_pin_reason)
      );
    }
    print $table;
  }
}

sub _list {
  my $self = shift;
  for my $ps (@_) {
    $self->log->info($ps->name);
  }
}

1;
