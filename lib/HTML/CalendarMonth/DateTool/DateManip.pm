package HTML::CalendarMonth::DateTool::DateManip;

# Interface to Date::Manip

use strict;
use Carp;

use vars qw(@ISA $VERSION);

@ISA = qw(HTML::CalendarMonth::DateTool);

$VERSION = '0.01';

use Date::Manip qw(Date_DaysInMonth Date_DayOfWeek DateCalc
                   UnixDate Date_SecsSince1970);

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  my $lastday = Date_DaysInMonth($month, $year);
  # Date::Manip uses 1 for Monday, 7 for Sunday as well.
  my $dow1st = $self->dow(1);
  ($dow1st, $lastday);
}

sub day_epoch {
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  Date_SecsSince1970($month, $day, $year, 0, 0, 0);
}

sub dow {
  # Date::Manip uses 1..7 as indicies in the week, starting with Monday.
  # Internally, we use 0..6, starting with Sunday. These turn out to be
  # identical except for Sunday.
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $dow = Date_DayOfWeek($month, $day, $year);
  $dow = 0 if $dow == 7;
  $dow;
}

sub add_days {
  my($self, $delta, $day, $month, $year) = @_;
  $delta || croak "Delta (in days) required.\n";
  $day   || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $date = DateCalc(sprintf("%04d%02d%02d", $year, $month, $day),
                      "+ $delta days");
  my($y, $m, $d) = $date =~ /^(\d{4})(\d\d)(\d\d)/;
  $_ += 0 foreach ($y, $m, $d);
  ($d, $m, $y);
}

sub week_of_year {
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $week = UnixDate(sprintf("%04d%02d%02d", $year, $month, $day), '%U');
  $week += 0;
  ($year, $week);
}

1;
