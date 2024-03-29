package HTML::CalendarMonth::Locale;
{
  $HTML::CalendarMonth::Locale::VERSION = '1.26';
}

# Front end class around DateTime::Locale. In addition to providing
# access to the DT::Locale class and locale-specific instance, this
# class prepares some other hashes and lookups utilized by
# HTML::CalendarMonth.

use strict;
use warnings;
use Carp;

use DateTime::Locale 0.45;

my %Register;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  my %parms = @_;
  my $id = $parms{id} or croak "Locale id required (eg 'en_US')\n";
  $self->{id} = $id;
  $self->{full_days}   = defined $parms{full_days}   ? $parms{full_days}   : 0;
  $self->{full_months} = defined $parms{full_months} ? $parms{full_months} : 1;
  unless ($Register{$id}) {
    $Register{$id} = $self->locale->load($id)
      or croak "Problem loading locale '$id'\n";
  }
  $self;
}

sub locale { 'DateTime::Locale' }

sub loc { $Register{shift->id} }

sub locales { shift->locale->ids }

sub id          { shift->{id}          }
sub full_days   { shift->{full_days}   }
sub full_months { shift->{full_months} }

sub first_day_of_week { shift->loc->first_day_of_week % 7 }

sub days {
  my $self = shift;
  my $id = $self->id;
  unless ($Register{$id}{days}) {
    my $method = $self->full_days > 0 ? 'day_stand_alone_wide'
                                      : 'day_stand_alone_abbreviated';
    # adjust to H::CM standard expectation, 1st day Sun
    # Sunday is first, regardless of what the calendar considers to be
    # the first day of the week
    my @days  = @{$self->loc->$method};
    unshift(@days, pop @days);
    $Register{$id}{days} = \@days;
  }
  wantarray ? @{$Register{$id}{days}} : $Register{$id}{days};
}

sub narrow_days {
  my $self = shift;
  my $id   = $self->id;
  unless ($Register{$id}{narrow_days}) {
    # Sunday is first, regardless of what the calendar considers to be
    # the first day of the week
    my @days = @{ $self->loc->day_stand_alone_narrow };
    unshift(@days, pop @days);
    $Register{$id}{narrow_days} = \@days;
  }
  wantarray ? @{$Register{$id}{narrow_days}} : $Register{$id}{narrow_days};
}

sub months {
  my $self = shift;
  my $id = $self->id;
  unless ($Register{$id}{months}) {
    my $method = $self->full_months > 0 ? 'month_stand_alone_wide'
                                        : 'month_stand_alone_abbreviated';
    $Register{$id}{months} = [@{$self->loc->$method}];
  }
  wantarray ? @{$Register{$id}{months}} : $Register{$id}{months};
}

sub narrow_months {
  my $self = shift;
  my $id   = $self->id;
  $Register{$id}{narrow_months} ||= [$self->loc->month_stand_alone_narrow];
  wantarray ? @{$Register{$id}{narrow_months}} : $Register{$id}{narrow_months};
}

sub days_minmatch {
  my $self = shift;
  $Register{$self->id}{days_mm}
    ||= $self->lc_minmatch_hash($self->days);
}
*minmatch = \&days_minmatch;

sub _days_minmatch_pattern {
  my $dmm = shift->days_minmatch;
  join('|', sort keys %$dmm);
}
*minmatch_pattern = \&_days_minmatch_pattern;


sub months_minmatch {
  my $self = shift;
  $Register{$self->id}{months_mm}
    ||= $self->lc_minmatch_hash($self->months);
}

sub _months_minmatch_pattern {
  my $mmm = shift->months_minmatch;
  join('|', sort keys %$mmm);
}

sub daynums {
  my $self = shift;
  my $id = $self->id;
  unless ($Register{$id}{daynum}) {
    my %daynum;
    my $days = $self->days;
    $daynum{$days->[$_]} = $_ foreach 0 .. $#$days;
    $Register{$id}{daynum} = \%daynum;
  }
  $Register{$id}{daynum};
}

sub _daymatch {
  my($self, $day) = @_;
  return unless defined $day;
  if ($day =~ /^\d+$/) {
    $day %= 7;
    return($day, $self->days->[$day]);
  }
  my $p = $self->_days_minmatch_pattern;
  if ($day =~ /^($p)/i) {
    $day = $self->days_minmatch->{lc $1};
    return($self->daynums->{$day}, $day);
  }
  return ();
}

sub daynum  { (shift->_daymatch(@_))[0] }
sub dayname { (shift->_daymatch(@_))[1] }

sub monthnums {
  my $self = shift;
  my $id = $self->id;
  unless ($Register{$id}{monthnum}) {
    my %monthnum;
    my $months = $self->months;
    $monthnum{$months->[$_]} = $_ foreach 0 .. $#$months;
    $Register{$id}{monthnum} = \%monthnum;
  }
  $Register{$id}{monthnum};
}

sub _monthmatch {
  my($self, $mon) = @_;
  return unless defined $mon;
  if ($mon =~ /^\d+$/) {
    $mon %= 12;
    return($mon, $self->months->[$mon]);
  }
  my $p = $self->_months_minmatch_pattern;
  if ($mon =~ /^($p)/i) {
    $mon = $self->months_minmatch->{lc $1};
    return($self->monthnums->{$mon}, $mon);
  }
  return ();
}

sub monthnum  { (shift->_monthmatch(@_))[0] }
sub monthname { (shift->_monthmatch(@_))[1] }

###

sub locale_map {
  my $self = shift;
  my %map;
  foreach my $id ($self->locales) {
    $map{$id} = $self->locale->load($id)->name;
  }
  wantarray ? %map : \%map;
}

###

