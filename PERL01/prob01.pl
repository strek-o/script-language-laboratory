#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;

my @zwierzeta = ("kot", "pies", "papuga", "kanarek", "ryba");

print $zwierzeta[0], "\n";

print scalar @zwierzeta, "\n";

$zwierzeta[1] = "kanarek";

push @zwierzeta, "żaba";

print scalar @zwierzeta, "\n";

pop @zwierzeta;

print scalar @zwierzeta, "\n";

foreach my $z (@zwierzeta) {
    print $z, "\n";
}

for (my $i = 0; $i < @zwierzeta; $i++) {
    print $i, " ", $zwierzeta[$i], "\n";
}

foreach my $z (@zwierzeta[1..3]){
    print $z, "\n";
}
