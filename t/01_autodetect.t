#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my($test_count, $method);
BEGIN { $test_count = case_count() ; $method = '' }

use Test::More tests => $test_count;

check_basic_with_datetool($method);
