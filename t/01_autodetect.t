#!/usr/bin/perl

use strict;

my($test_count, $method);
BEGIN { $test_count = 15 ; $method = '' }

use Test::More tests => $test_count;

use FindBin;
use lib $FindBin::RealBin;

use testload;

check_basic_with_datetool($method);
