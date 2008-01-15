use strict;
use warnings;

package XPAN::Dist;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE dists (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20),
  abstract TEXT,
  file VARCHAR(110) NOT NULL,
  UNIQUE(name, version)
);
END
}

__PACKAGE__->meta->setup(
  table   => 'dists',

  columns => [
    id       => { type => 'integer', not_null => 1 },
    name     => { type => 'varchar', length   => 100, not_null => 1 },
    version  => { type => 'varchar', length   => 20 },
    file     => { type => 'varchar', length   => 110, not_null => 1 },
    abstract => { type => 'text' },
  ],

  primary_key_columns => ['id'],

  unique_keys => [ ['name', 'version' ] ],

  relationships => [
    modules => {
      type       => 'one to many',
      class      => 'XPAN::Module',
      column_map => { id => 'dist_id' },
    },

    dependencies => {
      type       => 'one to many',
      class      => 'XPAN::Dependency',
      column_map => { id => 'dist_id' },
    },
  ],
);
__PACKAGE__->make_manager_class;

1;
