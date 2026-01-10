#!/bin/perl
# Author: Oliwier Strek

use strict;
use warnings;
use Getopt::Long;
use FindBin;
use File::Spec;

use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

my $module_loaded = 0;
eval {
    require Database;
    Database->import();
    $module_loaded = 1;
};

unless ($module_loaded) {
    die "Missing Database.pm module.\n";
}

my %ARGS;
GetOptions(
    "report" => \$ARGS{report},
    "cpu=f" => \$ARGS{cpu},
    "ram=f" => \$ARGS{ram},
    "disk=f" => \$ARGS{disk},
    "load=f" => \$ARGS{load},
    "verbose" => \$ARGS{verbose},
);

my $config = get_internal_config();

my $db_path = File::Spec->catfile($FindBin::Bin, '..', 'data', $config->{database}->{filename});

my $database = Database->new({
    db_path => $db_path,
    timeout => $config->{database}->{timeout_ms}
});

unless ($database->connect() && $database->initialize_schema()) {
    die "DB " . $database->get_error() . "\n";
}

if ($ARGS{report}) {
    run_report_mode($database);
} else {
    run_collection_mode($database, $config);
}

$database->disconnect();
exit 0;

sub get_internal_config {
    return {
        database => {
            filename => "metrics.db",
            retention_days => 14,
            timeout_ms => 5000
        },
        limits => {
            cpu_warning => 85.0,
            ram_warning => 90.0,
            disk_warning => 90.0,
            load_warning => 2.0
        }
    };
}

sub run_collection_mode {
    my ($db, $cfg) = @_;

    return unless defined $ARGS{cpu} && defined $ARGS{ram};

    my $limits = $cfg->{limits};

    if ($ARGS{cpu} >= $limits->{cpu_warning}) {
        print "High CPU usage: $ARGS{cpu}%\n";
    }
    if ($ARGS{ram} >= $limits->{ram_warning}) {
        print "High RAM usage: $ARGS{ram}%\n";
    }
    if ($ARGS{disk} >= $limits->{disk_warning}) {
        print "High Disk usage: $ARGS{disk}%\n";
    }
    if ($ARGS{load} >= $limits->{load_warning}) {
        print "High System Load: $ARGS{load}\n";
    }

    my $ok = $db->save_metric({
        cpu => $ARGS{cpu},
        ram => $ARGS{ram},
        disk => $ARGS{disk},
        load => $ARGS{load}
    });

    unless ($ok) {
        die "DB Write Error: " . $db->get_error() . "\n";
    }

    $db->prune_old_records($cfg->{database}->{retention_days});
}

sub run_report_mode {
    my $db = shift;
    my $data = $db->get_latest_report(10);

    unless ($data) {
        die "DB Read Error: " . $db->get_error() . "\n";
    }

    my $fmt_head = "%-30s | %6s | %6s | %6s | %6s\n";
    my $fmt_data = "%-30s | %6.1f | %6.1f | %6.1f | %6.2f\n";
    my $border = "=" x 70 . "\n";
    my $line = "-" x 70 . "\n";

    print "\n$border";
    printf $fmt_head, "TIMESTAMP", "CPU%", "RAM%", "DISK%", "LOAD";
    print $line;

    foreach my $row (@$data) {
        printf $fmt_data,
            scalar localtime($row->{timestamp}),
            $row->{cpu_usage},
            $row->{ram_usage},
            $row->{disk_usage},
            $row->{load_avg};
    }
    print "$border\n";
}
