#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;

my $PATTERN = " AEIOZSLNCWRYTKMDPJUBGHFVXQ";
my $ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ ";

my $target = $ARGV[0] or die "No target file specified\n";
open my $fh, '<', $target or die $!;
local $/; 
my $text = <$fh>;
close $fh;

my %counts;
$counts{$_}++ for split //, $text;

my @cipher_sorted = sort { $counts{$b} <=> $counts{$a} } keys %counts;
my @pattern_sorted = split //, $PATTERN;

my %cipher_to_plain;
for my $i (0 .. $#cipher_sorted) {
    last if $i > $#pattern_sorted;
    $cipher_to_plain{$cipher_sorted[$i]} = $pattern_sorted[$i];
}

my %plain_to_cipher = reverse %cipher_to_plain;

my $output = "";
for my $char (split //, $ALPHABET) {
    my $found = $plain_to_cipher{$char};
    
    if (defined $found) {
        $output .= ($found eq ' ') ? '_' : $found;
    }
    else {
        $output .= "?";
    }
}

$output =~ s/ /_/g; 
print "$output\n";
