use strict;
use warnings;

package XPAN::Indexer;

use base qw(XPAN::Object::HasArchiver);

use Carp ();
use CPAN::Checksums ();
use HTTP::Date ();
use IO::Zlib;

my %FILE = (
  '02packages' => '02packages.details.txt',
);

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

sub each_distribution {
  my ($self, $code) = @_;
  my $iter = $self->archiver->dists_by_name_iterator;
  while (my ($name, $dists) = $iter->()) {
    my $dist = $self->choose_distribution_version($name => @$dists);
    local $_ = $dist;
    $code->();
  }
}

sub all_distributions {
  my ($self) = @_;
  my @dists;
  $self->each_distribution(sub { push @dists, $_ });
  return @dists;
}

sub add_all_distributions {
  my ($self) = @_;
  $self->{packages} = [];
  $self->each_distribution(sub {
    $self->add_distribution($_);
  });
  $self->write_02packages;
}

sub add_distribution {
  my ($self, $dist) = @_;
  $self->add_to_packages($dist);
  $self->add_distribution_link($dist);
}

sub index_fh {
  my ($self, $filename) = @_;
  $filename = $FILE{$filename};
  $self->{index_fh}{$filename} ||= do {
    $self->path->subdir('modules')->mkpath;
    $self->path->subdir('modules')->file($filename)->openw;
  };
}

sub gzip_index_file {
  my ($self, $filename) = @_;
  $filename = $FILE{$filename};
  my $file = $self->path->subdir('modules')->file($filename);
  my $fh = $file->openr;
  my $gz = IO::Zlib->new("$file.gz", "w");
  while (<$fh>) { print { $gz } $_ }
}

sub add_to_packages {
  my ($self, $dist) = @_;
  push @{ $self->{packages} }, $dist;
}

sub write_02packages {
  my $self = shift;
  my $fh = $self->index_fh('02packages');
  print $fh sprintf <<END,
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   LOCAL
Line-Count:   %s
Last-Updated: %s

END
    scalar @{ $self->{packages} },
    HTTP::Date::time2str;

  for my $dist (@{ $self->{packages} }) {
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
  close $fh;
  $self->gzip_index_file('02packages');
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
