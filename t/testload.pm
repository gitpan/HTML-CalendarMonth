package testload;

use vars qw( @ISA @EXPORT $Dat_Dir );

use strict;
use Test::More;

my $DEBUG = 0;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( $Dat_Dir check_datetool case_count
              check_basic_with_datetool
              check_woy_with_datetool
            );

use File::Spec;

use HTML::CalendarMonth;
use HTML::CalendarMonth::DateTool;

my($base_dir, $vol, $dir);
BEGIN {
  my $pkg = __PACKAGE__;
  $pkg =~ s%::%/%g;
  $pkg .= '.pm';
  $pkg = File::Spec->canonpath($INC{$pkg});
  my $file;
  ($vol, $dir, $file) = File::Spec->splitpath($pkg);
  $base_dir = File::Spec->catpath($vol, $dir);
}
$Dat_Dir = $base_dir;

my($tcount, $rds, %dates, @tmethods, @twy_methods, @Cals);

# Required test dates
my $dat_file = File::Spec->catpath($vol, $dir, 'test.dat');
open(D, "<$dat_file") or die "Problem reading $dat_file: $!\n";
$rds = <D>;
foreach (split(' ', $rds)) {
  ++$dates{$_};
}

my %WOY_data;
eval join('', <DATA>);
die "Oops on eval: $@\n" if $@;

# Today's date
my($month, $year) = (localtime(time))[4,5];
++$month;
$year += 1900;

# Flag tests for a year
foreach my $y ($year .. $year + 1) {
  foreach my $m (1 .. 12) {
    ++$dates{sprintf("%d/%02d", $y, $m)};
  }
}

# Yank test cases
while (<D>) {
  chomp;
  my($d, $wb) = split(' ', $_);
  my($y, $m) = split('/', $d);
  my $cal = <D>;
  push(@Cals, [$y, $m, $cal, $wb]) if $dates{"$y/$m"};
}

close(D);

sub case_count { scalar @Cals }

sub check_datetool {
  my $datetool = shift;
  my $module = HTML::CalendarMonth::DateTool->toolmap($datetool);
  ok($module, "toolmap($datetool) : $module");
  require_ok($module);
}

sub check_basic_with_datetool {
  my $datetool = shift;
  my @days = qw( Sun Mon Tue Wed Thr Fri Sat );
  my $method = $datetool || 'auto-select';
  foreach my $cal (@Cals) {
    my $c = HTML::CalendarMonth->new(
      year       => $cal->[0],
      month      => $cal->[1],
      week_begin => $cal->[3],
      datetool   => $datetool,
    );
    my $day1 = $days[$cal->[3] - 1];
    cmp_ok($c->as_HTML, 'eq', $cal->[2],
       sprintf("(%d/%-02d %s 1st day) using %s",
               $cal->[0], $cal->[1], $day1, $method));
    if ($DEBUG && $c->as_HTML ne $cal->[2]) {
      debug_dump('Broken', $c->as_HTML, 'Test Data', $cal->[2]);
    }
  }
}

sub check_woy_with_datetool {
  my $datetool = shift;
  my $year = 2000;
  foreach my $month (qw(01 12)) {
    my $tc = $WOY_data{"$year/$month"};
    my $cal = HTML::CalendarMonth->new(
      year       => $year,
      month      => $month,
      head_week  => 1,
      datetool   => $datetool,
    );
    my $ct = $cal->as_HTML;
    chomp $ct;
    cmp_ok($ct, 'eq', $tc, "($year/$month week of year) using $datetool");
    if ($DEBUG && $ct ne $tc) {
      debug_dump('Broken', $ct, 'Test Data', $tc);
    }
  }
}

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
$WOY_data{'2000/01'} = '<table bgcolor="white" border=1 cellpadding=0 cellspacing=0><tr align="center"><td align="left" colspan=6>January</td><td align="center" colspan=2>2000</td></tr><tr align="center"><td align="center">Sun</td><td align="center">Mon</td><td align="center">Tue</td><td align="center">Wed</td><td align="center">Thu</td><td align="center">Fri</td><td align="center">Sat</td><td align="center">&nbsp; </td></tr><tr align="center"><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td><td align="center">52</td></tr><tr align="center"><td align="center">2</td><td align="center">3</td><td align="center">4</td><td align="center">5</td><td align="center">6</td><td align="center">7</td><td align="center">8</td><td align="center">1</td></tr><tr align="center"><td align="center">9</td><td align="center">10</td><td align="center">11</td><td align="center">12</td><td align="center">13</td><td align="center">14</td><td align="center">15</td><td align="center">2</td></tr><tr align="center"><td align="center">16</td><td align="center">17</td><td align="center">18</td><td align="center">19</td><td align="center">20</td><td align="center">21</td><td align="center">22</td><td align="center">3</td></tr><tr align="center"><td align="center">23</td><td align="center">24</td><td align="center">25</td><td align="center">26</td><td align="center">27</td><td align="center">28</td><td align="center">29</td><td align="center">4</td></tr><tr align="center"><td align="center">30</td><td align="center">31</td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">5</td></tr></table>';
$WOY_data{'2000/12'} = '<table bgcolor="white" border=1 cellpadding=0 cellspacing=0><tr align="center"><td align="left" colspan=6>December</td><td align="center" colspan=2>2000</td></tr><tr align="center"><td align="center">Sun</td><td align="center">Mon</td><td align="center">Tue</td><td align="center">Wed</td><td align="center">Thu</td><td align="center">Fri</td><td align="center">Sat</td><td align="center">&nbsp; </td></tr><tr align="center"><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td><td align="center">2</td><td align="center">48</td></tr><tr align="center"><td align="center">3</td><td align="center">4</td><td align="center">5</td><td align="center">6</td><td align="center">7</td><td align="center">8</td><td align="center">9</td><td align="center">49</td></tr><tr align="center"><td align="center">10</td><td align="center">11</td><td align="center">12</td><td align="center">13</td><td align="center">14</td><td align="center">15</td><td align="center">16</td><td align="center">50</td></tr><tr align="center"><td align="center">17</td><td align="center">18</td><td align="center">19</td><td align="center">20</td><td align="center">21</td><td align="center">22</td><td align="center">23</td><td align="center">51</td></tr><tr align="center"><td align="center">24</td><td align="center">25</td><td align="center">26</td><td align="center">27</td><td align="center">28</td><td align="center">29</td><td align="center">30</td><td align="center">52</td></tr><tr align="center"><td align="center">31</td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td></tr></table>';
