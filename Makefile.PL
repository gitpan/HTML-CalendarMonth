# Check for non-standard modules used by this module.
use ExtUtils::MakeMaker;

$DISTNAME = "HTML-CalendarMonth";
$NAME = "HTML::CalendarMonth";

$| = 1;

print "Checking for DateTime, Date::Calc or Date::Manip ... ";
unless (eval "require DateTime"  ||
        eval "require Date::Calc" ||
        eval "require Date::Manip") {
  print " failed\n";
  print <<EOT;
Could not locate DateTime, Date::Calc, or Date::Manip (don't worry).

The presence of one of these modules is only required if you want to
use week-of-year numbering, or if you plan on manipulating dates that
exceed the ability of localtime() (Prior to Jan 1, 1970 or after 2038
on 32-bit systems).

You can obtain any of these modules from CPAN:

    http://search.cpan.org/search?dist=Date-Calc
    http://search.cpan.org/search?dist=DateTime
    http://search.cpan.org/search?dist=DateManip

EOT
  sleep(2);  # Don't hurry too much
}
else {
  ++$found_date_mods;
}
print " ok\n" if $found_date_mods;

# Time to make a makefile

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME     => $DISTNAME,
  NAME         => $NAME,
  VERSION_FROM => 'lib/HTML/CalendarMonth.pm',
  PREREQ_PM    => {
    HTML::ElementTable => 1.18,
    DateTime::Locale   => 0.45,
    Class::Accessor    => 0,
    File::Spec         => 0,
    Time::Local        => 0,
  },
);
