package Modul;
# Author: Oliwier Strek

use strict;
use warnings;
use Spreadsheet::ParseXLSX;
use Text::CSV;

my @array; 
my ($rows, $cols);

sub init {
    my ($n, $m) = @_;
    $rows = $n;
    $cols = $m;

    @array = ();
    for my $i (0 .. $rows - 1) {
        for my $j (0 .. $cols - 1) {
            $array[$i][$j] = 0;
        }
    }
}

sub addReadXLS {
    my ($filename) = @_;

    my $parser = Spreadsheet::ParseXLSX->new();
    my $workbook = $parser->parse($filename)
        or die "Cannot open file: $filename\n";

    for my $sheet ($workbook->worksheets()) {
        for my $row (0 .. $rows - 1) {
            for my $col (0 .. $cols - 1) {
                my $cell = $sheet->get_cell($row, $col);
                next unless defined $cell;

                my $val = $cell->unformatted();
                $val = 0 unless defined $val;
                $array[$row][$col] += $val;
            }
        }
    }
}

sub saveCSV {
    my ($filename) = @_;

    open my $fh, '>', $filename
        or die "Cannot save file: $filename\n";

    my $csv = Text::CSV->new({
        sep_char => ';',
        quote_char => undef,
        escape_char => undef,
    });

    for my $row (@array) {
        $csv->combine(@$row);
        print $fh $csv->string(), "\n";
    }

    close $fh;
}

1;
