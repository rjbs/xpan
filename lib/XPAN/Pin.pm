use strict;
use warnings;

package XPAN::Pin;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE pins (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  pinset_id INTEGER NOT NULL,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20),
  manual INTEGER NOT NULL DEFAULT 0,
  comment TEXT,
  UNIQUE(pinset_id, name) 
);
END
}

__PACKAGE__->meta->setup(
  table => 'pins',

  columns => [
    id        => { type => 'integer', not_null => 1 },
    pinset_id => { type => 'integer', not_null => 1 },
    name     => { type => 'varchar', length   => 100, not_null => 1 },
    version  => { type => 'varchar', length   => 20 },
    manual    => { type => 'integer', not_null => 1, default => 0 },
    comment   => { type => 'text' },
  ],

  primary_key_columns => ['id'],

  relationships => [
    pinset => {
      type       => 'many to one',
      class      => 'XPAN::Pinset',
      column_map => { pinset_id => 'id' },
    },

    dists => {
      type       => 'one to many',
      class      => 'XPAN::Dist',
      column_map => { dist_id => 'id' },
    },
  ],
);
__PACKAGE__->make_manager_class;

1;
