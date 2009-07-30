use strict;
use warnings;

package XPAN::App::Command::outdated;

use base qw(App::Cmd::Command);

=head1 NAME

XPAN::App::Command::outdated - print outdated dists

=cut

use XPAN::Archiver;

sub opt_spec {
  return (
    [ 'path|p=s', 'path to archive', { required => 1 } ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("pinset name is required") unless @$args == 1;
}

sub run {
  my ($self, $opt, $args) = @_;
  
  my $arch = XPAN::Archiver->new(
    path    => $opt->{path},
  );

  my %recent;

  my $iter = $arch->dists_by_name_iterator;
  while (my ($name, $dists) = $iter->()) {
    $recent{$name} = $dists->[-1]->version;
  }

  my $ps = $arch->find_pinset($args->[0]);

  require Text::Table;
  my $table = Text::Table->new(qw(name version available));
  for my $pin ($ps->pins) {
    next if $pin->hard_pin_reason;
    next if $pin->version eq $recent{$pin->name};
    $table->add($pin->name, $pin->version, $recent{$pin->name});
  }
  print $table;
}

1;
