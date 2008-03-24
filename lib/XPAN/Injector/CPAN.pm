use strict;
use warnings;

package XPAN::Injector::CPAN;

use Moose;
with qw(XPAN::Helper XPAN::Injector);

use CPAN::SQLite;
use LWP::Simple ();
use File::Temp ();

has cpan => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    #my $dir = $self->archiver->tmp->subdir('cpan');
    # only for dev; faster
    my $dir = Path::Class::dir("$ENV{HOME}/tmp/cpan");
    my $exists = -e $dir->file('cpandb.sql');
    $dir->mkpath;
    my $cpan = CPAN::SQLite->new(
      CPAN   => $dir,
      db_dir => $dir,
    );
    $cpan->index(setup => 1) unless $exists;
    return $cpan;
  },
);

sub scheme { 'cpan' }

sub _validate {
  my ($self, $url) = @_;
  blessed($url) or $url = URI->new($url);
  unless ($url->isa('URI::cpan')) {
    Carp::croak "unknown CPAN URL scheme: $url (not isa URI::cpan)";
  }
  return $url;
}

sub _dist {
  my ($self, $url) = @_;
  $url = $self->_validate($url);
  if ($url->type eq 'dist') {
    return $url if $url->version;
    $self->cpan->query(
      mode => 'dist',
      name => $url->name,
    );
    $url->version($self->cpan->{results}->{dist_vers});
    return $url;
  }

  if ($url->type eq 'author') {
    my $info = CPAN::DistnameInfo->new($url->full_path);
    unless ($info->dist) {
      Carp::croak "author url '$url' does not refer to a dist";
    }
    return URI->new(sprintf(
      'cpan://dist/%s/%s',
      $info->dist,
      $info->version,
    ));
  }

  if ($url->type eq 'package') {
    $self->cpan->query(
      mode => 'module',
      name => $url->name,
    );
    my $result = $self->cpan->{results};
    if ($url->version and $url->version ne $result->{mod_vers}) {
      Carp::croak "version from $url does not match cpan ($result->{mod_vers})";
    }
    return URI->new(sprintf(
      'cpan://dist/%s/%s',
      $result->{dist_name},
      $result->{dist_vers},
    ));
  }

  Carp::croak "unknown CPAN url: $url";
}

sub _author {
  my ($self, $url) = @_;
  $url = $self->_validate($url);
  return $url if $url->type eq 'author';

  $url = $self->_dist($url);
  $self->cpan->query(
    mode => 'dist',
    name => $url->name,
  );
  my $result = $self->cpan->{results};
  if ($url->version and $url->version ne $result->{dist_vers}) {
    Carp::croak "version from $url does not match cpan ($result->{dist_vers})";
  }
  return URI->new(sprintf(
    'cpan://%s/%s', $result->{cpanid}, $result->{dist_file},
  ));
}

before prepare => sub {
  my ($self, $url, $opt) = @_;
  $_[1] = $self->_author($url);
};

sub url_to_file {
  my ($self, $url) = @_;
  $url = $self->_author($url);
  my $tmp = File::Temp::tempdir(CLEANUP => 1);
  my $file = "$tmp/" . $url->filename;
  return $self->_mirror_from(
    URI->new_abs(
      $url->full_path,
      $self->config->get('cpan_mirror'),
    ),
    $file,
  );
}

sub url_to_authority {
  my ($self, $url) = @_;
  return 'cpan:' . $url->cpanid;
}

sub _mirror_from {
  my ($self, $url, $file) = @_;
  my $rc = LWP::Simple::mirror($url, $file);
  unless (HTTP::Status::is_success($rc)) {
    Carp::croak "could not mirror $url -> $file: got $rc";
  }
  return $file;
}

1;
