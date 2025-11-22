#!/bin/bash
# Author: Oliwier Strek

PID_FILE="server.pid"
CONFIG_FILE="$HOME/.config/server.conf"

get_port() {
	if [[ -n "$1" ]]; then
		echo "$1"
	elif [[ -f "$CONFIG_FILE" ]]; then
		cat "$CONFIG_FILE"
	else
		echo "6789"
	fi
}

is_running() {
	[[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

case "$1" in
start)
	PORT=$(get_port "$2")
	if is_running; then
		exit 0
	fi
	setsid bash ./server.sh -p "$PORT" >/dev/null 2>&1 &
	echo $! >"$PID_FILE"
	;;
stop)
	PORT=$(get_port "$2")
	if is_running; then
		PID=$(cat "$PID_FILE")
		kill -- -"$PID" 2>/dev/null || true
		rm -f "$PID_FILE"
	fi
	;;
restart)
	bash "$0" stop
	if [[ -n "$2" ]]; then
		bash "$0" start "$2"
	else
		bash "$0" start
	fi
	;;
status)
	if is_running; then
		cat "$PID_FILE"
	fi
	;;
*)
	printf "\nUsage:\n\t%s [start PORT|stop|restart|status]\n\n" "$0"
	;;
esac
