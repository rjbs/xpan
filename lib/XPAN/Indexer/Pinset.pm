use strict;
use warnings;

package XPAN::Indexer::Pinset;

use Moose;
extends 'XPAN::Indexer::Latest';

use Moose::Util::TypeConstraints;

subtype 'Pinset'
  => as 'Object'
  => where { $_->isa('XPAN::Pinset') };

coerce 'Pinset'
  => from 'Int'
  => via { XPAN::Pinset->new(id => $_)->load }
  => from 'Str'
  => via { XPAN::Pinset->new(name => $_)->load };

has pinset => (
  is => 'ro',
  isa => 'Pinset',
  required => 1,
  coerce => 1,
  handles => [qw(name)],
);

use Carp;
use Digest::MD5 ();
use Module::Faker::Dist;

sub choose_distribution_version {
  my $self = shift;
  my $name = shift;
  my @dists = @_;

  my ($pin) = $self->pinset->find_pins({ name => $name });

  unless ($pin) {
    return $self->SUPER::choose_distribution_version($name, @dists);
  }
  my ($match) = grep { $_->version eq $pin->version } @dists;

  unless ($match) {
    Carp::confess "no pin found matching " . $pin->as_string;
  }

  return $match;
}

sub extra_distributions {
  my ($self) = @_;
  
  my $ps = $self->pinset;
  my $ctx = Digest::MD5->new;
  $ctx->add($_->name . '=' . $_->version) for $ps->pins;
  my $origin = $ctx->hexdigest;
    
  my $name = $ps->name;
  $name =~ tr/-/_/;
  $name = "XPAN-Task-Pinset-$name";
  (my $mod_name = $name) =~ s/-/::/;

  my ($dist) = sort {
    CPAN::Version->vcmp($b->version, $a->version)
  } @{ $self->archiver->dist->manager->get_objects(
    query => [ name => $name ],
    db => $ps->db,
  ) };

  unless ($dist and $dist->origin eq $origin) {
    my $version = 1 + ($dist ? $dist->version : 0);
    my %req;
    for my $pin ($ps->pins) {
      my $d = $pin->dist;
      for my $m (grep { $_->version } $d->modules) {
        $req{$m->name} = $m->version;
      }
    }
    my $fake = Module::Faker::Dist->new({
      name    => $name,
      version => $version,
      abstract => "all modules contained in " . $ps->name,
      requires => \%req,
    });
      
    $self->archiver->db->do_transaction(sub {
      my $res = $self->archiver->auto_inject_one(
        'file://' . $fake->make_archive
      );
      unless ($res->dist) { die $res->message }
      $dist = $res->dist;
      $dist->origin($origin);
      $dist->save;
    });
    die $self->archiver->db->error if $self->archiver->db->error;
  }
  return $dist;
}

1;
