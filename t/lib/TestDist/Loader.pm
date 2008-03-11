use strict;
use warnings;

package TestDist::Loader;

use TestDist;
use Path::Class ();
use File::Temp qw(tempdir);

use Moose;
use MooseX::AttributeHelpers;

has source => (
  is => 'ro',
  isa => 'Str',
  default => 't/dist',
);

has dir => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  lazy => 1,
  default => sub { tempdir(CLEANUP => 1) },
);

has dists => (
  isa => 'HashRef',
  default => sub { {} },
  metaclass => 'Collection::Hash',
  provides => {
    get    => 'get_dist',
    set    => 'set_dist',
    keys   => 'dist_names',
    values => 'dists',
  },
);

sub file {
  my ($self, $name) = @_;
  return Path::Class::dir($self->dir)->file($name);
}

sub BUILD {
  my ($self) = @_;

  my $dir = Path::Class::dir($self->source);

  for my $file (grep { !$_->is_dir && /\.dist$/ } $dir->children) {
    my $dist = TestDist->load("$file");
    $self->set_dist($dist->prefix => $dist);
    $dist->write($self->dir);
  }
}

1;
