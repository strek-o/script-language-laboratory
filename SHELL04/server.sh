#!/bin/bash
# Author: Oliwier Strek

PORT=6789

while [[ $# -gt 0 ]]; do
	case "$1" in
	-p)
		PORT="$2"
		shift 2
		;;
	*)
		shift
		;;
	esac
done

if lsof -i TCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
	echo "Port $PORT is unavailable"
	exit 1
fi

socat TCP-LISTEN:"$PORT",reuseaddr,fork SYSTEM:"bash handler.sh"
