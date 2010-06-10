#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my($test_count, $method);
BEGIN {
  $method = 'cal';
  $test_count = bulk_count() + odd_count() + 2;
}

use Test::More tests => $test_count;

SKIP: {
  my $CAL;
  chomp($CAL = `which cal`);
  skip("$method not installed", $test_count) unless -x $CAL;
  check_datetool($method);
  check_bulk_with_datetool($method);
  check_odd_with_datetool($method);
}
