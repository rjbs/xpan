use inc::Module::Install;

name     'XPAN';
all_from 'lib/XPAN.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';

auto_install;

WriteAll;

