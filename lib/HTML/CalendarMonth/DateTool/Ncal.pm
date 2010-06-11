package HTML::CalendarMonth::DateTool::Ncal;

# Interface to linux 'ncal' command

use strict;
use Carp;

use vars qw(@ISA $VERSION);

@ISA = qw(HTML::CalendarMonth::DateTool);

$VERSION = '0.01';

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  my $cmd = $self->ncal_cmd or croak "ncal command not found\n";
  my @cal = grep(!/^\s*$/,`$cmd -w $month $year`);
  shift @cal if $cal[0] =~ /\D+/;
  my @woy;
  if ($cal[-1] =~ /^\s*\d+/) {
    @woy = (pop @cal) =~ /(\d+)/g;
  }
  my($dow1st, %woy, %dow);
  my $last_day = 0;
  for my $di (0 .. $#cal) {
    my $dow_row = $cal[$di];
    $dow_row =~ s/^\s+//;
    $dow_row =~ s/\s+$//;
    $dow_row =~ s/\s{3,}/ 0 /g;
    $dow_row =~ s/\D+/ /g;
    $dow_row =~ s/^\s+//;
    my @days = split(/\s+/, $dow_row);
    $dow1st = ($di + 1) % 7 if !$dow1st && $days[0];
    for my $i (0 .. $#woy) {
      my $d = $days[$i] || next;
      $last_day = $d if $d > $last_day;
      $woy{$d}  = $woy[$i];
      $dow{$d}  = $di;
    }
  }
  # catch switchover from Julian to Gregorian
  $self->skips(undef);
  if ($month == 9 && $year == 1752) {
    my %skips;
    grep(++$skips{$_}, 3 .. 13);
    $self->skips(\%skips);
  }
  delete $self->{_woy};
  delete $self->{_lastday};
  $self->{_woy}{$year}{$month}     = \%woy if %woy;
  $self->{_dow}{$year}{$month}     = \%dow if %dow;
  $self->{_lastday}{$year}{$month} = $last_day;
  ($dow1st, $last_day);
}

sub week_of_year {
  my($self, $day, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  croak "week of year not supported by ncal prior to 10/1752"
    if $year < 1752 || ($year == 1752 && $month < 10);
  $self->dow1st_and_lastday unless $self->{_woy}{$year}{$month};
  $self->{_woy}{$year}{$month}{$day};
}

sub dow {
  my($self, $day, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  $self->dow1st_and_lastday unless $self->{_dow}{$year}{$month};
  $self->{_dow}{$year}{$month}{$day};
}

sub add_days {
  my($self, $delta, $day, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  if ($delta <= 0) {
    $delta = abs($delta);
    if ($delta < $day) {
      return($day - $delta, $month, $year);
    }
    else {
      my @days = reverse 1 .. $day;
      while (@days < $delta) {
        --$month;
        if ($month <= 0) {
          --$year; $month = 12;
        }
        my($dow1st, $last_day) = $self->dow1st_and_lastday($month, $year);
        push(@days, reverse 1 .. $last_day);
      }
      return($days[$delta], $month, $year);
    }
  }
  else {
    my $last_day = $self->{_lastday}{$year}{$month} ||
                   ($self->dow1st_and_lastday($month, $year))[1];
    if ($delta + $day <= $last_day) {
      return($day + $delta, $month, $year);
    }
    my @days = $day .. $last_day;
    while (@days < $delta) {
      ++$month;
      if ($month > 12) {
        ++$year; $month = 1;
      }
      my($dow1st, $last_day) = $self->dow1st_and_lastday($month, $year);
      push(@days, 1 .. $last_day);
    }
    return($days[$delta], $month, $year);
  }
}

1;
