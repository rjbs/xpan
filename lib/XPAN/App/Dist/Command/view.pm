use strict;
use warnings;

package XPAN::App::Dist::Command::view;

use base qw(XPAN::ArchiveCmd::Command);

=head1 NAME

XPAN::App::Dist::Command::view - view dist information (name or name + version)

=cut

sub usage_desc { '%c view <dist> [all|<version> <version...>]' }

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("dist name is required") unless @$args > 0;
}

sub run {
  my ($self, $opt, $args) = @_;
  require Text::Table;

  my $name = shift @$args;
  if (@$args) {
    my $iter = $self->archiver->dist->manager->get_objects_iterator(
      query => [
        name => $name,
        $args->[0] eq 'all' ? () : (version => $args)
      ],
    );
    while (my $dist = $iter->next) {
      $self->_details($dist);
    }
  } else {
    $self->_list($name);
  }
}

sub _list {
  my ($self, $name) = @_;
  my $iter = $self->archiver->dist->manager->get_objects_iterator(
    query => [ name => $name ],
  );
  print "+ $name\n";
  my $table = Text::Table->new(
    \'  ', qw(version pinsets),
  );
  while (my $dist = $iter->next) {
    $table->add(
      $dist->version,
      join ', ', map { $_->pinset->name } $dist->pins
    );
  }
  print $table;
}

sub _details {
  my ($self, $dist) = @_;
  print "+ " . $dist->vname . "\n";
  if ($dist->dependencies) {
    print "  + dependencies\n";
    my $table = Text::Table->new(
      \'    ', qw(name version),
    );
    for my $dep ($dist->dependencies) {
      $table->add($dep->name, $dep->version);
    }
    print $table;
  }
  if ($dist->pins) {
    print "  + pinsets\n";
    my $table = Text::Table->new(
      \'    ', qw(name),
    );
    for my $pin ($dist->pins) {
      $table->add($pin->pinset->name);
    }
    print $table;
  }
}

1;
