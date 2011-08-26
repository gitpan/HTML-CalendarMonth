
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Generate and manipulate HTML calendar months",
  "AUTHOR" => "Matthew P. Sisk <msisk\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "English" => 0,
    "Exporter" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "Test::More" => 0,
    "vars" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-CalendarMonth",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::CalendarMonth",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Accessor" => 0,
    "DateTime::Locale" => "0.45",
    "File::Which" => 0,
    "HTML::ElementTable" => "1.18",
    "Time::Local" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.26",
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



