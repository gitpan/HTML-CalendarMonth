package HTML::CalendarMonth::Accessor;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.01';

use Carp;

use Class::Accessor;

@ISA = qw(Class::Accessor);

my %Objects;

# Default complex attributes
my %Calmonth_Attrs = (
  head_m      => 1,  # Month heading mode
  head_y      => 1,  # Year heading mode
  head_dow    => 1,  # DOW heading mode
  head_week   => 0,  # European week number mode
  year_span   => 2,  # Default col span of year

  week_begin  => 1,  # What DOW (1-7) is the 1st DOW?

  historic    => 1,  # If able to choose, use 'cal'
                     # rather than Date::Calc, which
                     # blindly extrapolates Gregorian

  row_offset  => 0,  # Displacment within table
  col_offset  => 0,

  alias       => {}, # What gets displayed if not
                     # the default item

  month       => '', # These will get initialized
  year        => '',

  locale      => 'en_US',
  full_days   => 0,
  full_months => 1,

  datetool    => '',
  caltool     => '',

  # internal muckety muck
  _cal      => '',
  _itoc     => {},
  _ctoi     => {},
  _caltool  => '',
  _weeknums => '',

  dow1st   => '',
  lastday  => '',
  loc      => '',
);

__PACKAGE__->mk_accessors(keys %Calmonth_Attrs);

# Class::Accessor overrides

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  foreach (sort keys %Calmonth_Attrs) {
    $self->$_($Calmonth_Attrs{$_});
  }
  $self;
}

sub set {
  my($self, $key) = splice(@_, 0, 2);
  if (@_ == 1) {
    $Objects{$self}{$key} = $_[0];
  }
  elsif (@_ > 1) {
    $Objects{$self}{$key} = [@_];
  }
  else {
    Carp::confess("Wrong number of arguments received");
  }
}

sub get {
  my $self = shift;
  if (@_ == 1) {
    return $Objects{$self}{$_[0]};
  }
  elsif ( @_ > 1 ) {
    return @{$Objects{$self}{@_}};
  }
  else {
    Carp::confess("Wrong number of arguments received.");
  }
}

sub is_calmonth_attr { shift; exists $Calmonth_Attrs{shift()} }

sub set_defaults {
  my $self = shift;
  foreach (keys %Calmonth_Attrs) {
    $self->$_($Calmonth_Attrs{$_});
  }
  $self;
}

1;
