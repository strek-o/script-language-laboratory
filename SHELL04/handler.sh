#!/bin/bash
# Author: Oliwier Strek

COUNTER_FILE="COUNTER.txt"

if [[ -f "$COUNTER_FILE" ]]; then
	COUNTER=$(cat "$COUNTER_FILE")
else
	COUNTER=0
fi

read -r line
case "$line" in
"?")
	echo "$COUNTER"
	;;
"INC")
	COUNTER=$((COUNTER + 1))
	echo "$COUNTER" >"$COUNTER_FILE"
	;;
esac
