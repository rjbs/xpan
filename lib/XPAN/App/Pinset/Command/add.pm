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
    [ 'newer-only!', 'only update pins, do not downgrade' ],
    [ 'upgrade|U', 'upgrade existing pins, keeping install reason' ],
    [ 'reason|r=s', 'install reason (required)', { required => 1 } ],
    [ 'hard-reason|R=s', 'hard pin reason' ],
    [ 'force|f', 'force conflicts' ],
    [ 'include-deps|D!', 'include dependencies (default: yes)',
      { default => 1 },
    ],
    [ 'inject|I', 'inject non-xpan:// urls, then add them' ],
    [ 'rebuild', 'rebuild index after changes' ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error("at least one pin is required") unless @$args;
}

sub run {
  my ($self, $opt, $args) = @_;

  @$args = map {
    my $url;
    if (/^xpan:/) {
      $url = URI->new($_) or $self->usage_error("invalid URL: $_");
      $url->scheme && $url->scheme eq 'xpan'
        or $self->usage_error("non-XPAN URL: $_");
    } else {
      die "invalid URL: $_" unless $opt->{inject};
      my $res = $self->archiver->auto_inject_one($_);
      if ($res->dist) {
        $url = $res->dist->url;
      } else {
        die sprintf "Could not inject %s: %s",
          $res->url, $res->message;
      }
    }
    $url
  } @$args;

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
      upgrade => $opt->{upgrade},
      newer_only => $opt->{newer_only},
      force => $opt->{force},
      extra => {
        manual => 1,
        install_reason  => $opt->{reason},
        hard_pin_reason => $opt->{hard_reason},
      },
    );
    unless ($change->has_changes) {
      print "no changes\n";
      die $DONE;
    }
    if ($change->has_conflicts) {
      print "CONFLICTS PRESENT:\n";
      print $change->table($change->conflicts);
      die $DONE unless $change->force;
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
