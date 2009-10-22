use 5.8.2;
use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME            => 'DAIA',
    DISTNAME        => 'DAIA',
    VERSION_FROM    => 'lib/DAIA.pm',
    ABSTRACT_FROM   => 'lib/DAIA.pm',
    AUTHOR          => 'Jakob Voss <jakob.voss@gbv.de>',
    PREREQ_PM       => {
        'Data::Validate::URI' => '0.05',
        'DateTime::Duration' => '0',
        'DateTime::Format::Duration' => '1.03',
        'DateTime::Format::ISO8601' => '0.06',
        'JSON' => '2.15',
        'CGI' => '3.0',
        'URI' => '1.35',
        'XML::Simple' => '2.14',
        'IO::File' => 0,
    },
    depend          => {
        Makefile => '$(VERSION_FROM)'
    },
);
