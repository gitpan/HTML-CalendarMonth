# Check for non-standard modules used by this module.
use ExtUtils::MakeMaker;

$DISTNAME = "HTML-CalendarMonth";
$NAME = "HTML::CalendarMonth";

$| = 1;

print "Checking for Date::Calc or Date::Manip ... ";
eval {
    require Date::Calc;
};
if ($@) {
    eval {
        require Date::Manip;
    };
    if ($@) {
       print " failed\n";
       print <<EOT;
$@
Date::Calc or Date::Manip are only needed if you want to use week-of-year
numbering, or if you plan on manipulating dates that exceed the ability
of localtime() (Prior to Jan 1, 1970 or after 2038).
You can obtain either of these modules from CPAN:
    http://search.cpan.org/search?dist=Date-Calc
    http://search.cpan.org/search?dist=DateManip

EOT
       sleep(2);  # Don't hurry too much
    }
    else {
        ++$found_date_mods;
    }
}
else {
    ++$found_date_mods;
}
print " ok\n" if $found_date_mods;

# Time to make a makefile

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              DISTNAME     => $DISTNAME,
              NAME         => $NAME,
	      VERSION_FROM => 'lib/HTML/CalendarMonth.pm',
              PREREQ_PM    => {
			       HTML::ElementTable => 0,
			      },
	      dist         => {
			       COMPRESS => 'gzip -9f',
			       SUFFIX => 'gz',
			      },
	     );
