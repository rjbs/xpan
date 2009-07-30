package XPAN::Role::CPANMirror::Basic;
use Moose::Role;

requires 'distfile';         # ->distfile("RJBS/Sub-Exporter-0.987.tar.gz")
requires 'package_index';    # handle to the 02packages.details.txt
requires 'author_checksums'; # ->author_checksums('RJBS');

no Moose::Role;
1;
