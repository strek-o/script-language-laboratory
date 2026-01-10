#!/bin/bash
# Author: Oliwier Strek

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PERL_SOURCE="$SCRIPT_DIR/reporter.pl"
DATA_DIR="$PROJECT_ROOT/data"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/metrics.log"

VERBOSE=0

log() {
	local level="$1"
	local msg="$2"
	local timestamp
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")

	local tag="[$level]"
	local tag_padded
	tag_padded=$(printf "%-8s" "$tag")
	local log_entry="[$timestamp] ${tag_padded}${msg}"

	if [[ -d "$LOG_DIR" && -w "$LOG_DIR" ]]; then
		echo "$log_entry" >>"$LOG_FILE"
	fi

	case "$level" in
	"INFO")
		[[ $VERBOSE -eq 1 ]] && echo "${tag_padded}${msg}"
		;;
	"OK")
		echo "${tag_padded}${msg}"
		;;
	"WARN")
		echo "${tag_padded}${msg}"
		;;
	"ERROR")
		echo "${tag_padded}${msg}" >&2
		;;
	*)
		echo "$msg"
		;;
	esac
}

check_dependencies() {
	log "INFO" "Verifying libraries..."

	if ! command -v perl &>/dev/null; then
		log "ERROR" "Perl interpreter not found."
		exit 1
	fi

	local missing=0
	perl -MDBI -e 1 &>/dev/null || missing=1
	perl -MDBD::SQLite -e 1 &>/dev/null || missing=1

	if [[ $missing -eq 1 ]]; then
		log "ERROR" "Missing required Perl dependencies."
		echo -e "\nPlease install required modules:"
		echo -e "\tsudo apt update && sudo apt install -y libdbd-sqlite3-perl\n"
		exit 1
	fi
}

setup_directories() {
	for dir in "$LOG_DIR" "$DATA_DIR"; do
		if [[ ! -d "$dir" ]]; then
			mkdir -p "$dir" || {
				log "ERROR" "Failed to create directory $dir."
				exit 1
			}
		fi
	done
}

calculate_percent() {
	awk "BEGIN {printf \"%.2f\", ($1 / $2) * 100}" 2>/dev/null || echo "0.0"
}

get_cpu() {
	local stats_1=($(grep '^cpu ' /proc/stat))
	sleep 1
	local stats_2=($(grep '^cpu ' /proc/stat))

	local ticks_1=0
	local ticks_2=0

	local i
	for i in {1..7}; do
		ticks_1=$((ticks_1 + ${stats_1[$i]}))
		ticks_2=$((ticks_2 + ${stats_2[$i]}))
	done

	local idle_1=${stats_1[4]}
	local idle_2=${stats_2[4]}

	local total_period=$((ticks_2 - ticks_1))
	local total_idle=$((idle_2 - idle_1))
	local total_active=$((total_period - total_idle))

	if [[ $total_period -eq 0 ]]; then
		echo "0.0"
	else
		calculate_percent "$total_active" "$total_period"
	fi
}

get_ram() {
	local t a f b c
	t=$(grep 'MemTotal' /proc/meminfo | awk '{print $2}')
	a=$(grep 'MemAvailable' /proc/meminfo | awk '{print $2}')
	if [[ -z "$a" ]]; then
		f=$(grep 'MemFree' /proc/meminfo | awk '{print $2}')
		b=$(grep 'Buffers' /proc/meminfo | awk '{print $2}')
		c=$(grep '^Cached' /proc/meminfo | awk '{print $2}')
		a=$((f + b + c))
	fi
	local na=$((t - a))
	calculate_percent "$na" "$t"
}

get_disk() {
	df -P / | awk 'NR==2 {print $5}' | tr -d '%'
}

get_load() {
	awk '{print $1}' /proc/loadavg
}

usage() {
	cat <<EOF

System Resource Monitor
    This tool gathers essential system metrics (CPU usage, RAM usage, 
    Disk space, and Load Average) and persists them into a local SQLite 
    database.

Usage: ./monitor.sh [OPTIONS]
  -r, --report    Display database report
  -v, --verbose   Enable verbose mode (live logs)
  -h, --help      Show this help message

EOF
	exit 0
}

MODE="COLLECT"

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		usage
		;;
	-v | --verbose)
		VERBOSE=1
		shift
		;;
	-r | --report)
		MODE="REPORT"
		shift
		;;
	*)
		log "ERROR" "Unknown option passed: $1"
		usage
		;;
	esac
done

setup_directories
check_dependencies

if [[ "$MODE" == "REPORT" ]]; then
	perl "$PERL_SOURCE" --report
	exit $?
fi

[[ $VERBOSE -eq 1 ]] && log "INFO" "Collecting system data..."
CPU=$(get_cpu)
RAM=$(get_ram)
DISK=$(get_disk)
LOAD=$(get_load)
[[ $VERBOSE -eq 1 ]] && log "OK" "Metrics gathered."

log "INFO" "Data: CPU=$CPU%, RAM=$RAM%, DISK=$DISK%, LOAD=$LOAD"

OUT=$(perl "$PERL_SOURCE" \
	--cpu "$CPU" --ram "$RAM" --disk "$DISK" --load "$LOAD" \
	--verbose "$VERBOSE" 2>&1)

RET=$?
if [[ $RET -eq 0 ]]; then
	if [[ -n "$OUT" ]]; then
		while read -r line; do
			if [[ "$line" == *"FATAL"* || "$line" == *"Error"* ]]; then
				log "ERROR" "$line"
			elif [[ -n "$line" ]]; then
				log "WARN" "$line"
			fi
		done <<<"$OUT"
		log "OK" "Saved successfully."
	else
		log "OK" "Saved successfully."
	fi
else
	log "ERROR" "Execution failed ($RET): $OUT"
	exit $RET
fi
