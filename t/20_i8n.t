#!/usr/bin/perl

use strict;

use Test::More tests => 2;

use HTML::CalendarMonth;
use HTML::CalendarMonth::Locale;

my $basque;
eval join('', <DATA>);
die "Oops on eval: $@\n" if $@;

# i8n (use basque as example)
my @stoof = HTML::CalendarMonth::Locale->locales;
ok(@stoof > 20, 'i8n: locale ids retreived');
my($year, $month) = (2000, 12);
my $b = HTML::CalendarMonth->new(
  year       => $year,
  month      => $month,
  head_week  => 1,
  locale     => 'eu',
);
my $bstr = $b->as_HTML;
chomp($bstr);
cmp_ok($bstr, 'eq', $basque, "i8n: ($year/$month : Basque) using auto-detect");

__DATA__
$basque = '<table bgcolor="white" border=1 cellpadding=0 cellspacing=0><tr align="center"><td align="left" colspan=6>abendua</td><td align="center" colspan=2>2000</td></tr><tr align="center"><td align="center">ig</td><td align="center">al</td><td align="center">as</td><td align="center">az</td><td align="center">og</td><td align="center">or</td><td align="center">lr</td><td align="center">&nbsp; </td></tr><tr align="center"><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td><td align="center">2</td><td align="center">48</td></tr><tr align="center"><td align="center">3</td><td align="center">4</td><td align="center">5</td><td align="center">6</td><td align="center">7</td><td align="center">8</td><td align="center">9</td><td align="center">49</td></tr><tr align="center"><td align="center">10</td><td align="center">11</td><td align="center">12</td><td align="center">13</td><td align="center">14</td><td align="center">15</td><td align="center">16</td><td align="center">50</td></tr><tr align="center"><td align="center">17</td><td align="center">18</td><td align="center">19</td><td align="center">20</td><td align="center">21</td><td align="center">22</td><td align="center">23</td><td align="center">51</td></tr><tr align="center"><td align="center">24</td><td align="center">25</td><td align="center">26</td><td align="center">27</td><td align="center">28</td><td align="center">29</td><td align="center">30</td><td align="center">52</td></tr><tr align="center"><td align="center">31</td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td></tr></table>';
