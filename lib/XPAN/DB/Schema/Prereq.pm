package XPAN::DB::Schema::Prereq;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('dist_prerequisites');

__PACKAGE__->add_columns(
  id => {
    data_type   => 'integer',
    is_nullable => 0,
    is_auto_increment => 1,
  },
  dist_id => {
    data_type   => 'varchar',
    is_nullable => 0,
  },
  package => {
    data_type   => 'varchar',
    is_nullable => 0,
  },
  version => {
    data_type   => 'varchar',
    is_nullable => 0,
    default_value => 0,
  },
);

__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->add_unique_constraint([ qw(dist_id package) ]);

1;
