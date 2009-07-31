package XPAN::Role::CPANMirror::Basic;
use Moose::Role;

requires 'author_file';      # ->distfile("RJBS/Sub-Exporter-0.987.tar.gz")
requires 'package_index';    # handle to the 02packages.details.txt
requires 'package_index_gz'; # handle to the 02packages.details.txt.gz
requires 'author_checksums'; # ->author_checksums('RJBS');

no Moose::Role;
1;
