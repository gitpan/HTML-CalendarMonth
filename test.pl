# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

# Establish number of tests (ugh)
BEGIN {
  # Required test dates
  open(D, "test.dat");
  $rds = <D>;
  foreach (split(' ', $rds)) {
    ++$dates{$_};
  }

  # Today's date
  ($month, $year) = (localtime(time))[4,5];
  ++$month;
  $year += 1900;

  # Flag tests for a year
  foreach $y ($year .. $year + 1) {
    foreach $m (1 .. 12) {
      ++$dates{sprintf("%d/%02d", $y, $m)};
    }
  }

  # Yank test cases
  while (<D>) {
    chomp;
    ($d, $wb) = split(' ', $_);
    ($y, $m) = split('/', $d);
    $cal = <D>;
    push(@cals, [$y, $m, $cal, $wb]) if $dates{"$y/$m"};
  }

  close(D);

  # Figure out calendar generation options
  @modules  = qw(Time::Local Date::Calc DateTime Date::Manip);
  @tmethods = ();

  foreach $module (@modules) {
    if (eval "require $module") {
      print "Found $module, adding to tests.\n";
      push(@tmethods, $module);
    }
  }

  if ($CAL = `which cal`) {
    chomp $CAL;
    print "Found cal command at '$CAL', adding to tests.\n";
    push(@tmethods, 'cal');
  }

  # packages set up for woy handlign
  foreach (qw(DateTime Date::Calc Date::Manip)) {
    ++$woy_enabled{$_};
  }
  push(@twy_methods, $_) foreach grep($woy_enabled{$_}, @tmethods);

  $tcount = @cals * (@tmethods + 1) + (@twy_methods * 2) + 4;

}

# Carry on

use Test::More tests => $tcount;

BEGIN { use_ok 'HTML::CalendarMonth' }
BEGIN { use_ok 'HTML::CalendarMonth::DateTool' }

######################### End of black magic.

my $DEBUG = 0;

# Compare each case using each method
@days = qw( Sun Mon Tue Wed Thr Fri Sat );
foreach $tmethod ('', @tmethods) {
  my $method = $tmethod || 'auto-select';
  my $tc = 1;
  foreach $cal (@cals) {
    $c = HTML::CalendarMonth->new(
           year       => $cal->[0],
           month      => $cal->[1],
           week_begin => $cal->[3],
           datetool   => $tmethod,
    );
    ok($c->as_HTML eq $cal->[2],
       sprintf("%3d (%d/%-02d %s 1st day) using %s",
               $tc, $cal->[0], $cal->[1], $day1, $method));
    if ($DEBUG && $c->as_HTML ne $cal->[2]) {
      debug_dump('Broken', $c->as_HTML, 'Test Data', $cal->[2]);
    }
    $day1 = $days[$cal->[3] - 1];
    ++$tc;
  }
print STDERR "\n";
}

my(%woy_data, $basque);
eval join('', <DATA>);
die "Oops on eval: $@\n" if $@;

my $year = 2000;
foreach my $datetool (@twy_methods) {
  foreach my $month (qw(01 12)) {
    my $tc = $woy_data{"$year/$month"};
    my $cal = HTML::CalendarMonth->new(
      year       => $year,
      month      => $month,
      head_week  => 1,
      datetool   => $datetool,
    );
    my $ct = $cal->as_HTML;
    chomp $ct;
    ok($ct eq $tc, "($year/$month week of year) using $datetool");
    if ($DEBUG && $ct ne $tc) {
      debug_dump('Broken', $ct, 'Test Data', $tc);
    }
  }
}
print "\n";

# i8n (use basque as example)
my @stoof = HTML::CalendarMonth::Locale->locales;
ok(@stoof > 20, 'i8n: locale ids retreived');
($year, $month) = (2000, 12);
my $b = HTML::CalendarMonth->new(
  year       => $year,
  month      => $month,
  head_week  => 1,
  locale     => 'eu',
);
my $bstr = $b->as_HTML;
chomp($bstr);
ok($bstr eq $basque, "i8n: ($year/$month : Basque) using auto-detect");
if ($DEBUG && $bstr ne $basque) {
  debug_dump('Broken', $bstr, 'Test Data', $basque);
}

exit;

sub debug_dump {
  my($l1, $str1, $l2, $str2) = @_;
  local(*DUMP);
  open(DUMP, ">$DEBUG") or die "Could not dump to $DEBUG: $!\n";
  print DUMP "<html><body><table><tr><td>$l1</td><td>$l2</td></tr><tr><td>\n";
  print DUMP "$str1\n</td><td>\n";
  print DUMP "$str2\n</td></tr></table></body></html>\n";
  close(DUMP);
  print STDERR "\nDumped tables to $DEBUG. Aborting test.\n";
  exit;
}

