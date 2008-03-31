use strict;
use warnings;

package XPAN::PinsetChange;

use Moose;
extends 'XPAN::Object';

has pinset => (
  is => 'ro',
  weak_ref => 1,
  isa => 'XPAN::Pinset',
);

has dists => (
  is => 'ro',
  isa => 'ArrayRef[XPAN::Dist]',
  auto_deref => 1,
);

has changes => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub { shift->build_changes },
);

has conflicts => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub { shift->build_conflicts },
);

has extra => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub { {} },
);

has include_deps => (
  is => 'ro',
  isa => 'Bool', 
  default => 1,
);

use Module::CoreList;
use CPAN::Version;
use Carp;

sub build_changes {
  my ($self) = @_;

  my %changes;

  my @queue = $self->dists;
  my %orig = map { $_ => 1 } @queue;

  my $order;
  my %seen;
  while (@queue) {
    my $dist = shift @queue;
    my $extra;
    if (ref $dist eq 'ARRAY') {
      ($dist, $extra) = @$dist;
    }
    next if $seen{$dist->id}++;
    my ($pin) = $self->pinset->find_pins({ name => $dist->name });

    if ($pin) {
      next if $pin->version eq $dist->version;

      $changes{$dist->name} = {
        from => $pin,
        to   => $dist,
      };
    } else {
      $changes{$dist->name} = {
        to => $dist,
      };
    }

    if ($orig{$dist}) {
      $changes{$dist->name}{extra} = $self->extra;
    } else {
      $changes{$dist->name}{extra} = $extra;
    }
    $changes{$dist->name}{order} = ++$order;

    next unless $self->include_deps;
    for my $dep ($dist->dependencies) {

      next if Module::CoreList->first_release($dep->name);
      next if $dep->name eq 'perl';

      unless (($pin && $dep->matches($self->pinset))
        || grep { $dep->matches($_->{to}) } values %changes) {

        my ($module) = sort {
          CPAN::Version->vcmp($b->version, $a->version) ||
          CPAN::Version->vcmp($b->dist->version, $a->dist->version)
        } $dep->matching_modules;

        unless ($module) {
          die "no module found to fulfill dependency " . $dep->as_string;
        }

        push @queue, [ $module->dist, {
          install_reason => 'dependency of ' . $dist->vname,
        } ];
      }
    }
  }

  return \%changes;
}

sub has_changes { 0 < keys %{ shift->changes } }

sub build_conflicts {
  my ($self) = @_;
  my $changes = $self->changes;
  my $conflicts = {
    map {
      $_ => $changes->{$_}
    }
    grep {
      $changes->{$_}{from} &&
      $changes->{$_}{from}->hard_pin_reason
    } keys %$changes
  };
  return $conflicts;
}

sub has_conflicts { 0 < keys %{ shift->conflicts } }

sub table {
  my ($self, $data) = @_;
  require Text::Table;
  my $table = Text::Table->new("dist", "from", "to", "manual", "reason");

  for (sort { $data->{$a}{order} <=> $data->{$b}{order} } keys %$data) {
    my $c = $data->{$_};
    $table->add(
      $_,
      $c->{from} && $c->{from}->version,
      $c->{to}->version,
      $c->{extra}{manual} ? 'yes' : 'no',
      $c->{extra}{install_reason},
    );
  }

  return $table->table;
}

sub apply {
  my ($self) = @_;
  my $changes = $self->changes;

  if ($self->has_conflicts) {
    Carp::confess "asked to apply changes, but conflicts are present";
  }

  my $ps = $self->pinset;
  $ps->db->do_transaction(sub {
    my @pins;
    for (keys %$changes) {
      my $dist = $changes->{$_}{to};
      if (my $pin = $changes->{$_}{from}) {
        $pin->version($dist->version);
        $pin->$_($self->extra->{$_}) for keys %{ $self->extra };
        #$pin->save;
        push @pins, $pin;
      } else {
        push @pins, $ps->add_pins(
          {
            name => $dist->name,
            version => $dist->version,
            pinset_id => $ps->id,
            db => $ps->db,
            %{ $changes->{$_}{extra} },
          }
        );
      }
    }
    $_->save for @pins;
    $ps->save;
  });
  die $ps->db->error if $ps->db->error;
}

1;
