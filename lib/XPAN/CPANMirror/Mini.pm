package XPAN::CPANMirror::Mini;
use Moose;
with 'XPAN::Role::CPANMirror::Basic';

use IO::File;
use IO::Zlib;

has root => (
  is  => 'ro',
  isa => 'Str', # path::class::dir
  required => 1,
);

sub _author_fn {
  my ($self, $author, $path) = @_;
  my @bits = map { substr $author, $_, 1 } (0..1);

  return $self->root . "/authors/id/$bits[0]/$bits[0]$bits[1]/$author/$path";
}

sub distfile {
  my ($self, $distfile) = @_;
  my ($author, $rest) = split m{/}, $distfile, 2;

  my $path = $self->_author_fn($author, $rest);
  warn "opening $path\n";
  my $file = IO::File->new($path, '<');

  return $file;
}

sub package_index {
  my ($self) = @_;
  my $fn   = $self->root . "/modules/02packages.details.txt.gz";
  my $file = IO::Zlib->new($fn, 'rb');

  return $file;
}

sub author_checksums {
  my ($self, $author) = @_;
  my $path = $self->_author_fn($author, 'CHECKSUMS');
  my $file = IO::File->new($path, '<');
  
  return $file;
}

no Moose;
1;
