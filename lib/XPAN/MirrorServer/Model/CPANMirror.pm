package XPAN::MirrorServer::Model::CPANMirror;
use base 'Catalyst::Model';

use XPAN::CPANMirror::Mini;

sub new {
  my $mirror = XPAN::CPANMirror::Mini->new({
    root => "$ENV{HOME}/mirrors/minicpan",
  });

  return $mirror;
}

1;
