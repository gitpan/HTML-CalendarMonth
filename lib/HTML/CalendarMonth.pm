package HTML::CalendarMonth;

use strict;
use vars qw($VERSION $AUTOLOAD @ISA $CAL);

$VERSION = '1.11';

use Carp;

use HTML::ElementTable;
use HTML::CalendarMonth::Locale;
use HTML::CalendarMonth::DateTool;

@ISA = qw(HTML::ElementTable);

# Default complex attributes
my %COMPLEX_ATTRS = (
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
);

#################
# Attr override #
#################

sub attr {
  # Handle special attributes for the calendar element
  my $self = shift;
  $self->_complex_attr($_[0]) ? $self->_cattr(@_) :
    $self->SUPER::attr(@_);
}

#############################
# Special attribute methods #
#############################

sub _complex_attr {
  # Test whether a string is a complex attribute
  my $self = shift;
  exists $self->{_cattrs}{lc(shift)};
}

sub _cattr {
  # Generic interface for setting complex attributes
  my $self = shift;
  my $attr = lc(shift);
  croak "Invalid complex attribute" unless $self->_complex_attr($attr);
  croak "$attr already initialized" if defined $attr && $self->_initialized();
  if (@_) {
    if ($attr eq 'row_offset' || $attr eq 'col_offset') {
      $_[0] >= 0 or croak "Offset must be zero or more";
    }
  }
  @_ ? $self->{_cattrs}{$attr} = shift : $self->{_cattrs}{$attr};
}

sub _row_offset {
  # Displace calendar how many rows into table?
  my $self = shift;
  $self->_cattr('row_offset',@_);
}
sub _col_offset {
  # Displace calendar how many cols into table?
  my $self = shift;
  $self->_cattr('col_offset',@_);
}

# Alias set/retr
sub alias {
  # The alias gets set as initial cell content rather
  # than the default
  my $self = shift;
  my $item = shift;
  defined $item  or croak "Item name required";
  $self->{_cattrs}{alias}{$item} = shift if @_;
  exists $self->{_cattrs}{alias}{$item} ?
    $self->{_cattrs}{alias}{$item} : $item;
}
sub aliased {
  my $self = shift;
  my $item = shift;
  defined $item or croak "Item name required";
  defined $self->{_cattrs}{alias}{$item};
}

# Header Toggles

sub _head {
# Set/test entire heading (month,year,and dow headers)
# (does not affect European week number column)
  my $self = shift;
  # If either headeing active, return true
  if (@_) {
    $self->_head_my(@_); $self->_head_dow(@_);
  }
  $self->_head_my || $self->_head_dow;
}

sub _head_my {
# Set/test month and year header mode
  my $self = shift;
  my $mode = shift;
  if (defined $mode) {
    $self->_head_m($mode); $self->_head_y($mode);
  }
  $self->_head_m || $self->_head_y;
}

sub _initialized {
  my $self = shift;
  @_ ? $self->{_initialized} = shift : $self->{_initialized};
}

# Circa Interface

sub _date {
  # Set target month, year
  my $self = shift;
  if (@_) {
    my ($month,$year) = @_;
    $month && $year || croak "date method requires month and year";
    croak "Date already set" if $self->_initialized();

    $month <= 12 && $month >= 1 or croak "Month $month out of range (1-12)\n";
    $year > 0 or croak "Negative years are unacceptable\n";

    $self->month($self->monthname($month));
    $self->year($year);
    $month = $self->monthnum($month);

    # Clear old month/year dependencies
    delete $self->{_hitog}{$self->month};
    delete $self->{_hitog}{$self->year};

    # Trigger _gencal...this is the only place this occurs
    $self->_gencal;
  }
  return($self->month,$self->year);
}

# locale accessors

sub locales { shift->attr('loc')->locales }

sub locale_days {
  my $self = shift;
  $self->attr('loc')->days;
}
sub locale_daynums {
  my $self = shift;
  $self->attr('loc')->daynums;
}
sub locale_daynum {
  my $self = shift;
  $self->attr('loc')->daynum(@_);
}
sub locale_months {
  my $self = shift;
  $self->attr('loc')->months;
}
sub locale_minmatch {
  my $self = shift;
  $self->attr('loc')->minmatch;
}
sub locale_minmatch_pattern {
  my $self = shift;
  $self->attr('loc')->minmatch_pattern;
}
sub locale_monthnums {
  my $self = shift;
  $self->attr('loc')->monthnums;
}
sub locale_monthnum {
  my $self = shift;
  $self->attr('loc')->monthnum(@_);
}

# Publicize month and year complex attrs
sub month {
  my $self = shift;
  $self->_month(@_);
}
sub year {
  my $self = shift;
  $self->_year(@_);
}

