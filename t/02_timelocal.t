#!/usr/bin/perl

use strict;

my($test_count, $method);
BEGIN { $test_count = 17 ; $method = 'Time::Local' }

use Test::More tests => $test_count;

use FindBin;
use lib $FindBin::RealBin;

use testload;

SKIP: {
  eval "use $method";
  skip("$method not installed", $test_count) if $@;
  check_datetool($method);
  check_basic_with_datetool($method);
}
