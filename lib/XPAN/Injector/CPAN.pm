use strict;
use warnings;

package XPAN::Injector::CPAN;

use Moose;
with qw(XPAN::Object::HasArchiver XPAN::Injector);

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

sub _qualify {
  my ($self, $url) = @_;
  blessed($url) or $_[1] = $url = URI->new($url);
  unless ($url->cpanid && $url->version
    && $url->path =~ /\Q@{[ $url->extension ]}\E$/) {
    $self->cpan->query(
      mode => 'dist',
      name => $url->dist,
    );
    my $result = $self->cpan->{results};
    unless ($result) {
      Carp::croak "no cpanid given in $url and no dist found on cpan";
    }
    if ($url->version and $url->version ne $result->{dist_vers}) {
      Carp::croak "version from $url does not match cpan ($result->{dist_vers})";
    }
    $url->path('/' . $result->{dist_file});
    $url->authority($result->{cpanid});
  }
  return $url;
}

before prepare => sub {
  my ($self, $url, $opt) = @_;
  $self->_qualify($url);
};

sub url_to_file {
  my ($self, $url) = @_;
  $self->_qualify($url);
  my $tmp = File::Temp::tempdir(CLEANUP => 1);
  my $file = "$tmp/" . $url->info->filename;
  return $url->mirror($file);
}

sub url_to_authority {
  my ($self, $url) = @_;
  return 'cpan:' . $url->cpanid;
}

package URI::cpan;

use MooseX::InsideOut;
extends 'URI::_foreign';

use CPAN::DistnameInfo;

has _info => (
  is => 'ro',
  lazy => 1,
  isa => 'HashRef',
  default => sub { {} },
);

sub info {
  my ($self) = @_;
  my $key = "$self";
  return $self->_info->{$key} if $self->_info->{$key};

  # recalculate if the url stringification changes
  my (undef, $name) = split m{/}, $self->path, 2;
  if ($self->authority) {
    my $cpanid = $self->authority;
    $name = sprintf(
      "authors/id/%s/%s/%s/%s",
      substr($cpanid, 0, 1),
      substr($cpanid, 0, 2),
      $cpanid,
      $name,
    );
  }
  $name .= '.tar.gz' unless $name =~ /(\.tar\.gz|\.zip)$/;
  my $info = CPAN::DistnameInfo->new($name);
  %{ $self->_info } = ($key => $info);
  #use Data::Dumper; warn Dumper($info);
  return $info;
}

sub dist      { shift->info->dist      }
sub version   { shift->info->version   }
sub distvname { shift->info->distvname }
sub cpanid    { shift->info->cpanid    }
sub extension { shift->info->extension }

sub mirror {
  my ($self, $file, $mirror) = @_;
  $mirror ||= 'http://www.cpan.org/';
  my $url = $mirror . $self->info->pathname;
  my $rc = LWP::Simple::mirror($url, $file);
  unless (HTTP::Status::is_success($rc)) {
    Carp::croak "could not mirror $url -> $file: got $rc";
  }
  return $file;
}

1;
