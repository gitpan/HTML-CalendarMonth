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

  $tcount = @cals * (@tmethods + 1) + 1;

}

# Carry on

use Test::More tests => $tcount;

BEGIN { use_ok 'HTML::CalendarMonth' }

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
      local(*DUMP);
      open(DUMP, ">$DEBUG") or die "Could not dump to $DEBUG: $!\n";
      print DUMP "<html><body><table><tr><td>Broken</td><td>Test Data</td></tr><tr><td>\n";
      print DUMP $c->as_HTML, "\n</td><td>\n";
      print DUMP $cal->[2], "\n</td></tr></table></body></html>\n";
      close(DUMP);
      print STDERR "\nDumped tables to $DEBUG. Aborting test.\n";
      exit;
    }
    $day1 = $days[$cal->[3] - 1];
    ++$tc;
  }
print STDERR "\n";
}
