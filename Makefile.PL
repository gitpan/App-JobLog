
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "log what you do",
  "AUTHOR" => "David F. Houghton <dfhoughton\@gmail.com>",
  "BUILD_REQUIRES" => {
    "File::Spec" => 0,
    "File::Temp" => 0,
    "String::Random" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-JobLog",
  "EXE_FILES" => [
    "bin/job",
    "bin/job"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::JobLog",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => 0,
    "Carp" => 0,
    "Class::Autouse" => 0,
    "Config::Tiny" => 0,
    "DateTime" => "0.66",
    "DateTime::TimeZone" => "1.30",
    "Exporter" => 0,
    "File::HomeDir" => 0,
    "File::ReadBackwards" => 0,
    "FileHandle" => 0,
    "IO::All" => 0,
    "Modern::Perl" => 0,
    "Module::Build" => "0.3601",
    "Term::ReadKey" => "2.30",
    "Text::Wrap" => 0,
    "Text::WrapI18N" => 0,
    "autouse" => 0,
    "base" => 0,
    "constant" => 0,
    "overload" => 0
  },
  "VERSION" => "1.020",
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



