package HTML::CalendarMonth::Lang;

# base class for language modules with some automatic configuration of
# certain lookup hashes and patterns.

use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.01';

my %Register;

sub new { bless {}, shift }

sub days {
  my $class = shift;
  $class = ref $class || $class;
  $Register{$class}{days};
}

sub months {
  my $class = shift;
  $class = ref $class || $class;
  $Register{$class}{months};
}

sub minmatch {
  my $class = shift;
  $class = ref $class || $class;
  $Register{$class}{minmatch};
}

sub daynums {
  my $class = shift;
  $class = ref $class || $class;
  $Register{$class}{daynum};
}

sub daynum {
  my($class, $day) = @_;
  defined $day or croak "day of week label required\n";
  $class = ref $class || $class;
  $Register{$class}{daynum}{$day};
}

sub monthnums {
  my $class = shift;
  $class = ref $class || $class;
  $Register{$class}{monthnum};
}

sub monthnum {
  my($class, $month) = @_;
  defined $month or croak "month label required\n";
  $class = ref $class || $class;
  $Register{$class}{monthnum}{$month};
}

###

sub register_days {
  my $class = shift;
  $class = ref $class || $class;
  $class || croak "could not determine class\n";
  @_ == 7 or croak '7 days required ('.join(',',@_).")\n";
  $Register{$class}{days} = [@_];
  my %daynum;
  foreach my $i (0 .. $#_) { $daynum{$_[$_]} = $_ }
  $Register{$class}{daynum} = \%daynum;
}

sub register_months {
  my $class = shift;
  $class = ref $class || $class;
  $class || croak "could not determine class\n";
  @_ == 12 || croak "12 months required\n";
  $Register{$class}{months} = [@_];
  $Register{$class}{minmatch} = $class->minmatch_hash(@_);
  my %monthnum;
  foreach (0 .. $#_) { $monthnum{$_[$_]} = $_ }
  $Register{$class}{monthnum} = \%monthnum;
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

sub minmatch_pattern { join('|',keys %{shift->minmatch}) }

1;

__END__

=head1 NAME

HTML::CalendarMonth::Lang - Base class for HTML::CalendarMonth language modules

=head1 SYNOPSIS

  package HTML::CalendarMonth::en;

  use HTML::CalendarMonth::Lang;
  @ISA = qw(HTML::CalendarMonth::Lang);

  __PACKAGE__->register_days(qw(Su M Tu W Th F Sa));

  __PACKAGE__->register_months(
    qw(January   February March    April
       May       June     July     August
       September October  November December)
  );

  1;

=head1 DESCRIPTION

HTML:CalendarMonth can render itself in many languages if it's given
enough clues about the language in question. All it needs is a list of
day-of-the-week abbreviations and a list of month names. The langauge-
specific class should inherit from HTML::CalendarMonth::Lang. Preferably
the name of the module should be an applicable iso639 abbreviation, all
in lower case. See http://www.loc.gov/standards/iso639-2/englangn.html
for more information on these langauge codes.

The list of currently installed language modules can be discovered from within HTML::CalendarMonth with the following class method:

  HTML::CalendarMonth->lang_list()

Feel free to look at the existing modules and install your own.
Send the results to me if you like, or just send me the details for
your particular language and I can create a language module for
that language.

=head1 METHODS

Only two class methods need be invoked within the language module:

=item register_days

Takes a list of labels for each day of the week. By default this list
expects the label for Sunday to be first, but it doesn't really matter
as that can be adjusted with the C<week_begin> parameter in the
HTML::CalendarMonth constructor.

=item register_months

Takes a list of labels for each month of the year. By default this list
expects the label for January to be first.

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTML::CalendarMonth(3)
