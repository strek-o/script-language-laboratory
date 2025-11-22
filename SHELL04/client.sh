#!/bin/bash
# Author: Oliwier Strek

SERVER_HOST="localhost"
SERVER_PORT=6789

if [[ "$1" == "test1" ]]; then
	send_query() {
		echo "$1" | nc "$SERVER_HOST" "$SERVER_PORT"
	}

	send_query "?"
	send_query "INC"
	send_query "INC"
	send_query "?"
	send_query "INC"
	send_query "?"
	exit 0
fi
