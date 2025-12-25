#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;

use lib '.';
use Modul;

die "Usage:\n...\n...\n...\n"
    unless @ARGV == 4;

my ($xls, $csv, $n, $m) = @ARGV;

Modul::init($n, $m);
Modul::addReadXLS($xls);
Modul::saveCSV($csv);
