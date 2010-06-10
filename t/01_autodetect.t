#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my $test_count;
BEGIN { $test_count = bulk_count() + odd_count() }

use Test::More tests => $test_count;

check_bulk_with_datetool();
check_odd_with_datetool();
