use strict;
use warnings;

package XPAN::Module;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE modules (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20),
  file VARCHAR(110) NOT NULL,
  abstract TEXT,
  dist_id INTEGER NOT NULL,
  UNIQUE(name, version)
);
END
}

__PACKAGE__->meta->setup(
  table   => 'modules',
  columns => [
    id       => { type => 'integer', not_null => 1 },
    name     => { type => 'varchar', length   => 100, not_null => 1 },
    version  => { type => 'varchar', length => 20 },
    file     => { type => 'varchar', length   => 110, not_null => 1 },
    dist_id  => { type => 'integer', not_null => 1 },
    abstract => { type => 'text' },
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
