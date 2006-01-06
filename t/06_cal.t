#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my($test_count, $method);
BEGIN { $test_count = case_count() + 2 ; $method = 'cal' }

use Test::More tests => $test_count;

SKIP: {
  my $CAL;
  chomp($CAL = `which cal`);
  skip("$method not installed", $test_count) unless -x $CAL;
  check_datetool($method);
  check_basic_with_datetool($method);
}
