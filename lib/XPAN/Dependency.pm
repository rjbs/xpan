use strict;
use warnings;

package XPAN::Dependency;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE dependencies (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  dist_id INTEGER NOT NULL,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20) NOT NULL,
  source VARCHAR(20) NOT NULL,
  UNIQUE(dist_id, name)
);
END
}

__PACKAGE__->meta->setup(
  table   => 'dependencies',

  columns => [
    id      => { type => 'integer', not_null => 1 },
    dist_id => { type => 'integer', not_null => 1 },
    name    => { type => 'varchar', length   => 100, not_null => 1 },
    version => { type => 'varchar', length   => 20, not_null => 1 },
    source  => { type => 'varchar', length   => 20, not_null => 1 },
  ],

  primary_key_columns => ['id'],

  relationships => [
    dist => {
      type => 'many to one',
      class => 'XPAN::Dist',
      column_map => { dist_id => 'id' },
    },
  ],
);
__PACKAGE__->make_manager_class;

1;
