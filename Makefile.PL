
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Document Availability Information API",
  "AUTHOR" => "Jakob Voss",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "File::Spec" => 0,
    "Test::More" => 0,
    "URI" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DAIA",
  "EXE_FILES" => [
    "bin/daia",
    "bin/daia"
  ],
  "LICENSE" => "perl",
  "NAME" => "DAIA",
  "PREREQ_PM" => {
    "CGI" => 0,
    "Carp" => 0,
    "Carp::Clan" => 0,
    "Data::Dumper" => 0,
    "Data::Validate::URI" => 0,
    "DateTime" => 0,
    "DateTime::Duration" => 0,
    "DateTime::Format::Duration" => 0,
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "IO::Scalar" => 0,
    "JSON" => 0,
    "LWP::Simple" => 0,
    "POSIX" => 0,
    "Pod::Usage" => 0,
    "Scalar::Util" => 0,
    "UNIVERSAL" => 0,
    "XML::Simple" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.41",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