sub _gencal {
# Generate internal calendar representation
  my $self = shift;
  # New calendar...clobber day-specific settings
  $self->{_cal} = undef;
  $self->{_itog} = undef;

  $self->_anchor_month();

  my ($wcnt) = 0; # row count for weeks in grid

  my ($dowc) = $self->dow1st;
  my $skips = $self->_caltool->skips;
  my ($r, $c);
  # For each day
  
  foreach (1 .. $self->lastday) {
    next if $skips->{$_};
    $r = $wcnt + 2 + $self->_row_offset;
    $c = $dowc + $self->_col_offset;
    # This is a bootstrap until we know the number of rows in the month.
    $self->_itoc($_, [$r, $c]);
    $dowc = ++$dowc % 7;

    ++$wcnt unless $dowc || $_ == $self->lastday;
  }

  $self->{_week_rows} = $wcnt;

  my $row_extent = $wcnt + 2;
  my $col_extent = 6;
  $col_extent += 1 if $self->_head_week;

  $self->extent($row_extent + $self->_row_offset,
                $col_extent + $self->_col_offset);

  # Table can contain the days now, so replace our bootstrap coordinates
  # with references to the actual elements.
  my $cellref;
  foreach (keys %{$self->{_itog}}) {
    $cellref = $self->cell(@{$self->_itoc($_)});
    $self->_itoc($_, $cellref);
    $self->_ctoi($cellref, $_);
  }

  # Week num affects month/year spans
  my $width = $self->_head_week ? 8 : 7;

  # Month/Year headers
  $cellref = $self->cell($self->_row_offset, $self->_col_offset);
  $self->_itoc($self->month, $cellref);
  $self->_ctoi($cellref, $self->month);
  $cellref = $self->cell($self->_row_offset,
                         $width - $self->_year_span + $self->_col_offset);
  $self->_itoc($self->year,  $cellref);
  $self->_ctoi($cellref, $self->year);

  $self->item($self->month)->replace_content($self->alias($self->month));
  $self->item($self->year)->replace_content($self->alias($self->year));

  if ($self->_head_my) {
    if ($self->_head_m) {
      $self->item($self->month)->attr('colspan',$width - $self->_year_span);
    }
    else {
      $self->item($self->month)->mask(1);
      $self->item($self->year)->attr('colspan', $width);
    }
    if ($self->_head_y) {
      $self->item($self->year)->attr('colspan',$self->_year_span);
    }
    else {
      $self->item($self->year)->mask(1);
      $self->item($self->month)->attr('colspan', $width);
    }
  }
  else {
    $self->row($self->first_row)->mask(1);
  }

  # DOW headers
  my $trans;
  my $days = $self->locale_days;
  foreach (0..$#$days) {
    # Transform for week_begin 1..7
    $trans = ($_ + $self->_week_begin - 1) % 7;
    $cellref = $self->cell(1 + $self->_row_offset, $_ + $self->_col_offset);
    $self->_itoc($days->[$trans], $cellref);
    $self->_ctoi($cellref, $days->[$trans]);
  }
  if ($self->_head_dow) {
    grep($self->item($_)->replace_content($self->alias($_)), @$days);
  }
  else {
    $self->row($self->first_row + 1)->mask(1);
  }

  # Week number column
  if ($self->_head_week) {
    # Week nums can collide with days.  Use "w" in front of
    # the number for uniqueness, and automatically alias to
    # just the number (unless already aliased, of course).
    $self->_gen_week_nums();
    my $ws;
    my $row_count = $self->first_week_row;
    foreach ($self->_numeric_week_nums) {
      $ws = "w$_";
      $self->alias($ws,$_) unless $self->aliased($ws);
      $cellref = $self->cell($row_count, $self->last_col);
      $self->_itoc($ws, $cellref);
      $self->_ctoi($cellref, $ws);
      $self->item($ws)->replace_content($self->alias($ws));
      ++$row_count;
    }
  }

  # Fill in days of the month
  my $i;
  foreach my $r ($self->first_week_row .. $self->last_row) {
    foreach my $c ($self->first_col .. $self->last_week_col) {
      $self->cell($r,$c)->replace_content($self->alias($i))
        if ($i = $self->item_at($r,$c));
    }
  }

  # Defaults
  $self->table->attr('align','center');
  $self->item($self->month)->attr('align','left') if $self->_head_m;
  $self->attr('bgcolor','white') unless defined $self->attr('bgcolor');
  $self->attr('border',1)        unless defined $self->attr('border');
  $self->attr('cellspacing',0)   unless defined $self->attr('cellspacing');
  $self->attr('cellpadding',0)   unless defined $self->attr('cellpadding');

  $self->{_cal};
}

