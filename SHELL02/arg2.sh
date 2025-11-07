#!/bin/bash
# Author: Oliwier Strek

declare -A options

OPTS=$(getopt -o :abcdefghjklmnprstuvwxyzi:o:q -l help -n "$0" -- "$@") || OPTS="$*"
eval set -- "$OPTS"

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help)
		printf "Usage:\n...\n...\n...\n"
		exit 0
		;;
	-q)
		echo "Unsupported option: -q"
		exit 0
		;;
	-i)
		if [[ -z "$2" || "$2" == -* ]]; then
			echo "-i -o options require a filename"
			exit 0
		fi
		options[i]="present and set to \"$2\""
		shift 2
		;;
	-o)
		if [[ -z "$2" || "$2" == -* ]]; then
			echo "-i -o options require a filename"
			exit 0
		fi
		options[o]="present and set to \"$2\""
		shift 2
		;;
	--)
		shift
		break
		;;
	-*)
		char=${1#-}
		options[$char]="present"
		shift
		;;
	*)
		break
		;;
	esac
done

for k in $(printf '%s\n' "${!options[@]}" | sort); do
	echo "-$k ${options[$k]}"
done

if [[ $# -gt 0 ]]; then
	echo "Arguments are:"
	i=1
	for arg in "$@"; do
		echo "\$${i}=$arg"
		((i++))
	done
fi
