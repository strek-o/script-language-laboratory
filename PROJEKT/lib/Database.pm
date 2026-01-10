package Database;
# Author: Oliwier Strek

use strict;
use warnings;
use DBI;

sub new {
    my ($class, $args) = @_;

    unless (defined $args && ref($args) eq 'HASH') {
        print STDERR "Database Error: Arguments must be a hash.\n";
        return undef;
    }

    my $self = {
        db_path => $args->{db_path} || 'default.db',
        timeout => $args->{timeout} || 3000,
        dbh => undef,
        last_error => '',
        is_connected => 0,
    };

    bless $self, $class;
    return $self;
}

sub connect {
    my $self = shift;

    return 1 if $self->{is_connected} && defined $self->{dbh} && $self->{dbh}->ping;

    $self->{last_error} = undef;

    eval {
        my $dsn = "dbi:SQLite:dbname=" . $self->{db_path};
        $self->{dbh} = DBI->connect($dsn, "", "", {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
            sqlite_unicode => 1,
            sqlite_use_immediate_transaction => 1,
        });
        
        $self->{dbh}->do("PRAGMA busy_timeout = " . int($self->{timeout}));
    };

    if ($@) {
        $self->{last_error} = "DB Connection Failed: $@";
        $self->{is_connected} = 0;
        return 0;
    }

    $self->{is_connected} = 1;
    return 1;
}

sub disconnect {
    my $self = shift;
    if ($self->{dbh}) {
        eval { $self->{dbh}->disconnect(); };
        $self->{dbh} = undef;
    }
    $self->{is_connected} = 0;
    return 1;
}

sub initialize_schema {
    my $self = shift;
    return 0 unless $self->_check_connection();

    my @queries = (
        qq{
            CREATE TABLE IF NOT EXISTS metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp INTEGER NOT NULL,
                cpu_usage REAL,
                ram_usage REAL,
                disk_usage REAL,
                load_avg REAL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        },
        qq{ CREATE INDEX IF NOT EXISTS idx_ts ON metrics(timestamp) }
    );

    foreach my $sql (@queries) {
        eval {
            $self->{dbh}->do($sql);
        };
        if ($@) {
            $self->{last_error} = "Schema Init Error: $@";
            return 0;
        }
    }
    return 1;
}

sub save_metric {
    my ($self, $data) = @_;
    
    return 0 unless $self->_check_connection();

    unless (defined $data->{cpu} && defined $data->{ram}) {
        $self->{last_error} = "Missing required metric fields (cpu/ram)";
        return 0;
    }

    my $sql = qq{
        INSERT INTO metrics (timestamp, cpu_usage, ram_usage, disk_usage, load_avg)
        VALUES (?, ?, ?, ?, ?)
    };

    my $result = 0;
    eval {
        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute(
            time(),
            $data->{cpu},
            $data->{ram},
            $data->{disk} || 0.0,
            $data->{load} || 0.0
        );
        $result = 1;
    };

    if ($@) {
        $self->{last_error} = "Insert Failed: $@";
        return 0;
    }

    return $result;
}

sub prune_old_records {
    my ($self, $days) = @_;
    return 0 unless $self->_check_connection();
    
    $days = 30 unless defined $days && $days > 0;
    
    my $cutoff = time() - ($days * 24 * 60 * 60);
    my $deleted = 0;

    eval {
        my $sth = $self->{dbh}->prepare("DELETE FROM metrics WHERE timestamp < ?");
        $deleted = $sth->execute($cutoff);
    };

    if ($@) {
        $self->{last_error} = "Prune Failed: $@";
        return -1;
    }

    return $deleted;
}

sub get_latest_report {
    my ($self, $limit) = @_;
    return [] unless $self->_check_connection();
    $limit = 10 unless defined $limit;

    my $rows = [];
    eval {
        my $sth = $self->{dbh}->prepare("SELECT * FROM metrics ORDER BY timestamp DESC LIMIT ?");
        $sth->execute($limit);
        while (my $row = $sth->fetchrow_hashref) {
            push @$rows, $row;
        }
    };
    
    if ($@) {
        $self->{last_error} = "Fetch Failed: $@";
        return undef;
    }
    
    return $rows;
}

sub get_error {
    my $self = shift;
    return $self->{last_error};
}

sub _check_connection {
    my $self = shift;
    unless ($self->{is_connected} && defined $self->{dbh}) {
        $self->{last_error} = "No active DB connection.";
        return 0;
    }
    return 1;
}

1;
