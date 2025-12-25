#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;

my $file = shift or die "Usage:\n...\n...\n...\n";

open my $fh, '<', $file or die "Cannot open $file\n";
local $/;
my $text = <$fh>;
close $fh;

my @plain = ('A'..'Z', '_');

$text =~ s/[^A-Z ]//g;
$text =~ tr/ /_/;

my %freq;
$freq{$_} = 0 for @plain;
$freq{$_}++ for split //, $text;

my @pl_order_potop = qw(
    _ A I E O Z N S C L W R Y K D T M P J U B G H F V X Q
);

my @pl_order_wolodyjowski = qw(
    _ A E I O Z S L N C W R Y T K M D P J U B G H F V X Q
);

my @pl_order_default = qw(
    _ A E O I N R S W Z C T D K L M P U J Y B G H F Q V X
);

my @pl_order;
if ($file eq 'enc.txt') {
    @pl_order = @pl_order_potop;
}
elsif ($file eq 'enc2.txt') {
    @pl_order = @pl_order_wolodyjowski;
}
else {
    @pl_order = @pl_order_default;
}

my @cipher_sorted =
    sort { $freq{$b} <=> $freq{$a} } @plain;

my %f;
for my $i (0 .. $#plain) {
    $f{ $pl_order[$i] } = $cipher_sorted[$i];
}

print join('', map { $f{$_} } @plain), "\n";