__DATA__
$woy_data{'2000/01'} = '<table bgcolor="white" border=1 cellpadding=0 cellspacing=0><tr align="center"><td align="left" colspan=6>January</td><td align="center" colspan=2>2000</td></tr><tr align="center"><td align="center">Sun</td><td align="center">Mon</td><td align="center">Tue</td><td align="center">Wed</td><td align="center">Thu</td><td align="center">Fri</td><td align="center">Sat</td><td align="center">&nbsp; </td></tr><tr align="center"><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td><td align="center">52</td></tr><tr align="center"><td align="center">2</td><td align="center">3</td><td align="center">4</td><td align="center">5</td><td align="center">6</td><td align="center">7</td><td align="center">8</td><td align="center">1</td></tr><tr align="center"><td align="center">9</td><td align="center">10</td><td align="center">11</td><td align="center">12</td><td align="center">13</td><td align="center">14</td><td align="center">15</td><td align="center">2</td></tr><tr align="center"><td align="center">16</td><td align="center">17</td><td align="center">18</td><td align="center">19</td><td align="center">20</td><td align="center">21</td><td align="center">22</td><td align="center">3</td></tr><tr align="center"><td align="center">23</td><td align="center">24</td><td align="center">25</td><td align="center">26</td><td align="center">27</td><td align="center">28</td><td align="center">29</td><td align="center">4</td></tr><tr align="center"><td align="center">30</td><td align="center">31</td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">5</td></tr></table>';
$woy_data{'2000/12'} = '<table bgcolor="white" border=1 cellpadding=0 cellspacing=0><tr align="center"><td align="left" colspan=6>December</td><td align="center" colspan=2>2000</td></tr><tr align="center"><td align="center">Sun</td><td align="center">Mon</td><td align="center">Tue</td><td align="center">Wed</td><td align="center">Thu</td><td align="center">Fri</td><td align="center">Sat</td><td align="center">&nbsp; </td></tr><tr align="center"><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td><td align="center">2</td><td align="center">48</td></tr><tr align="center"><td align="center">3</td><td align="center">4</td><td align="center">5</td><td align="center">6</td><td align="center">7</td><td align="center">8</td><td align="center">9</td><td align="center">49</td></tr><tr align="center"><td align="center">10</td><td align="center">11</td><td align="center">12</td><td align="center">13</td><td align="center">14</td><td align="center">15</td><td align="center">16</td><td align="center">50</td></tr><tr align="center"><td align="center">17</td><td align="center">18</td><td align="center">19</td><td align="center">20</td><td align="center">21</td><td align="center">22</td><td align="center">23</td><td align="center">51</td></tr><tr align="center"><td align="center">24</td><td align="center">25</td><td align="center">26</td><td align="center">27</td><td align="center">28</td><td align="center">29</td><td align="center">30</td><td align="center">52</td></tr><tr align="center"><td align="center">31</td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td></tr></table>';
$basque = '<table bgcolor="white" border=1 cellpadding=0 cellspacing=0><tr align="center"><td align="left" colspan=6>abendua</td><td align="center" colspan=2>2000</td></tr><tr align="center"><td align="center">ig</td><td align="center">al</td><td align="center">as</td><td align="center">az</td><td align="center">og</td><td align="center">or</td><td align="center">lr</td><td align="center">&nbsp; </td></tr><tr align="center"><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td><td align="center">2</td><td align="center">48</td></tr><tr align="center"><td align="center">3</td><td align="center">4</td><td align="center">5</td><td align="center">6</td><td align="center">7</td><td align="center">8</td><td align="center">9</td><td align="center">49</td></tr><tr align="center"><td align="center">10</td><td align="center">11</td><td align="center">12</td><td align="center">13</td><td align="center">14</td><td align="center">15</td><td align="center">16</td><td align="center">50</td></tr><tr align="center"><td align="center">17</td><td align="center">18</td><td align="center">19</td><td align="center">20</td><td align="center">21</td><td align="center">22</td><td align="center">23</td><td align="center">51</td></tr><tr align="center"><td align="center">24</td><td align="center">25</td><td align="center">26</td><td align="center">27</td><td align="center">28</td><td align="center">29</td><td align="center">30</td><td align="center">52</td></tr><tr align="center"><td align="center">31</td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td></tr></table>';
