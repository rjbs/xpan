use strict;
use warnings;

package XPAN::DB;

use base qw(Rose::DB);

__PACKAGE__->use_private_registry;

#__PACKAGE__->register_db(
#  driver => 'SQLite',
#  database => 'xpan.db',
#);

sub table_classes {
  return map { "XPAN::$_" } qw(
    Dist
    Module
    Dependency
    Pinset
    Pin
  )
}

sub create_tables {
  my $self = shift;
  for my $table_class (reverse $self->table_classes) {
    eval "require $table_class";
    die $@ if $@;
    eval {
      $self->dbh->do($table_class->__create);
    };
    warn $@ if $@;
  }
}

1;
