use strict;
use warnings;

package XPAN::Archiver;

use Carp;
use base qw(Rose::Object);
use Rose::Object::MakeMethods::Generic (
  'scalar --get_set_init' => [qw(analyzer analyzer_class)],
);
use Path::Class ();
use File::Copy ();
use XPAN::DB;
use CPAN::DistnameInfo;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->db; # argh
  return $self;
}

sub path {
  my $self = shift;
  if (@_) {
    $self->{path} = Path::Class::dir(shift);
    $self->{path}->mkpath;
  }
  return $self->{path} || Carp::croak("'path' is required");
}

sub init_analyzer_class { 'XPAN::Analyzer' }

sub init_analyzer {
  my $class = shift->analyzer_class;
  eval "require $class";
  die $@ if $@;
  $class->new;
}

sub init_db {
  my $self = shift;
  my $db_path = $self->path->file('xpan.db');
  XPAN::DB->register_db(
    driver => 'SQLite',
    database => $db_path,
  );
  my $exists = -e $db_path;
  my $db = XPAN::DB->new;
  $db->create_tables unless $exists;
  return $db;
}

sub db {
  my ($self) = @_;
  return $self->{db} ||= $self->init_db;
}

sub dist       { require XPAN::Dist;       'XPAN::Dist' }
sub module     { require XPAN::Module;     'XPAN::Module' }
sub pinset     { require XPAN::Pinset;     'XPAN::Pinset' }
sub pin        { require XPAN::Pin;        'XPAN::Pin' }
sub dependency { require XPAN::Dependency; 'XPAN::Dependency' }

sub do_transaction { shift->db->do_transaction(@_) }

my %related_loaded;
sub _related_object {
  my ($self, $default_base, $name, @rest) = @_;
  $name = "$default_base\::$name" if $name =~ s/^-//;
  unless ($related_loaded{$name}++) {
    eval "require $name";
    die $@ if $@;
  }
  return $name->new(
    @rest,
    archiver => $self,
  );
}

sub injector { shift->_related_object('XPAN::Injector', @_) }
sub indexer  { shift->_related_object('XPAN::Indexer',  @_) }

# should this return something useful?
sub inject {
  my $self = shift;
  my @args = @_;
  $self->do_transaction(sub {
    while (@args) {
      my ($name, $args) = splice @args, 0, 2;

      my $injector = $self->injector($name);
      #warn "injecting: $name => $injector -> @$args\n";
      $injector->inject(@$args);
    }
  });
  die $self->db->error if $self->db->error;
}

sub dist_from_file {
  my ($self, $filename) = @_;

  my $dir = $self->path->subdir('dist');
  $dir->mkpath;

  my $dist_file = Path::Class::file($filename)->basename;
  require XPAN::Dist;
  my $dist = $self->dist->new(
    %{ $self->analyzer->analyze($filename) },
    file => $dist_file,
  );

  File::Copy::copy(
    $filename,
    $dir->file($dist_file),
  );

  return $dist;
}

sub dists_by_name_iterator {
  my $self = shift;
  my $iter = $self->dist->manager->get_objects_iterator(
    sort_by => [ qw(name version) ],
  );
  my $last = [ '' ];
  return sub {
    DIST: {
      my $item = $iter->next;
      unless ($item) {
        if ($last->[0]) {
          my $return = $last;
          $last = [ '' ];
          return @$return;
        }
        return;
      }
      unless ($last->[0] eq $item->name) {
        my $return = $last;
        $last = [ $item->name => [ $item ] ];
        # special case for the first time through
        if ($return->[0]) {
          return @$return;
        } else {
          redo DIST;
        }
      }
      push @{ $last->[1] }, $item;
      redo DIST;
    }
  };
}

sub find_pinset {
  my ($self, $arg) = @_;
  return $self->pinset->new(
    ($arg =~ /^\d+$/
      ? (id => $arg)
      : (name => $arg)
    ),
  )->load;
}

sub find_dist {
  my ($self, $arg) = @_;
  
  if ($arg =~ /::/) {
    my ($name, $version) = split /\s+/, $arg;
    my $modules = $self->module->manager->get_objects(
      query => [
        name => $name,
        $version ? (version => $version) : (),
      ],
      db => $self->db,
      sort_by => 'version DESC',
    );

    unless (@$modules) {
      Carp::confess "can't find_dist, no matching modules: $arg";
    }

    return $modules->[0]->dist;
  }

  my $dinfo = CPAN::DistnameInfo->new("$arg.tar.gz");

  unless ($dinfo) {
    Carp::confess "can't parse argument as module or dist name: $arg";
  }

  my $dists = $self->dist->manager->get_objects(
    query => [
      name => $dinfo->dist,
      $dinfo->version ? (version => $dinfo->version) : (),
    ],
    db => $self->db,
    sort_by => 'version DESC',
  );

  unless (@$dists) {
    Carp::confess "can't find_dist, no matching dists: $arg";
  }

  return $dists->[0];
}
      
1;
