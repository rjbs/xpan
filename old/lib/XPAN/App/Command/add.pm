use strict;
use warnings;

package XPAN::App::Command::add;

use base qw(App::Cmd::Command);

sub opt_spec {
  return (
    [ 'pinset|p=s' => 'pinset to add to' ],
  );
}

my $packages;
my $p;
sub _resolve {
  my ($name, $version) = @_;
  require LWP::Simple;
  $packages ||=
    LWP::Simple::get("http://www.cpan.org/modules/02packages.details.txt.gz");
  require Parse::CPAN::Packages;
  $p ||= Parse::CPAN::Packages->new($packages);
  my (@modules) = $p->package($name);
  unless (@modules) {
    Carp::confess("could not find package for $name on CPAN");
  }
  if (@modules > 1) {
    die "$name: @modules";
  }
  my $module = $modules[0];
  unless (Sort::Versions::versioncmp($module->version, $version) >= 0) {
    Carp::confess("could not satisfy dependency ($name $version) from CPAN");
  }
  return $module->distribution->distvname;
}

sub run {
  my ($self, $opt, $args) = @_;

  my $arch = $self->app->archiver;
  my @dists;
  my @queue = @$args;
  while (@queue) {
    my $arg = shift @queue;
    my $dist = eval { $arch->find_dist($arg) };
    unless ($dist) {
      $arch->inject(-BackPAN => [ $arg ]);
      $dist = $arch->find_dist($arg);
    }
    my @unmatched = grep { ! $_->matches($arch) } $dist->dependencies;
    for my $dep (@unmatched) {
      my $new = _resolve($dep->name, $dep->version);
      next if $new =~ /^perl-\d/;
      warn "adding $new for " . $dep->as_string;
      push @queue, $new;
    }
    push @dists, $dist;
  }

  if ($opt->{pinset}) {
    my $pinset = $arch->find_pinset($opt->{pinset});

    my $change = $pinset->change(dists => \@dists);

    if (my $conflicts = $change->conflicts) {
      die "can't add because of conflicts:\n" . $change->table($conflicts);
    }

    my $table = $change->table($change->changes);
    $change->apply;
    $arch->indexer(-Pinset, pinset => $pinset->name)->build;
    print $table;
  }
}

1;
