package HTML::CalendarMonth::Locale;

# Front end class around DateTime::Locale. In addition to providing
# access to the DT::Locale class and locale-specific instance, this
# class prepares some other hashes and lookups utilized by
# HTML::CalendarMonth.

use strict;
use Carp;

use DateTime::Locale;

use vars qw($VERSION);
$VERSION = '0.01';

my %Register;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  my %parms = @_;
  my $id = $parms{id} or croak "Locale id required (eg 'en_US')\n";
  $self->{id} = $id;
  $self->{full_days}   = exists $parms{full_days}   ? $parms{full_days}   : 0;
  $self->{full_months} = exists $parms{full_months} ? $parms{full_months} : 1;
  unless ($Register{$id}) {
    $Register{$id} = DateTime::Locale->load($id)
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

sub days {
  my $self = shift;
  my $id = $self->id;
  unless ($Register{$id}{days}) {
    # we've always used Sunday as first day...
    my $method = $self->full_days ? 'day_names' : 'day_abbreviations';
    my @days = @{$self->loc->$method};
    unshift(@days, pop @days);
    $Register{$id}{days} = \@days;
  }
  wantarray ? @{$Register{$id}{days}} : $Register{$id}{days};
}

sub months {
  my $self = shift;
  my $id = $self->id;
  unless ($Register{$id}{months}) {
    my $method = $self->full_months ? 'month_names' : 'month_abbreviations';
    $Register{$id}{months} = [@{$self->loc->$method}];
  }
  wantarray ? @{$Register{$id}{months}} : $Register{$id}{months};
}

sub minmatch {
  my $self = shift;
  my $id = $self->id;
  unless ($Register{$id}{minmatch}) {
    $Register{$id}{days_minmatch} = 
      $self->minmatch_hash(@{$self->days});
  }
  $Register{$id}{days_minmatch};
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

sub daynum {
  my($self, $day) = @_;
  defined $day or croak "day of week label required\n";
  my $days = $self->days;
  $days->{$day} or croak "Failed daynum lookup for '$day'\n";
}

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

sub monthnum {
  my($self, $month) = @_;
  defined $month or croak "month label required\n";
  my $monthnums = $self->monthnums;
  $monthnums->{$month} or croak "Failed monthnum lookup for '$month'\n";
}

###

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

sub minmatch_pattern { join('|',keys %{shift->minmatch}) }

1;

__END__

=head1 NAME

HTML::CalendarMonth::Lang - Front end class for DateTime::Locale

=head1 SYNOPSIS

  use HTML::CalendarMonth::Locale;

  my $loc = HTML::CalendarMonth::Locale->new( id => 'en_US' );

  1;

=head1 DESCRIPTION

HTML::CalendarMonth utilizes the powerful locale capabilities of
DateTime::Locale for rendering its calendars. The default locale is
'en_US' but many others are available. To see this list, invoke the
class method HTML::CalendarMonth::Locale->locales() which in turn
invokes DateTime::Locale::ids().

This module is mostly inteded for internal usage within
HTML::CalendarMonth, but some of its functionality may be of use for
developers:

=head1 METHODS

=item new()

Constructor. Takes the following parameters:

=over

=item id

Locale id, e.g. 'en_US'.

=back

=item id()

Rturns the locale id used during object construction.

=item locale()

Accessor method for the DateTime::Locale class, which in turn offers
several class moethods of specific interest. See L<DateTime::Locale>.

=item loc()

Accessor method for the DateTime::Locale instance as specified by C<id>.
See L<DateTime::Locale>.

=item locales()

Lists all available locale ids. Equivalent to locale()->ids(), or
DateTime::Locale->ids().

=item days()

Returns a list of days of the week, Sunday first. These are the actual
days used for rendering the calendars, so depending on which attributes
were provided to C<new()>, this list will either be abbreviations or
full names. The default uses abbreviated day names. Returns a list in
list context or an array ref in scalar context.

=item months()

Returns a list of months of the year, beginning with January. Depending
on which attributes were provided to C<new()>, this list will either be
full names or abbreviations. The default uses full names. Returns a list
in list context or an array ref in scalar context.

=item minmatch()

Provides a hash reference containing minimal match strings for each
month of the year, e.g., 'J' for January, 'Mar' for March, 'May'
for May, etc.

=item daynums()

Provides a hash reference containing day of week numbers for each day
name.

=item daynum($day)

Provides the day of week number for a particular day name.

=item monthnums()

Provides a hash reference containing month of year numbers for each
month name.

=item monthnum($month)

Provides the month of year number for a particular month name.

=item minmatch_hash(@list)

This is the method used to generate the minimal match hash referenced
above. Given an arbitrary list, a hash reference will be returned with
minimal match strings as keys and full names as values.

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTML::CalendarMonth(3), DateTime::Locale(3)
