package XPAN::DB::Schema::Dist;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('dists');

# I've pondered adding version here.  For now, adding as little data as
# possible for re-proof of concept. -- rjbs, 2009-08-01
__PACKAGE__->add_columns(
  id => {
    data_type   => 'integer',
    is_nullable => 0,
    is_auto_increment => 1,
  },
  author => {
    data_type   => 'varchar',
    is_nullable => 0,
  },
  filename => {
    data_type   => 'varchar',
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->add_unique_constraint(dist_file => [ qw(author filename) ]);

1;
