use strict;
use warnings;

package XPAN::DB;

use base qw(Rose::DB);

__PACKAGE__->use_private_registry;

sub table_classes {
  return map { "XPAN::$_" } qw(
    Dist
  )
}

sub create_tables {
  my $self = shift;
  for my $table_class ($self->table_classes) {
    $self->dbh->do($table_class->__create);
  }
}

1;
