package HTML::CalendarMonth::DateTool::Cal;

# Interface to unix 'cal' command

use strict;
use Carp;

use vars qw(@ISA $VERSION);

@ISA = qw(HTML::CalendarMonth::DateTool);

$VERSION = '0.01';

use Time::Local;

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  my $cmd = $self->cal_cmd or croak "cal command not found\n";

  my @cal = grep(!/^\s*$/,`$cmd $month $year`);
  chomp @cal;
  my @days     = grep(/\d+/,split(/\s+/,$cal[2]));
  my $dow1st   = 6 - $#days;
  my($lastday) = $cal[$#cal] =~ /(\d+)\s*$/;
  # With dow1st and lastday, one builds a calendar sequentially.
  # Historically, in particular Sep 1752, days have been skipped. Here's
  # the chance to catch that.
  $self->skips(undef);
  if ($month == 9 && $year == 1752) {
    my %skips;
    grep(++$skips{$_}, 3 .. 13);
    $self->skips(\%skips);
  }
  ($dow1st, $lastday);
}

1;
