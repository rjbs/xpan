package XPAN::DB::Schema;
use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_classes(qw/Dist IndexedPackage Prereq/);
1;