sub lc_minmatch_hash {
  # given a list, provide a reverse lookup of case-insensitive minimal
  # values for each label in the list
  my $whatever = shift;
  my @orig_labels = @_;
  my @labels = map { lc $_ } @orig_labels;
  my $cc = 1;
  my %minmatch;
  while (@labels) {
    my %scratch;
    foreach my $i (0 .. $#labels) {
      my $str = $labels[$i];
      my $chrs = substr($str, 0, $cc);
      $scratch{$chrs} ||= [];
      push(@{$scratch{$chrs}}, $i);
    }
    my @keep_i;
    foreach (keys %scratch) {
      if (@{$scratch{$_}} == 1) {
        $minmatch{$_} = $orig_labels[$scratch{$_}[0]];
      }
      else {
        push(@keep_i, @{$scratch{$_}});
      }
    }
    @labels      = @labels[@keep_i];
    @orig_labels = @orig_labels[@keep_i];
    ++$cc;
  }
  \%minmatch;
}

sub minmatch_hash {
  # given a list, provide a reverse lookup of minimal values for each
  # label in the list
  my $whatever = shift;
  my @labels = @_;
  my $cc = 1;
  my %minmatch;
  while (@labels) {
    my %scratch;
    foreach my $i (0 .. $#labels) {
      my $str = $labels[$i];
      my $chrs = substr($str, 0, $cc);
      $scratch{$chrs} ||= [];
      push(@{$scratch{$chrs}}, $i);
    }
    my @keep_i;
    foreach (keys %scratch) {
      if (@{$scratch{$_}} == 1) {
        $minmatch{$_} = $labels[$scratch{$_}[0]];
      }
      else {
        push(@keep_i, @{$scratch{$_}});
      }
    }
    @labels = @labels[@keep_i];
    ++$cc;
  }
  \%minmatch;
}

1;

__END__

=head1 NAME

HTML::CalendarMonth::Locale - Front end class for DateTime::Locale

=head1 SYNOPSIS

  use HTML::CalendarMonth::Locale;

  my $loc = HTML::CalendarMonth::Locale->new( id => 'en_US' );

  # list of days of the week for locale
  my @days = $loc->days;

  # list of months of the year for locale
  my @months = $loc->months;

  # the name of the current locale, as supplied the id parameter to
  # new()
  my $locale_name = $loc->id;

  # the actual DateTime::Locale object
  my $loc = $loc->loc;

  1;

=head1 DESCRIPTION

HTML::CalendarMonth utilizes the powerful locale capabilities of
DateTime::Locale for rendering its calendars. The default locale is
'en_US' but many others are available. To see this list, invoke the
class method HTML::CalendarMonth::Locale->locales() which in turn
invokes DateTime::Locale::ids().

This module is mostly intended for internal usage within
HTML::CalendarMonth, but some of its functionality may be of use for
developers:

=head1 METHODS

=over

=item new()

Constructor. Takes the following parameters:

=over

=item id

Locale id, e.g. 'en_US'.

=item full_days

Specifies whether full day names or their abbreviations are desired.
Default 0, use abbreviated days.

=item full_months

Specifies whether full month names or their abbreviations are desired.
Default 1, use full months.

=back

=item id()

Returns the locale id used during object construction.

=item locale()

Accessor method for the DateTime::Locale class, which in turn offers
several class methods of specific interest. See L<DateTime::Locale>.

=item locale_map()

Returns a hash of all available locales, mapping their id to their
full name.

=item loc()

Accessor method for the DateTime::Locale instance as specified by C<id>.
See L<DateTime::Locale>.

=item locales()

Lists all available locale ids. Equivalent to locale()->ids(), or
DateTime::Locale->ids().

=item days()

Returns a list of days of the week, Sunday first. These are the actual
unique day strings used for rendering calendars, so depending on which
attributes were provided to C<new()>, this list will either be
abbreviations or full names. The default uses abbreviated day names.
Returns a list in list context or an array ref in scalar context.

=item narrow_days()

Returns a list of short day abbreviations, beginning with Sunday. The
narrow abbreviations are not guaranteed to be unique (i.e. 'S' for both
Sat and Sun).

=item days_minmatch()

Provides a hash reference containing minimal case-insensitive match
strings for each day of the week, e.g., 'sa' for Saturday, 'm' for
Monday, etc.

=item months()

Returns a list of months of the year, beginning with January. Depending
on which attributes were provided to C<new()>, this list will either be
full names or abbreviations. The default uses full names. Returns a list
in list context or an array ref in scalar context.

=item narrow_months()

Returns a list of short month abbreviations, beginning with January. The
narrow abbreviations are not guaranteed to be unique.

=item months_minmatch()

Provides a hash reference containing minimal case-insensitive match
strings for each month of the year, e.g., 'n' for November, 'ja' for
January, 'jul' for July, 'jun' for June, etc.

=item daynums()

Provides a hash reference containing day of week indices for each fully
qualified day name as returned by days().

=item daynum($day)

Provides the day of week index for a particular day name.

=item dayname($day)

Provides the fully qualified day name for a given string or day index.

=item monthnums()

Provides a hash reference containing month of year indices for each
fully qualified month name as returned by months().

=item monthnum($month)

Provides the month of year index for a particular month name.

=item monthname($month)

Provides the month name for a given string or month index.

=item minmatch_hash(@list)

This is the method used to generate the case-insensitive minimal match
hash referenced above. Given an arbitrary list, a hash reference will
be returned with minimal match strings as keys and the original strings
as values.

=item lc_minmatch_hash(@list)

Same as minmatch_hash, except keys are forced to lower case.

=item first_day_of_week()

Returns a number from 0 to 6 representing the first day of the week for
this locale, where 0 represents Sunday.

=back

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2010 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTML::CalendarMonth(3), DateTime::Locale(3)

=for Pod::Coverage minmatch minmatch_pattern