sub _anchor_month {
  # Anchor month
  # Let HTML::CalendarMonth::DateTool figure out which method is
  # appropriate.
  my $self = shift;

  my $month = $self->monthnum($self->month);
  my $year  = $self->year;


  # Autoselect calendar generation method if undefined.
  my $tool = $self->_caltool;
  if (!$tool) {
    $tool = HTML::CalendarMonth::DateTool->new(
              year     => $year,
              month    => $month,
              weeknum  => $self->_head_week,
              historic => $self->_historic,
              datetool => $self->_datetool,
            );
    $self->_caltool($tool);
  }
  my $dow1st  = $tool->dow1st;
  my $lastday = $tool->lastday;

  # If the first day of the week is not Sunday...
  $dow1st = ($dow1st - ($self->_week_begin - 1)) % 7;

  $self->{_dow1st}  = $dow1st;
  $self->{_lastday} = $lastday;
}

sub _caltool {
  @_ ? shift->attr('caltool', @_) : shift->attr('caltool');
}

sub _gen_week_nums {
  # Generate week-of-the-year numbers (according to Date::Calc)
  # Week 1 is the week containing the first Thursday of the year.
  #
  # From the Date::Calc manpage:
  #
  #   $week = Week_Number($year,$month,$day);
  #
  #   This function returns the number of the week the given date lies
  #   in.
  #
  #   If the given date lies in the LAST week of the PREVIOUS year,
  #    "0" is returned.
  #
  #   If the given date lies in the FIRST week of the NEXT year,
  #   "Weeks_in_Year($year) + 1" is returned.
  #
  # Therefore we do bounds checks for cases where the first week
  # number is "0" or the last week number is greater than the number
  # of weeks in the year.
  #
  # These week number will *always* correspond to the Thursday slot in
  # that row, regardless of what day of the week is considered to be
  # the graphical "first" of the week.

  my $self = shift;

  my($year, $month, $lastday) = ($self->year, $self->monthnum, $self->lastday);

  my $tool = $self->_caltool;
  $tool->can('week_of_year')
    or croak "Oops. $tool not set up for week of year calculations.\n";

  my $fdow = $self->dow1st;
  my $delta = 4 - $fdow;
  if ($delta < 0) {
    $delta += 7;
  }
  my @ft = $tool->add_days($delta, 1);

  my $ldow = $tool->dow($lastday);
  $delta = 4 - $ldow;
  if ($delta > 0) {
    $delta -= 7;
  }
  my @lt = $tool->add_days($delta, $lastday);

  my $fweek = $tool->week_of_year(@ft);
  my $lweek = $tool->week_of_year(@lt);
  my @wnums = $fweek .. $lweek;

  # Do we have days above our first Thursday?
  if ($self->row_of($ft[0]) != $self->first_week_row) {
    unshift(@wnums, $wnums[0] -1);
  }

  # Do we have days below our last Thursday?
  if ($self->row_of($lt[0]) != $self->last_row) {
    push(@wnums, $wnums[-1] + 1);
  }

  # First visible week is from last year
  if ($wnums[0] == 0) {
    $wnums[0] = $tool->week_of_year($tool->add_days(-7, $ft[0]));
  }

  # Last visible week is from subsequent year
  if ($wnums[-1] > $lweek) {
    $wnums[-1] = $tool->week_of_year($tool->add_days(7, $lt[0]));
  }

  $self->{_weeknums} = \@wnums;
}

###############
# Month hooks #
###############

sub row_items {
# Given a list of items, return all items in rows shared by
# the provided items.
  my $self = shift;
  my($item,$row,$col,$i,@i,%i);
  foreach $item (@_) {
    $row = ($self->coords_of($item))[0];
    foreach $col ($self->first_col..$self->last_col) {
      $i = $self->item_at($row,$col) || next;
      ++$i{$i};
    }
  }
  @i = keys %i;
  @i ? @i : $i[0];
}
sub col_items {
  # Return all item cells in the columns occupied
  # by the provided list of items.
  my $self = shift;
  $self->_col_items($self->first_row,$self->last_row,@_);
}
sub daycol_items {
  # Same as col_items(), but excludes header cells.
  my $self = shift;
  $self->_col_items($self->first_week_row,$self->last_row,@_);
}
sub _col_items {
  # Given row bounds and a list of items, return
  # all item elements in the columns occupied by the
  # provided items.  Does not return empty cells.
  my $self = shift;
  my $rfirst = shift;
  my $rlast  = shift;
  my($item,$row,$col,$i,@i,%i);
  foreach $item (@_) {
    $col = ($self->coords_of($item))[1];
    foreach $row ($rfirst..$rlast) {
      $i = $self->item_at($row,$col) || next;
      ++$i{$i};
    }
  }
  @i = keys %i;
  $#i ? @i : $i[0];
}

sub lastday {
  # Return the last day of the month.
  my $self = shift;
  $self->{_lastday};
}
sub dow1st {
  # Return the day-of-week (0..6) for the 1st
  my $self = shift;
  $self->{_dow1st};
}

sub daytime {
  # Return seconds since epoch for a given day
  my $self = shift;
  my $day  = shift or croak "Must specify day of month";
  croak "Day does not exist" unless $self->_daycheck($day);
  $self->_caltool->day_epoch($day);
}

