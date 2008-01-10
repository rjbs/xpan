use strict;
use warnings;

package XPAN::DB;

use base qw(Rose::DB);

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
  driver => 'SQLite',
  database => 'xpan.db',
);

sub table_classes {
  return map { "XPAN::$_" } qw(
    Dist
    Module
    Dependency
  )
}

sub create_tables {
  my $self = shift;
  for my $table_class ($self->table_classes) {
    eval "require $table_class";
    die $@ if $@;
    $self->dbh->do($table_class->__create);
  }
}

1;
