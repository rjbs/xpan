use strict;
use warnings;

package XPAN::Injector::CPAN;

use Moose;
with qw(XPAN::Helper XPAN::Injector);

use CPAN::SQLite;
use LWP::Simple ();
use File::Temp ();
use Parse::BACKPAN::Packages;

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
    $cpan->index unless (
      $exists and
      # trust the CPAN::SQLite index for at least 10 minutes
      $dir->file('cpandb.sql')->stat->mtime >= (time - 60 * 10)
    );
    return $cpan;
  },
);

has backpan => (
  is => 'ro',
  lazy => 1,
  default => sub { Parse::BACKPAN::Packages->new },
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

sub dist_url {
  my ($self, $url) = @_;
  $url = $self->_validate($url);
  if ($url->type eq 'dist') {
    return $url if $url->version;
    $self->cpan->query(
      mode => 'dist',
      name => $url->name,
    );
    my $result = $self->cpan->{results}
      or Carp::croak "no dist found for $url";
    $url->version($result->{dist_vers});
    return $url;
  }

  if ($url->type eq 'id') {
    my $info = CPAN::DistnameInfo->new($url->full_path);
    unless ($info->dist) {
      Carp::croak "id url '$url' does not refer to a dist";
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
    my $result = $self->cpan->{results} or
      Carp::croak "could not find package on cpan: $url";
    if ($url->version and $url->version ne $result->{mod_vers}) {
      # we can't fall back to backpan for this (yet); Parse::BACKPAN::Packages
      # does not have module-specific version to dist information, which makes
      # sense
      Carp::croak "version from $url does not match cpan ($result->{mod_vers})";
    }
    my $info = CPAN::DistnameInfo->new($result->{dist_file});
    return URI->new(sprintf(
      'cpan://dist/%s/%s',
      $info->dist,
      $info->version,
    ));
  }

  Carp::croak "unknown CPAN url: $url";
}

sub id_url {
  my ($self, $url) = @_;
  $url = $self->_validate($url);
  return $url if $url->type eq 'id';

  $url = $self->dist_url($url);
  $self->cpan->query(
    mode => 'dist',
    name => $url->name,
  );
  my $result = $self->cpan->{results};
  unless ($result and %$result) {
    $self->throw_result(
      'Error',
      message => 'does not exist on cpan',
      url => $url,
    );
  }
  if ($url->version and $url->version ne ($result->{dist_vers} || -1)) {
    $self->throw_result(
      'Error',
      message => 'wrong version on cpan',
      url => $url,
    ) unless $self->config->get('backpan_mirror');
    my ($dist) = grep { $_->version eq $url->version }
      $self->backpan->distributions($url->name) or
      $self->throw_result(
        'Error',
        message => "does not exist on cpan or backpan",
        url => $url,
      );
    $result = { cpanid => $dist->cpanid, dist_file => $dist->filename };
  }
  return URI->new(sprintf(
    'cpan://id/%s/%s', $result->{cpanid}, $result->{dist_file},
  ));
}

sub normalize {
  my ($self, $url) = @_;
  return $self->id_url($url);
}

before prepare => sub {
  my ($self, $url) = @_;
  my $dist_url = $self->dist_url($url);
  if (my $dist = $self->archiver->find_dist(
    [ $dist_url->name, $dist_url->version ]
  )) {
    $self->throw_result('Success::Already', dist => $dist);
  }
};

sub url_to_file {
  my ($self, $url) = @_;
  $url = $self->id_url($url);
  my $tmp = File::Temp::tempdir(CLEANUP => 1);
  my $file = "$tmp/" . $url->file_path->basename;
  return $self->_mirror_from(
    [ 
      map { 
        URI->new_abs(
          $url->full_path_url,
          $_,
        );
      } 
      grep { defined } map {
        $self->config->get($_)
      } qw(cpan_mirror backpan_mirror)
    ],
    $file,
  );
}

sub url_to_authority {
  my ($self, $url) = @_;
  return 'cpan:' . $url->cpanid;
}

sub _mirror_from {
  my ($self, $urls, $file) = @_;
  $urls = [ $urls ] unless ref $urls eq 'ARRAY';
  for my $url (@$urls) {
    $self->log->debug("mirroring $url -> $file");
    my $rc = LWP::Simple::mirror($url, $file);
    unless (HTTP::Status::is_success($rc)) {
      $self->log->warning("could not mirror $url -> $file: got $rc");
      next;
    }
    return $file;
  }
  Carp::croak "all mirrors failed: @$urls";
}

1;
