use strict;
use warnings;

package XPAN::Module;

use base qw(Rose::DB::Object);

sub __create {
  return <<END;
CREATE TABLE modules (
  id INTEGER NOT NULL AUTOINCREMENT PRIMARY KEY,
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
    file     => { type => 'varchar', length   => 110, not_null => 1 },
    dist_id  => { type => 'integer', not_null => 1 },
    abstract => { type => 'text' },
    version  => { type => 'varchar', length => 20 },
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

1;
