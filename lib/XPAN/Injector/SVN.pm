use strict;
use warnings;

package XPAN::Injector::SVN;

use Moose;
with qw(XPAN::Helper XPAN::Injector);
use File::Temp ();
use File::pushd;

sub scheme { 'svn' }

sub url_to_file {
  my ($self, $url) = @_;

  my $export_dir = File::Temp::tempdir(CLEANUP => 1);

  system("svn export --force $url $export_dir >/dev/null")
    and die "svn export failed: $?";

  my $dist;
  {
    my $dir = pushd($export_dir);
    my $builder = 
      -e 'Build.PL'    ? '_build' :
      -e 'Makefile.PL' ? '_make' :
      die "Can't find either Build.PL or Makefile.PL in $export_dir from $url";

    my $dist_dir = $self->$builder;
    my ($suffix) = grep { -e "$dist_dir$_" } qw(.tar.gz .tgz .zip)
      or die "Can't find dist in $export_dir from $url ($dist_dir)";
    $dist = "$dist_dir$suffix";
  }

  return Path::Class::dir($export_dir)->file($dist)->stringify;
}

sub _run {
  my $self = shift;
  system("$^X @_ >/dev/null") && die "Error running @_: nonzero exit $?";
}

sub _build {
  my ($self) = @_;
  $self->_run('Build.PL');
  my $out = `./Build dist`;
  my ($dist) = grep { $_ ne 'META.yml' }
    $out =~ m{^Creating (\S+)$}m;
  return $dist;
}

sub _make {
  my ($self) = @_;
  $self->_run('Makefile.PL');
  my $out = `make dist`;
  my ($dist) = $out =~ m{^mkdir ([^\n/]+)$}m;
  return $dist;
}

1;
