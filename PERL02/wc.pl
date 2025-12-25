#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;
use Getopt::Long;

my %opt;
GetOptions(
    'c' => \$opt{c},
    'm' => \$opt{m},
    'l' => \$opt{l},
    'w' => \$opt{w},
    'p' => \$opt{p},
    'i' => \$opt{i},
);

my $file = @ARGV ? $ARGV[-1] : '-';

my $text = '';
if ($file eq '-') {
    local $/;
    $text = <STDIN>;
} else {
    open my $fh, '<', $file or die "Cannot open $file\n";
    local $/;
    $text = <$fh>;
    close $fh;
}

my $bytes = length($text);
my $lines = () = $text =~ /\n/g;
my $chars = length($text);
my @words = split(/[ \t\r\n]+/, $text);
@words = grep { $_ ne '' } @words;
my $words_count = scalar @words;

if ($opt{c}) { print "$bytes $file\n"; }
if ($opt{m}) { print "$chars $file\n"; }
if ($opt{l}) { print "$lines $file\n"; }
if ($opt{w}) { print "$words_count $file\n"; }

if ($opt{p}) {
    my %freq;

    for my $w (@words) {
        my $key = $w;
        $key = lc $key if $opt{i};
        $freq{$key}++;
    }

    my @entries;
    for my $w (keys %freq) {
        my $printed = $w;
        $printed =~ s/[^a-zA-Z]/?/g;

        push @entries, {
            printed => $printed,
            count => $freq{$w},
        };
    }

    my @sorted = sort {
           $b->{count} <=> $a->{count}
        || $a->{printed} cmp $b->{printed}
    } @entries;

    for my $i (0..9) {
        last if $i > $#sorted;
        print "$sorted[$i]{printed} $sorted[$i]{count}\n";
    }
}
