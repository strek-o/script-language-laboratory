#!/bin/bash
# Author: Oliwier Strek

declare -A options
# i_set=""
# o_set=""

while getopts ":abcdefghjklmnprstuvwxyzi:o:q" opt; do
	case $opt in
	q)
		echo "Unsupported option: -q"
		exit 0
		;;
	i)
		if [[ -z "$OPTARG" || "$OPTARG" == -* ]]; then
			echo "-i -o options require a filename"
			exit 1
		fi
		# i_set="$OPTARG"
		options[i]="present and set to \"$OPTARG\""
		;;
	o)
		if [[ -z "$OPTARG" || "$OPTARG" == -* ]]; then
			echo "-i -o options require a filename"
			exit 1
		fi
		# o_set="$OPTARG"
		options[o]="present and set to \"$OPTARG\""
		;;
	:)
		echo "-i -o options require a filename"
		exit 1
		;;
	*)
		options[$opt]="present"
		;;
	esac
done

shift $((OPTIND - 1))

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

# echo "i_set: $i_set"
# echo "o_set: $o_set"
