#!/usr/bin/perl

use strict;

my($test_count, $method);
BEGIN { $test_count = 17 ; $method = 'cal' }

use Test::More tests => $test_count;

use FindBin;
use lib $FindBin::RealBin;

use testload;

SKIP: {
  my $CAL;
  chomp($CAL = `which cal`);
  skip("$method not installed", $test_count) unless -x $CAL;
  check_datetool($method);
  check_basic_with_datetool($method);
}