sub week_nums {
  # Return list of all week numbers
  my $self = shift;
  map("w$_",$self->_numeric_week_nums);
}
sub _numeric_week_nums {
  # Return list of all week numbers as numbers
  my $self = shift;
  $self->_head_week ? @{$self->{_weeknums}} : ();
}

sub days {
  # Return list of all days of the month (1..$c->lastday).
  my $self = shift;
  my $skips = $self->_caltool->skips;
  grep(!$skips->{$_},(1..$self->lastday));
}

sub dayheaders {
  # Return list of all day headers (Su..Sa).
  shift->locale_days;
}

sub headers {
  # Return list of all headers (month,year,dayheaders)
  my $self = shift;
  ($self->year,$self->month,$self->dayheaders);
}

sub items {
  # Return list of all items (days, headers)
  my $self = shift;
  ($self->headers,$self->days);
}

sub first_col {
  # Where is the first column of the calendar?
  my $self = shift;
  $self->_col_offset();
}

sub first_week_col { first_col(@_) }

sub last_col {
  # What's the max col of the calendar?
  my $self = shift;
  $self->_head_week ? $self->last_week_col + 1 : $self->last_week_col;
  $self->_head_week ? $self->last_week_col + 1 : $self->last_week_col;
}

sub last_week_col {
  # What column does the last DOW fall in?  Should be
  # the same as last_col unless _head_week is activated
  my $self = shift;
  $self->first_col + 6;
}

sub first_row {
  # Where is the first row of the calendar?
  my $self = shift;
  $self->_row_offset();
}

sub first_week_row {
  # Returns the first row containing days of the month.  This used to
  # take into account whether the header rows were active or not, but
  # since masking was implemented this should always be offset 2 from
  # the first row (thereby taking into account the month/year and DOW
  # rows).
  my $self = shift;
  my $w = 2;
  $self->first_row + $w;
}

sub last_row {
  # Last row of the calendar
  my $self = shift;
  return ($self->coords_of($self->lastday))[0];
}

sub last_week_row { last_row(@_) }

##########################
# Custom glob interfaces #
##########################

sub item {
  # Return TD elements containing items
  my $self = shift;
  @_ || croak "Item(s) must be provided";
  $self->cell(grep(defined $_, map($self->coords_of($_), @_)));
}
sub item_row {
  # Return a glob of the rows of a list of items, including
  # empty cells.
  my $self = shift;
  $self->_item_row($self->first_col,$self->last_col,@_);
}
sub item_day_row {
  # Same as item_row, but excludes possible week number cells
  my $self = shift;
  $self->_item_row($self->first_col,$self->last_week_col,@_);
}
sub _item_row {
  # Given column bounds and a list of items, return a glob
  # representing the cells in the rows occupied by the
  # provided items, including empty cells.
  my $self = shift;
  my $cfirst = shift;
  my $clast  = shift;
  @_ or croak "No items provided";
  my($row,$col,@coords);
  foreach $row (map($self->row_of($_),@_)) {
    foreach $col ($cfirst .. $clast) {
      push(@coords,$row,$col);
    }
  }
  $self->cell(@coords);
}
sub item_week_nums {
  # Glob of all week numbers
  my $self = shift;
  $self->item($self->week_nums);
}
sub item_col {
  # Return a glob of the cols of a list of items, including
  # empty cells.
  my $self = shift;
  $self->_item_col($self->first_row,$self->last_row,@_);
}
sub item_daycol {
  # Same as item_col(), but excludes header cells.
  my $self = shift;
  $self->_item_col($self->first_week_row,$self->last_row,@_);
}
sub _item_col {
  # Given row bounds and a list of items, return a glob representing
  # the cells in the columns occupied by the provided items,
  # including empty cells.
  my $self = shift;
  my $rfirst = shift;
  my $rlast  = shift;
  @_ or croak "No items provided";
  my($row,$col,@coords);
  foreach $col (map($self->col_of($_),@_)) {
    foreach $row ($rfirst .. $rlast) {
      push(@coords,$row,$col);
    }
  }
  $self->cell(@coords);
}
sub item_box {
  # Return a glob of the box defined by two items
  my $self = shift;
  my($item1,$item2) = @_;
  $item1 && $item2 or croak "Two items required";
  $self->box($self->coords_of($item1),$self->coords_of($item2));
}
sub all {
  # Return a glob of all calendar cells, including empty cells.
  my $self = shift;
  $self->box($self->first_row,$self->first_col,
             $self->last_row,$self->last_col);
}
sub alldays {
  # Return a glob of all cells other than header cells
  my $self = shift;
  $self->box($self->first_week_row,$self->first_col,
             $self->last_row,$self->last_week_col);
}
sub allheaders {
  # Return a glob of all header cells
  my $self = shift;
  $self->item($self->headers);
}

