use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Config;

my $output = WriteMakefile(
    NAME           => 'APNIC::RPKI::TALUpdater',
    AUTHOR         => 'Software <software@apnic.net>',
    LICENSE        => 'bsd',
    VERSION_FROM   => 'lib/APNIC/RPKI/TALUpdater.pm',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/APNIC-net/rpki-signed-tal-demo'
        }
    },
    EXE_FILES      => [ qw(bin/rpki-tal-updater) ],
    PREREQ_PM      => { 'Test::More'             => 0,
                        'LWP::UserAgent'         => 0,
                        'List::MoreUtils'        => 0 }
);

1;
