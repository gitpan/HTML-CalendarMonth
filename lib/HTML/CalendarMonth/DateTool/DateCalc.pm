package HTML::CalendarMonth::DateTool::DateCalc;

# Interface to Date::Calc

use strict;
use Carp;

use vars qw(@ISA $VERSION);

@ISA = qw(HTML::CalendarMonth::DateTool);

$VERSION = '0.02';

use Date::Calc qw(Days_in_Month Day_of_Week Add_Delta_Days
                  Weeks_in_Year Week_of_Year Week_Number Mktime
                 );

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  my $lastday = Days_in_Month($year, $month);
  # Date::Calc uses 1..7 as indicies in the week, starting with Monday.
  # Internally, we use 0..6, starting with Sunday. These turn out to be
  # identical except for Sunday.
  my $dow1st = $self->dow(1);
  $dow1st = 0 if $dow1st == 7;
  ($dow1st, $lastday);
}

sub day_epoch {
  my($self, $day, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  Mktime($year, $month, $day, 0, 0, 0);
}

sub dow {
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  Day_of_Week($year, $month, $day);
}

sub add_days {
  my($self, $delta, $day, $month, $year) = @_;
  $delta || croak "Delta (in days) required.\n";
  $day   || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my($y, $m, $d) = Add_Delta_Days($year, $month, $day, $delta);
  ($d, $m, $y);
}

sub week_of_year {
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $week;
  ($week, $year) = Week_of_Year($year, $month, $day);
  ($year, $week);
}

1;
