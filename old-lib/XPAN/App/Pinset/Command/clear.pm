use strict;
use warnings;

package XPAN::App::Pinset::Command::clear;

use base qw(XPAN::ArchiveCmd::Command);

=head1 NAME

XPAN::App::Pinset::Command::clear - delete pins and pinsets

=cut

sub opt_spec {
  return (
    [ 'pinset|p=s', 'pinset name to operate on (required)',
      { required => 1 },
    ],
    [ mode => [
      [ 'pins', 'delete selected pins (default)' ],
      [ 'all', 'delete all pins' ],
      [ 'entire', 'delete entire pinset' ],
    ], { default => 'pins' } ],
    [ 'rebuild', 'rebuild index after changes' ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  if ($opt->{mode} eq 'pins') {
    $self->usage_error("must specify one or more pins with --pins")
      unless @$args;
    @$args = map { URI->new($_) } @$args;
  } else {
    $self->usage_error("0 arguments are needed with --$opt->{mode}")
      if @$args;
  }
}

sub run {
  my ($self, $opt, $args) = @_;
  my $ps = $self->archiver->find_pinset($opt->{pinset});

  if ($opt->{mode} eq 'entire') {
    $ps->delete;
    exit 0;
  }

  my @pins;
  if ($opt->{mode} eq 'all') {
    @pins = $ps->pins;
  } else {
    @pins = map {
      $ps->find_pins([ name => $_->name, version => $_->version ])
    } @$args;
  }
  require Text::Table;
  my $table = Text::Table->new(qw(name version reason hard_reason));
  $ps->db->do_transaction(sub {
    for my $pin (@pins) {
      $table->add(
        $pin->name,
        $pin->version,
        $pin->install_reason,
        $pin->hard_pin_reason
      );
      $pin->delete;
    }
    $ps->save;
  });
  die $ps->db->error if $ps->db->error;
  print $table;

  if ($opt->{rebuild}) {
    $self->archiver->indexer(-Pinset => pinset => $ps)->build;
  }
}

1;