##########################
# Transformation Methods #
##########################

sub coords_of {
  # Convert an item into grid coordinates
  my $self = shift;
  my $ref = $self->_itoc(@_);
  my @pos = ref $ref ? $ref->position : ();
  @pos ? (@pos[$#pos - 1, $#pos]) : ();
}

sub item_at {
  # Convert grid coords into item
  my $self = shift;
  $self->_ctoi($self->cell(@_));
}

sub _itoc {
  # Item to cell reference
  my $self = shift;
  my($item, $ref) = @_;
  defined $item or croak "item required";
  if ($ref) {
    croak "Reference required" unless ref $ref;
    $self->{_itog}{$item} = $ref;
  }
  $self->{_itog}{$item};
}

sub _ctoi {
  # Cell reference to item
  my $self = shift;
  my($refstring, $item) = @_;
  $refstring or croak "cell id required";
  if (defined $item) {
    $self->{_ctoi}{$refstring} = $item;
  }
  $self->{_ctoi}{$refstring};
}

sub row_of {
  my $self = shift;
  ($self->coords_of(@_))[0];
}
sub col_of {
  my $self = shift;
  ($self->coords_of(@_))[1];
}

sub monthname {
  # Check/return month...returns name
  # Accepts 1-12, or Jan..Dec
  my $self = shift;
  return $self->month unless @_;
  my(@mn, $month);
  my $months   = $self->locale_months;
  my $monthnum = $self->locale_monthnums;
  my $minmatch = $self->locale_minmatch;
  my $mmpat    = $self->locale_minmatch_pattern;
  
  foreach $month (@_) {
    if ($month =~ /^\d+$/) {
      $month >= 1 && $month <= 12 || return 0;  
      push(@mn,$months->[$month-1]);
    }
    else {
      if (exists $monthnum->{$month}) {
        push(@mn,$month);
      }
      else {
        # Make one last attempt
        if ($month =~ /^($mmpat)/) {
          push(@mn,$minmatch->{$1});
        }
        else {
          return undef;
        }
      }
    }
  }
  $#mn > 0 ? @mn : $mn[0];
}

sub monthnum {
  # Check/return month, returns number
  # Accepts 1-12, or Jan..Dec
  my $self = shift;
  my $monthnum = $self->locale_monthnums;
  my @mn;
  push(@mn,map(exists $monthnum->{$_} ?
               $monthnum->{$_}+1 : undef,$self->monthname(@_)));
  $#mn > 0 ? @mn : $mn[0];
}

sub dayname {
  # Check/return day...returns name
  # Accepts 1..7, or Su..Sa
  my $self = shift;
  @_ || croak "Day must be provided";
  my(@dn, $day);
  my $days = $self->locale_days;
  my $daynum = $self->locale_daynums;
  foreach $day (@_) {
    if ($day =~ /^\d+$/) {
      $day >= 1 && $day <= 7 || return undef;
      # week_begin is at least 1, so skew is automatic
      push(@dn,$days->[($day - 1 + $self->_week_begin - 1) % 8]);
    }
    else {
      $day = ucfirst(lc($day));
      if (exists $daynum->{$day}) {
        push(@dn,$day);
      }
      else {
        return undef;
      }
    }
  }
  $#dn > 0 ? @dn : $dn[0];
}

sub daynum {
  # Check/return day number 1..7, returns number
  # Accepts 1..7, or Su..Sa
  my $self = shift;
  my $daynum = $self->locale_daynums;
  my @dn;
  push(@dn,map(exists $daynum->{$_} ?
               $daynum->{$_}+1 : undef,$self->dayname(@_)));
  $#dn > 0 ? @dn : $dn[0];
}

##################
# Tests-n-checks #
##################

sub _dayheadcheck {
  # Test day head names
  my $self = shift;
  my $name = shift || croak "Name missing";
  return undef if $name =~ /^\d+$/;
  $self->daynum($name);
}

sub _daycheck {
  # Check if an item is a day of the month (1..31)
  my $self = shift;
  my $item = shift || croak "Item required";
  # Can't just invert _headcheck because coords_of() needs
  # _daycheck, and _headcheck uses coords_of()
  $item =~ /^\d{1,2}$/ && $item <= 31;
}
sub _headcheck {
  # Check if an item is a header
  !_daycheck(@_);
}
sub _daygridcheck {
  # Check if coords are in DOM area
  # (Beware use by item_at())
  !_headgridcheck(@_);
}
sub _headgridcheck {
  # Check if coords are in the header area
  # (This can't be used by item_at())
  my $self = shift;
  my($row,$col) = @_;
  $row && $col || croak "Row and Col required";
  my $skew = 0;
  ++$skew if $self->_head_my;
  ++$skew if $self->_head_dow;
  $row > $skew ? 0 : $self->item_at($row,$col);
}

############################
# Constructors/Destructors #
############################

sub new {
  my $that = shift;
  my $class = ref($that) || $that;

  my(%attrs,%tattrs);
  my($attr,$val);
  while ($_ = shift) {
    $val = shift;
    $attr = lc($_);
    if (exists $COMPLEX_ATTRS{$attr}) {
      $attrs{$attr} = $val;
    } 
    else {
      $tattrs{$_} = $val;
    }
  }

  my $self = HTML::ElementTable->new(%tattrs);
  bless $self,$class;

  # Complex attributes initialization
  grep($self->{_cattrs}{$_} = $COMPLEX_ATTRS{$_}, keys %COMPLEX_ATTRS);

  # Locale initialization
  my $locale      = $attrs{locale}      || $self->{_cattrs}{locale};
  my $full_days   = $attrs{full_days}   || $self->{_cattrs}{full_days};
  my $full_months = $attrs{full_months} || $self->{_cattrs}{full_months};
  $self->{_cattrs}{loc} = HTML::CalendarMonth::Locale->new(
    id          => $locale,
    full_days   => $full_days,
    full_months => $full_months,
  ) or croak "Problem creating locale $locale\n";

  # Enable blank cell fill so BGCOLOR shows up by default
  $self->blank_fill(1);

  my $month = $attrs{month};
  my $year  = $attrs{year};
  if (!$month || !$year) {
    my ($nmonth,$nyear) = (localtime(time))[4,5];
    ++$nmonth; $nyear += 1900;
    ($month = $nmonth) unless $month;
    ($year  = $nyear)  unless $year;
  }
  # Make sure they're numeric (trim leading 0's, etc)
  $month += 0;
  $year += 0;

  # Process special calendar attributes
  while (($attr,$val) = each %attrs) {
    next if $attr eq 'month' || $attr eq 'year';
    $self->attr($attr,$val);
  }

  # For now, this is the only time this will every happen
  # for this object.  It is now 'initialized'.
  $self->_date($month,$year);

  $self;
}

AUTOLOAD {
  # Automatically pass along simple attr methods
  my $self = shift;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;           # Strip fully-qualified portion
  return if $name eq 'DESTROY';
  my($attr) = $name =~ /^_(.*)/;
  croak "Invalid method '$name'" unless $self->_complex_attr($attr);
  $self->_cattr($attr,@_);
}

# Go forth and prosper.
1;
__END__

=head1 NAME

HTML::CalendarMonth - Perl extension for generating and manipulating HTML calendar months

=head1 SYNOPSIS

 use HTML::CalendarMonth;
 use HTML::AsSubs;

 # Using HTML::AsSubs
 $c = HTML::CalendarMonth->new( month => 3, year => 69 );
 $c->item($c->year, $c->month)->attr(bgcolor => 'wheat');
 $c->item($c->year, $c->month)->wrap_content(font({size => '+2'}));
 $c->item(12, 16, 28)->wrap_content(strong());
 print $c->as_HTML;

 # Using regular HTML::Element creation
 $c2 = HTML::CalendarMonth->new( month => 8, year => 79 );
 $c2->item($c2->year, $c2->month)->attr(bgcolor => 'wheat');
 $f = HTML::Element->new('font', size => '+2');
 $c2->item($c2->year, $c2->month)->wrap_content($f);
 $c2->item_daycol('Su', 'Sa')->attr(bgcolor => 'cyan');
 print $c2->as_HTML;

 # Full locale support via DateTime::Locale
 $c3 HTML::CalendarMonth->new( month => 8, year => 79, locale => 'fr' );
 print $c3->as_HTML

=head1 DESCRIPTION

HTML::CalendarMonth is a subclass of HTML::ElementTable. See
L<HTML::ElementTable(3)> for how that class works, for it affects this
module on many levels. Like HTML::ElementTable, HTML::CalendarMonth
behaves as if it were an HTML::ElementSuper, which is a regular
HTML::Element with methods added to easily manipulate the appearance of
the HTML table containing the calendar.

The primary interaction with HTML::CalendarMonth is through I<items>. An
I<item> is merely a symbol that represents the content of the cell of
interest within the calendar. For instance, the element representing the
14th day of the month would be returned by C<$c-E<gt>item(14)>.
Similarly, the element representing the header for Monday would be
returned by C<$c-E<gt>item('Mo')>. If the year happened to by 1984, then
C<$c-E<gt>item(1984)> would return the cell representing the year. Since
years and particular months change frequently, it is probably more
useful to take advantage of the C<month()> and C<year()> methods, which
return the respective item symbol for the current calendar. In the prior
example, using 1984, the following is equivalent: C<$c-E<gt>item($c-
E<gt>year())>.

Multiple cells of the calendar can be manipulated as if they were a
single element. For instance, C<$c-E<gt>item(15)-E<gt>attr(bgcolor
=E<gt> 'cyan')> would alter the background color of the cell
representing the 15th. By the same token, C<$c-E<gt>item(15, 16, 17,
23)-E<gt>attr(bgcolor =E<gt> 'cyan')> would do the same thing for all
cells containing the item symbols passed to the C<item()> method.

The calendar structure is still nothing more than a table structure; the
same table structure provided by the HTML::ElementTable class. In
addition to the I<item> based access methods above, calendar cells can
still be accessed using row and column grid coordinates using the
C<cell()> method provided by the table class. All coordinate-based
methods in the table class are accessible to the calendar class.

The module includes support for week-of-the-year numbering, arbitrary
1st day of the week definitions, and aliasing so that you can express
any element in any language HTML can handle.

Dates that are beyond the range of the built-in time functions of perl
are handled either by the 'cal' command, Date::Calc, or Date::Manip. The
presence of any one of these utilities and modules will suffice for
these far flung date calculations. If you want to use week-of-year
numbering, then either one of the date modules is required.

Full locale support is offered via DateTime::Locale. For a full list of
supported locale id's, look at HTML::CalendarMonth::Locale->locales() or
DateTime::Locale->ids().

=head1 METHODS

All arguments appearing in [brackets] are optional, and do not represent
anonymous array references.

=over

B<Constructor>

=item new()

With no arguments, the constructor will return a calendar object
representing the current month with a default appearance. The initial
configuration of the calendar is controlled by special attributes. Non-
calendar related attributes are passed along to HTML::ElementTable. Any
non-table related attributes left after that are passed to HTML::Element
while constructing the E<lt>tableE<gt> tag. See L<HTML::ElementTable> if
you are interested in attributes that can be passed along to that class.

Special Attributes for HTML::CalendarMonth:

=over

=item month

1-12, or Jan-Dec.  Defaults to current month.

=item year

Four digit representation. Defaults to current year.

=item head_m

Specifies whether to display the month header. Default 1.

=item head_y 

Specifies whether to display the year header. Default 1.

=item head_dow

Specifies whether to display days of the week header. Default 1.

=item locale

Specifies a locale in which to render the calendar. Default is 'en_US'.
See L<HTML::CalendarMonth::Locale> for more information. If for some
reason you prefer to use different labels than those provided by
C<locale>, see the C<alias> attribute below.

=item full_days

Specifies whether or not to use full day names or their abbreviated
names. Default is 0, use abbreviated names.

=item full_months

Specifies whether or not to use full month names or their abbriviated
names. Default is 1, use full names.

=item alias

Takes a hash reference mapping labels provided by C<locale> to any
custom label you prefer. Lookups, such as C<day('Sun')>, will still use
the locale string, but when the calendar is rendered the aliased value
will appear.

=item head_week

Specifies whether to display the week-of-year numbering. Default 0.

=item week_begin

Specify first day of the week, which can be 1..7, starting with Sunday.
Defaults to 1, or Sunday. In order to specify Monday, set this to 2,
and so on.

=item row_offset

Specifies the offset of the first calendar row within the table
containing the calendar. This is 0 by default, making the first row of
the table the same as the first row of the calendar.

=item col_offset

Specifies the offset of the first calendar column within the table
containing the calendar. This is 0 by default, making the first column
of the table the same as the first row of the calendar.

=item historic

This option is ignored for dates that do not exceed the range of the built-
in perl time functions. For dates that B<do> exceed these ranges, this
option specifies the default calculation method. When set, if the 'cal'
utility is available on your system, that will be used rather than the
Date::Calc or Date::Manip modules. This can be an issue since the date
modules blindly extrapolate the Gregorian calendar, whereas 'cal' takes
some of these quirks into account. If 'cal' is not available on your
system, this attribute is meaningless. Defaults to 1.

=back

=back

B<Item Query Methods>

The following methods return lists of item symbols that are related in
some way to the provided list of items. The returned symbols may then
be used as arguments to the glob methods detailed further below. When
these methods deal with 'rows' and 'columns', they are only concerned
with the cells in the calendar -- not the cells that might be present
in the surrounding table if you have extended it. If you have not set
row or column offsets, or extended the span of the containing table,
then these rows and columns are functionally equivalent to the table
rows and columns.

=over

=item row_items(item1, [item2, ...])

Returns all item symbols in rows shared by the provided item symbols.

=item col_items(item1, [item2, ...])

Returns all item symbols in columns shared by the provided item symbols.

=item daycol_items(col_item1, [col_item2, ...])

Same as col_items(), but the returned item symbols are limited to those
that are not header items (month, year, day-of-week).

=item row_of(item1, [item2, ...])

Returns the row numbers of rows containing the provided item symbols.

=item col_of(item1, [item2, ...])

Returns the column numbers of columns containing the provided
item symbols.

=item lastday()

Returns the number of the last day of the month.

=item dow1st()

Returns the column number for the first day of the month.

=item days()

Returns a list of all days of the month.

=item dayheaders()

Returns a list of all day headers (Su..Sa)

=item headers()

Returns a list of all headers (month, year, dayheaders)

=item items()

Returns a list of all item symbols in the calendar.

=item first_col()

Returns the number of the first column of the calendar. This could be
different from that of the surrounding table if the table was extended,
but otherwise should be identical.

=item last_col()

Returns the number of the last column of the calendar. This could be
different from that of the surrounding table if the table was extended,
but should otherwise be identical.

=item first_row()

Returns the number of the first row of the calendar. This could be
different from that of the surrounding table if offsets were made.

=item first_week_row()

Returns the number of the first row of the calendar containing day items
(ie, the first week). This could vary depending on table offsets and
header modes.

=item last_row()

Returns the number of the last row of the calendar. This could be
different from that of the surrounding table if the table was extended,
but should otherwise be identical.

=back

B<Glob Methods>

Glob methods return references that are functionally equivalent to an
individual calendar cell. Mostly, they provide item based analogues to
the glob methods provided in HTML::ElementTable. In methods dealing with
rows, columns, and boxes, the globs include empty calendar cells (which
would otherwise need to be accessed through native HTML::ElementTable
methods). The row and column numbers returned by the item methods above
are compatible with the grid based methods in HTML::ElementTable.

For details on how these globs work, check out L<HTML::ElementTable> and
L<HTML::ElementGlob>.

=over

=item item(item1, [item2, ...])

Returns all cells containing the provided item symbols.

=item item_row(item1, [item2, ...])

Returns all cells in all rows occupied by the provided item symbols.

=item item_col(item1, [item2, ...])

Returns all cells in all columns occupied by the provided item symbols.

=item item_daycol(item1, [item2, ...])

Same as item_col(), except limits the cells to non header cells.

=item item_box(item1a, item1b, [item2a, item2b, ...])

Returns all cells in the boxes defined by the item pairs provided.

=item allheaders()

Returns all header cells.

=item alldays()

Returns all non header cells, including empty cells.

=item all()

Returns all cells in the calendar, including empty cells.

=back

B<Transformation Methods>

The following methods provide ways of translating between various item
symbols, coordinates, and other representations.

=over

=item coords_of(item)

Returns the row and column of the provided item symbol, for use with the
grid based methods in HTML::ElementTable.

=item item_at(row,column)

Returns the item symbol of the item at the provided coordinates, for use
with the item based methods of HTML::CalendarMonth.

=item monthname(monthnum)

Returns the name (item symbol) of the month number provided, where
I<monthnum> can be 1..12.

=item monthnum(monthname)

Returns the number (1..12) of the month name provided. Only a minimal
case-insensitive match on the month name is necessary; the proper item
symbol for the month will be determined from this match.

=item dayname(daynum)

Returns the name (item symbol) of the day of week header for a number of
a day of the week, where I<daynum> is 1..7.

=item daynum(dayname)

Returns the number of the day of the week given the symbolic name for
that day (Su..Sa).

=item daytime(day)

Returns the number in seconds since the epoch for a given day. The day
must be present in the current calendar.

=back

=head1 Notes On Dates And Spatial Relationships

One of the nice things about having a calendar represented as a table
accessible with grid coordinates is that some of the trickier date
calculations become trivial. You can use packages such as I<Date::Manip>
or I<Date::Calc> for these sort of things, but the algorithms are often
derived from a common human activity: looking at a calendar on a wall.
Say, for instance, that you are interested in "the third Friday of every
month". If you are using a calendar with Sunday as the first day of the
week, then Fridays will always be in column 5, starting from 0.
Likewise, due to the fact that supressed headers are merely I<masked> in
the actual table, the first row with dates in a calendar structure will
B<always> be 2, even if the month, year, or day headers are disabled.
The third friday of every month therefore becomes C<$c-E<gt>cell(2,5)>,
regardless of the particular month. Likewise, the "nth dayname/week of
the month" can always be mapped to table coordinates.

The particulars of this grid mapping are affected if you have redefined
what the first day of the week is, or if you have tweaked the table
beyond the bounds of the calendar itself. There are methods that can
help under these circumstances, though. For instance, in our example
where we are interested in the 3rd Friday of the month, the row number
is accessed with C<$c-E<gt>first_week_row + 2>, whereas the column
number could be derived with C<$c-E<gt>last_col - 1>.

=head1 REQUIRES

HTML::ElementTable

=head1 OPTIONAL

Date::Calc or Date::Manip (only if you want week-of-year numbering or
non-contemporary dates on a system without the I<cal> command)

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998-2005 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

A useful page of examples can be found at
http://www.mojotoad.com/sisk/projects/HTML-CalendarMonth.

For information on iso639 standards for abbreviations for language
names, see http://www.loc.gov/standards/iso639-2/englangn.html

HTML::ElementTable(3), HTML::Element(3), perl(1)

=cut
