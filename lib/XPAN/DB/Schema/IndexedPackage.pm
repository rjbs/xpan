package XPAN::DB::Schema::IndexedPackage;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('package_index_entries');

__PACKAGE__->add_columns(
  id => {
    data_type   => 'integer',
    is_nullable => 0,
    is_auto_increment => 1,
  },
  package => {
    data_type   => 'varchar',
    is_nullable => 0,
  },
  version => {
    data_type   => 'varchar',
    is_nullable => 1,
  },

  # The way we refer to what provides something isn't really firmly decided.
  # Maybe it's a FK to another table, maybe it's a path to a file in the
  # archive... I dunno. -- rjbs, 2009-08-01
  provided_by => {
    data_type   => 'varchar',
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint([ qw(package) ]);

1;
