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
use Perl::Version;

sub choose_distribution_version {
  my $self = shift;
  my $name = shift;
  my @dists = @_;

  # do not include dists that we have no pin for
  my ($pin) = $self->pinset->find_pins({ name => $name }) or return;

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

  unless ($dist and $dist->origin and $dist->origin eq $origin) {
    my $version = 1 + ($dist ? $dist->version : 0);
    my %req;
    for my $pin ($ps->pins) {
      my $d = $pin->dist;
      my @m;
      @m = grep { $d->is_simile($_) } $d->modules;
      @m = grep {
        defined $_->version
        && $_->version eq $d->version
        && ! $_->is_inner_package
      } $d->modules unless @m;
      @m = grep {
        defined $_->version
        && eval { Perl::Version->new($_->version) }
        && ! $_->is_inner_package
      } $d->modules unless @m;
      #warn "selecting modules for " . $d->vname . "\n";
      for (@m) {
        $req{$_->name} = $_->version;
        #warn ">> " . $_->name . ' ' . $_->version . "\n";
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
