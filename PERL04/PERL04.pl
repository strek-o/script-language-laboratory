#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;
use DBI;

my $db_file = "database.db";

unlink $db_file if -f $db_file;

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$db_file",
    "",
    "",
    { RaiseError => 1, AutoCommit => 1 }
);

foreach my $csv_file (@ARGV) {

    open my $fh, "<", $csv_file or die "Cannot open file $csv_file\n";

    my $table = $csv_file;
    $table =~ s/\.csv$//;

    my $header = <$fh>;
    chomp $header;
    my @cols = split /,/, $header;

    my @defs;
    for my $c (@cols) {
        if ($c eq 'id') {
            push @defs, "$c INTEGER UNIQUE";
        }
        elsif ($c =~ /date/i) {
            push @defs, "$c DATE";
        }
        elsif ($c =~ /^i/) {
            push @defs, "$c INTEGER";
        }
        else {
            push @defs, "$c TEXT";
        }
    }

    my $create_sql = "CREATE TABLE $table (" . join(", ", @defs) . ")";
    $dbh->do($create_sql);

    my $placeholders = join(",", ("?") x @cols);
    my $insert_sql = "INSERT INTO $table VALUES ($placeholders)";
    my $sth = $dbh->prepare($insert_sql);

    while (<$fh>) {
        chomp;
        my @values = split /,/;
        $sth->execute(@values);
    }

    close $fh;
}

my $query = qq{
SELECT
    e.name,
    e.surname,
    u.email,
    SUM(s.salary) AS total_salary
FROM employees e
JOIN user_data u ON e.id = u.employee_id
JOIN salaries s ON e.id = s.employee_id
GROUP BY e.id
ORDER BY total_salary DESC, u.email ASC
LIMIT 4
};

my $sth = $dbh->prepare($query);
$sth->execute();

print "Top 4 employees with highest total salaries:\n";
print "----------------------------------------\n";

while (my $row = $sth->fetchrow_arrayref) {
    print join(" | ", @$row), "\n";
}

$dbh->disconnect;
