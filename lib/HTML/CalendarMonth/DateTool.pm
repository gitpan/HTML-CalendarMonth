package HTML::CalendarMonth::DateTool;

# Base class for determining what date calculation package to use.

use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.01';

my $DEBUG = 0;

my %Toolmap = (
  'Time::Local' => 'TimeLocal',
  'Date::Calc'  => 'DateCalc',
  'DateTime'    => 'DateTime',
  'Date::Manip' => 'DateManip',
  'cal'         => 'Cal',
);

sub toolmap {
  shift;
  my $str = shift;
  my $tool = $Toolmap{$str};
  unless ($tool) {
    foreach (values %Toolmap) {
      if ($str =~ /^$_$/i) {
        $tool = $_;
        last;
      }
    }
  }
  return undef unless $tool;
  join('::', __PACKAGE__, $tool);
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  my %parms = @_;
  $self->{year}     = $parms{year}  or croak "missing year (YYYY)\n";
  $self->{month}    = $parms{month} or croak "missing month num (1-12)\n";
  $self->{weeknum}  = $parms{weeknum};
  $self->{historic} = $parms{historic};
  if ($parms{datetool}) {
    $self->{datetool} = $self->toolmap($parms{datetool})
      or croak "Sorry, didn't find a tool for datetool '$parms{datetool}'\n";
  }
  my $dc = $self->_summon_date_class;
  unless (eval "require $dc") {
    croak "Problem loading $dc ($@)\n";
  }
  print STDERR "Using date class $dc\n" if $DEBUG;
  # rebless into new class
  bless $self, $dc;
}

sub year     { shift->{year}     }
sub month    { shift->{month}    }
sub weeknum  { shift->{weeknum}  }
sub historic { shift->{historic} }
sub datetool { shift->{datetool} }

sub cal_cmd {
  my $self = shift;
  unless (exists $self->{cal_cmd}) {
    my $cal;
    foreach (qw(/usr/bin /bin /usr/local/bin)) {
      if (-x "$_/cal") {
        $cal = "$_/cal";
        last;
      }
    }
    $self->{cal_cmd} = $cal || undef;
  }
  $self->{cal_cmd};
}

sub day_epoch {
  # in case our subclasses are lazy
  my($self, $day, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  Time::Local::timegm(0,0,0,1,$month,$year);
}

sub skips {
  my $self = shift;
  @_ ? $self->{skips} = shift : $self->{skips};
}

sub dow1st  { (shift->dow1st_and_lastday)[0] }

sub lastday { (shift->dow1st_and_lastday)[1] }

sub _summon_date_class {
  my $self = shift;
  return $self->datetool if $self->datetool;
  my $year = $self->year;
  my $weeknum = $self->weeknum;
  my $historic = $self->historic;
  my $cal = $self->cal_cmd;
  my $dc;
  if ( !$weeknum && eval "require Time::Local" &&
      (!defined $year || (($year >= 1970) && ($year < 2038)))) {
    $dc = __PACKAGE__ . '::TimeLocal';
  }
  elsif (!$weeknum && $historic && $cal) {
    $dc = __PACKAGE__ . '::Cal';
  }
  elsif (eval "require DateTime") {
    $dc = __PACKAGE__ . '::DateTime';
  }
  elsif(eval "require Date::Calc") {
    $dc = __PACKAGE__ . '::DateCalc';
  }
  elsif(eval "require Date::Manip") {
    $dc = __PACKAGE__ . '::DateManip';
  }
  else {
    croak <<__NOTOOL;
No valid date mechanism found. Install Date::Calc, DateTime, or
Date::Manip, or try using a date between 1970 and 2038 so that
Time::Local can be used.
__NOTOOL
  }
  $dc;
}

1;

__END__

=head1 NAME

HTML::CalendarMonth::DateTool - Base class for determining which date package to use for calendrical calculations.

=head1 SYNOPSIS

  my $date_tool = HTML::CalendarMonth::DateTool->new(
                    year     => $YYYY_year,
                    month    => $one_thru_12_month,
                    weeknum  => $weeknum_mode,
                    historic => $historic_mode,
                    datetool => $specific_datetool_if_desired,
                  );

=head1 DESCRIPTION

This module attempts to utilize the best date calculation package
available on the current system. For most contemporary dates this
usually ends up being the internal Time::Local package of perl. For more
exotic dates, or when week number of the years are desired, other
methods are attempted including DateTime, Date::Calc, Date::Manip, and
the unix 'cal' command. Each of these has a specific subclass of this
module offering the same utility methods needed by HTML::CalendarMonth.

=head1 METHODS

=item new()

Constructor. Takes the following parameters:

=over

=item year

Year of calendar in question (required). If you are rendering exotic
dates (i.e. dates outside of 19070 to 2038) then something besides
Time::Local will be used for calendrical calculations.

=item month

Month of calendar in question (required). 1 through 12.

=item weeknum

Optional. When specified, will limit class excursions to those that are
currently set up for week of year calculations.

=item historic

Optional. If the 'cal' command is available, use it rather than other available
date modules since the 'cal' command accurately handles some specific
historical artifacts such as the transition from Julian to Gregorian.

=item datetool

Optional. Mostly for debugging, this option can be used to indicate a
specific HTML::CalendarMonth::DateTool subclass for instantiation. The
value can be either the actual utility class, e.g., Date::Calc, or the
name of the CalendarMonth handler leaf class, e.g. DateCalc. For the
'cal' command, use 'cal'.

=back

There are number of methods automatically available:

=item month()

=item year()

=item weeknum()

=item historical()

=item datetool()

Accessors for the parameters provided to C<new()> above.

=item dow1st()

Returns the day of week number for the 1st of the C<year> and C<month>
specified during the call to C<new()>. This can be overridden directly,
otherwise it relies on the presence of C<dow1st_and_lastday()>.

=item lastday()

Returns the last day of the month for the C<year> and C<month> specified
during the call to C<new()>. This can be overridden directly, otherwise
it relies on the presence of C<dow1st_and_lastday()>.

=head1 Overridden methods

Subclasses of this module must provide at least the C<day_epoch()>
and C<dow1st_and_lastday()> methods. Optionally, rather than the
C<dow1st_and_lastday()> method, subclasses can override both C<dow1st()>
and C<lastday()> individually.

=item dow1st_and_lastday()

Provides a list containing the day of the week of the first day of the
month along with the last day of the month.

=item day_epoch()

For a given day, and optionally C<month> and C<year> if they are
different from those specified in C<new()>, provide the unix epoch in
seconds for that day at midnight.

If the subclass is expected to provide week of year numbers, three more
methods are necessary:

=item dow()

For a given day, and optionally C<month> and C<year> if they are
different from those specified in C<new()>, provide the day of week
number. (1=Sunday, 6=Saturday).

=item add_days($days, $delta, $day, [$month], [$year])

For a given day, and optionally C<month> and C<year> if they are
different from those specified in C<new()>, provide a list of year,
month, and day once C<delta> days have been added.

=item week_of_year($day, [$month], [$year])

For a given day, and optionally C<month> and C<year> if they are
different from those specified in C<new()>, provide a list with the week
number of the year along with the year. (some days of a particular year
can end up belonging to the prior or following years).

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTML::CalendarMonth(3), Time::Local(3), DateTime(3), Date::Calc(3),
Date::Manip(3), cal(1)

