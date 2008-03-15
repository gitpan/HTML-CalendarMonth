#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

use Test::More tests => 2;

use HTML::CalendarMonth;
use HTML::CalendarMonth::Locale;

my $zulu;
eval do { local $/; <DATA> };
die "Oops on eval: $@\n" if $@;
$zulu = dq_nums($zulu);

# i8n (use zulu as example)
my @stoof = HTML::CalendarMonth::Locale->locales;
ok(@stoof > 20, 'i8n: locale ids retreived');
my($year, $month) = (2008, 3);
my $b = HTML::CalendarMonth->new(
  year      => $year,
  month     => $month,
  locale    => 'zu',
);
my $bstr = dq_nums($b->as_HTML);
chomp($bstr);
cmp_ok($bstr, 'eq', $zulu, "i8n: ($year/$month : Zulu) using auto-detect");

__DATA__
$zulu = '<table bgcolor="white" border="1" cellpadding="0" cellspacing="0"><tr align="center"><td align="left" colspan="5">Mashi</td><td align="center" colspan="2">2008</td></tr><tr align="center"><td align="center">Son</td><td align="center">Mso</td><td align="center">Bil</td><td align="center">Tha</td><td align="center">Sin</td><td align="center">Hla</td><td align="center">Mgq</td></tr><tr align="center"><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">1</td></tr><tr align="center"><td align="center">2</td><td align="center">3</td><td align="center">4</td><td align="center">5</td><td align="center">6</td><td align="center">7</td><td align="center">8</td></tr><tr align="center"><td align="center">9</td><td align="center">10</td><td align="center">11</td><td align="center">12</td><td align="center">13</td><td align="center">14</td><td align="center">15</td></tr><tr align="center"><td align="center">16</td><td align="center">17</td><td align="center">18</td><td align="center">19</td><td align="center">20</td><td align="center">21</td><td align="center">22</td></tr><tr align="center"><td align="center">23</td><td align="center">24</td><td align="center">25</td><td align="center">26</td><td align="center">27</td><td align="center">28</td><td align="center">29</td></tr><tr align="center"><td align="center">30</td><td align="center">31</td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td><td align="center">&nbsp; </td></tr></table>'
