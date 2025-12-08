#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;

my %zwierzeta;

while (my $linia = <STDIN>) {
    chomp $linia;
    next if $linia eq '';

    if (exists $zwierzeta{$linia}) {
        $zwierzeta{$linia}++;
    }
    else {
        $zwierzeta{$linia} = 1;
    }
}

my @sort = sort keys %zwierzeta;

foreach my $z (@sort) {
    print $z, " ", $zwierzeta{$z}, "\n";
}
