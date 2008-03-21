use inc::Module::Install;

name     'XPAN';
all_from 'lib/XPAN.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';
build_requires 'Module::Faker' => 0.005; # order

requires 'App::Cmd'                  => 0;
requires 'CPAN::SQLite'              => 0;
requires 'File::pushd'               => 0;
requires 'Moose'                     => 0;
requires 'Rose::DB::Object'          => 0;
requires 'WWW::Mechanize'            => 0;
requires 'Module::Pluggable::Object' => 0;

install_script 'script/xpan';

WriteAll;

