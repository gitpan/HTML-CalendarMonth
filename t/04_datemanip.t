#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my($test_count, $method);
BEGIN { $test_count = case_count() + 4 ; $method = 'Date::Manip' }

use Test::More tests => $test_count;

SKIP: {
  eval "use $method";
  skip("$method not installed", $test_count) if $@;
  check_datetool($method);
  check_basic_with_datetool($method);
  check_woy_with_datetool($method);
}
