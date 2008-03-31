use strict;
use warnings;

package XPAN::App::Pinset::Command::add;

use base qw(XPAN::ArchiveCmd::Command);

=head1 NAME

XPAN::App::Pinset::Command::add - add pins to a pinset

=cut

sub opt_spec {
  return (
    [ 'pinset|p=s', 'pinset name to operate on (required)',
      { required => 1 },
    ],
    [ mode => [
      [ 'not-really|n', "don't apply change, just print it" ],
      [ 'non-interactive|N', "apply change without prompting" ],
      [ 'interactive|i', "show change and prompt to apply" ],
    ], { default => 'interactive' } ],
    [ 'update|U', 'only update pins if they exist, do not downgrade' ],
    [ 'reason|r=s', 'install reason (required)',
      { required => 1 },
    ],
    [ 'hard-reason|R=s', 'hard pin reason' ],
    [ 'include-deps|D!', 'include dependencies (default: yes)',
      { default => 1 },
    ],
    [ 'rebuild', 'rebuild index after changes' ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error("at least one pin is required") unless @$args;

  @$args = map {
    my $url = URI->new($_) or $self->usage_error("invalid URL: $_");
    $url->scheme && $url->scheme eq 'xpan'
      or $self->usage_error("non-XPAN URL: $_");
    $url
  } @$args;
}

sub run {
  my ($self, $opt, $args) = @_;

  my $ps = $self->archiver->find_pinset($opt->{pinset});
  my $change;
  my $DONE = "DONE\n";
  $ps->db->do_transaction(sub {
    my @dists = map {
      $self->archiver->url_to_dist($_) or
        Carp::croak "url is not a valid dist: $_"
    } @$args;
    $change = $ps->change(
      include_deps => $opt->{include_deps},
      dists => \@dists,
      extra => {
        update => $opt->{update},
        manual => 1,
        install_reason  => $opt->{reason},
        hard_pin_reason => $opt->{hard_reason},
      },
    );
    unless ($change->has_changes) {
      print "no changes\n";
      die $DONE;
    }
    print $change->table($change->changes);
    if ($opt->{mode} eq 'interactive') {
      print "Apply changes? [Y/n] ";
      chomp(my $ok = <STDIN>);
      $ok ||= 'y';
      if ($ok =~ /^y/i) {
        $change->apply;
      } else {
        print "Exiting.\n";
        die $DONE;
      }
    } elsif ($opt->{mode} ne 'not_really') {
      $change->apply;
    } else {
      die $DONE;
    }
  });
  die $ps->db->error if $ps->db->error and $ps->db->error !~ /$DONE$/;

  if ($opt->{rebuild} and $opt->{mode} ne 'not_really') {
    $self->archiver->indexer(-Pinset => pinset => $ps)->build;
  }
}
    
1;
