use inc::Module::Install;

name     'XPAN';
all_from 'lib/XPAN.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';

requires 'Moose' => 0;
requires 'Rose::DB::Object' => 0;
requires 'File::pushd' => 0;
requires 'WWW::Mechanize' => 0;
requires 'App::Cmd' => 0;

auto_install;

WriteAll;

