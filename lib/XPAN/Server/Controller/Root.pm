package XPAN::Server::Controller::Root;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub index : Path('/') Args(0) {
  my ($self, $c) = @_;
  $c->res->body('This server is powered by XPAN::Server.');
}

sub default : Private {
  my ($self, $c) = @_;
  $c->res->body('No such resource.');
  $c->res->status(404);
}

sub author : Chained('/') PathPart('authors/id') CaptureArgs(3) {
  my ($self, $c, @authorparts) = @_;

  my $author = $c->stash->{author} = $authorparts[2];

  $c->detach('default')
    unless $authorparts[0] eq substr($author, 0, 1)
    and    $authorparts[1] eq substr($author, 0, 2)
}

sub authorfile : Chained('author') PathPart('') {
  my ($self, $c, @args) = @_;
  my $author = $c->stash->{author};

  if (@args == 1 and $args[0] eq 'CHECKSUMS') {
    my $fh = $c->model('CPANMirror')->author_checksums($author);
    $c->res->body($fh);
    $c->detach;
  }

  my $fh = $c->model('CPANMirror')->author_file($author, join(q{/}, @args));
  $c->res->body($fh);
}

sub package_index_gz : Path('modules/02packages.details.txt.gz') {
  my ($self, $c) = @_;

  my $index_fh = $c->model('CPANMirror')->package_index_gz;
  $c->res->body($fh);
}

1;
