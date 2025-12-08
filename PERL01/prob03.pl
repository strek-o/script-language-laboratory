#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;

if (@ARGV != 3) {
    die "Usage:\n...\n...\n...\n";
}

my ($file0, $file1, $file2) = @ARGV;

sub read_file {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot open file: $!\n";

    my @matrix;

    while (my $line = <$fh>) {
        my @row = split(/\s+/, $line);
        push @matrix, \@row;
    }

    close($fh);
    return \@matrix;
}

my $A = read_file($file0);
my $B = read_file($file1);

my $n = @$A;
my $m = @{$A->[0]};
my $p = @{$B->[0]};

my @C;
for my $i (0 .. $n - 1) {
    for my $j (0 .. $p - 1) {
        my $sum = 0;
        for my $k (0 .. $m - 1) {
            $sum += $A->[$i][$k] * $B->[$k][$j];
        }
        $C[$i][$j] = $sum;
    }
}


open my $out, '>', $file2 or die "Cannot open file: $!\n";

for my $i (0 .. $#C) {
    for my $j (0 .. $#{$C[$i]}) {
        if ($j == $#{$C[$i]}) {
            printf $out "%8.3f", $C[$i][$j];
        } else {
            printf $out "%8.3f ", $C[$i][$j];
        }
    }
    print $out "\n";
}

close($out);
