use strict;
use warnings;

package XPAN::App::Command::pinset;

use base qw(App::Cmd::Command);

sub opt_spec {
  return (
    [ mode => [
      [ 'dump|d=s' => 'dump the given pinset' ],
      [ 'list|l' => 'list all pinsets' ],
    ], { required => 1 } ],
  );
}

my $sep = \" | \n | ";

sub _table {
  my (@cols) = @_;
  return Text::Table->new(
    $sep, map { $_, $sep } @cols,
  );
}

sub _print {
  my ($table) = @_;
  print $table->title, $table->rule('=', '='), $table->body;
}

sub run {
  my ($self, $opt, $args) = @_;

  my $archiver = $self->app->archiver;
  require Text::Table;
  if ($opt->{dump}) {
    my $key = $opt->{dump} =~ /^\d+$/ ? 'id' : 'name';
    my $pinset = $archiver->pinset->new(
      $key => $opt->{dump}
    )->load;
    my $table = _table(qw(dist version));
    for my $pin ($pinset->pins) {
      $table->add($pin->name, $pin->version);
    }
    _print($table);
  } else {
    my $table = _table(qw(id name));
    my $iter = $archiver->pinset->manager->get_objects_iterator;
    while (my $pinset = $iter->next) {
      $table->add($pinset->id, $pinset->name);
    }
    _print($table);
  }
};

1;
    
