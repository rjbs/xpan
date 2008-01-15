use strict;
use warnings;

package XPAN::Indexer;

use base qw(Rose::Object);
use Rose::Object::MakeMethods::WeakRef (
  'scalar --get_set_init' => [ 'archiver' ],
);

use Carp ();
use CPAN::Checksums ();

sub init_archiver { Carp::croak "'archiver' is required" }

sub choose_distribution_version { Carp::croak "unimplemented" }

sub name { Carp::croak "unimplemented" }

sub path {
  my $self = shift;
  return $self->archiver->path->subdir('index')->subdir($self->name);
}

sub build {
  my ($self) = @_;

  $self->clear_index;
  $self->build_index_files;
  $self->add_all_distributions;
  CPAN::Checksums::updatedir($self->author_dir('LOCAL'));
}

sub clear_index {
  my ($self) = @_;
  $self->path->rmtree;
}

sub build_index_files { }

sub add_all_distributions {
  my ($self) = @_;
  my $iter = $self->archiver->dists_by_name_iterator;
  while (my ($name, $dists) = $iter->()) {
#    use Data::Dumper;
#    local $Data::Dumper::MaxDepth = 2;
#    warn Dumper($name, $dists);
    my $dist = $self->choose_distribution_version(@$dists);
    $self->add_distribution($dist);
  }
}

sub add_distribution {
  my ($self, $dist) = @_;
  $self->add_to_packages($dist);
  $self->add_distribution_link($dist);
}

sub index_fh {
  my ($self, $filename) = @_;
  $self->{index_fh}{$filename} ||= do {
    $self->path->subdir('modules')->mkpath;
    $filename = $self->path->subdir('modules')->file($filename);
    open my $fh, ">", $filename or die "Can't open $filename: $!";
    $fh;
  };
}

sub add_to_packages {
  my ($self, $dist) = @_;
  my $exists = -e $self->path
    ->subdir('modules')->file('02packages.details.txt');
  my $fh = $self->index_fh('02packages.details.txt');
  unless ($exists) {
    print $fh <<END;
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   ME
Line-Count:   ???
Last-Updated: ???

END
  }
  for my $module ($dist->modules) {
    print $fh sprintf "%-30s %8s  %s\n",
      $module->name,
      (defined $module->version ? $module->version : 'undef'),
        $self->author_dir('LOCAL')->relative(
          $self->path->subdir('authors')->subdir('id')
        )->file($dist->file),
    ;
  }
}

sub author_dir {
  my ($self, $id) = @_;
  my $path = $self->path->subdir('authors')->subdir('id');
  $path = $path->subdir(substr($id, 0, 1));
  $path = $path->subdir(substr($id, 0, 2));
  return $path->subdir($id);
}

sub add_distribution_link {
  my ($self, $dist) = @_;

  my $author_dir = $self->author_dir('LOCAL');
  $author_dir->mkpath;
  my $file = $author_dir->file($dist->file);

  my $target =
    $self->archiver->path->subdir('dist')->file($dist->file)->absolute;
  warn "linking $file -> $target\n";
  symlink(
    $target,
    $file,
  ) or die "Can't symlink $file -> $target: $!";
}

1;
