package HTML::CalendarMonth::DateTool::DateTime;

# Interface to DateTime

use strict;
use Carp;

use vars qw(@ISA $VERSION);

@ISA = qw(HTML::CalendarMonth::DateTool);

$VERSION = '0.02';

use DateTime;

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  my $lastday = $self->_last_dom_dt($year, $month);
  my $dow1st = $self->dow(1);
  ($dow1st, $lastday->day);
}

sub day_epoch {
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $dt = $self->_new_dt($year, $month, $day);
  $dt->epoch;
}

sub dow {
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $dt = $self->_new_dt($year, $month, $day);
  $dt->dow;
}

sub add_days {
  my($self, $delta, $day, $month, $year) = @_;
  defined $delta || croak "Delta (in days) required.\n";
  $day   || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $dt = $self->_new_dt($year, $month, $day);
  $dt->add(days => $delta);
  ($dt->day, $dt->month, $dt->year);
}

sub week_of_year {
  my($self, $day, $month, $year) = @_;
  $day || croak "Day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $dt = $self->_new_dt($year, $month, $day);
  # returns ($year, $week)
  $dt->week;
}

sub _new_dt {
  my $self = shift;
  my($year, $month, $day) = @_;
  $year or croak "year and month required\n";
  my %parms = (year => $year);
  $parms{month} = $month if $month;
  $parms{day}   = $day    if $day;
  $parms{hour} = 0;
  $parms{minute} = 0;
  $parms{second} = 0;
  DateTime->new(%parms);
}

sub _last_dom_dt {
  my $self = shift;
  my($year, $month) = @_;
  $year && $month or croak "Year and month required.\n";
  DateTime->last_day_of_month(year => $year, month => $month);
}

1;
