#!/bin/bash
# Author: Oliwier Strek

if [[ $# -eq 2 ]]; then
	if [[ $1 -le $2 ]]; then
		A=$1
		B=$2
	else
		exit
	fi
elif [[ $# == 1 ]]; then
	A="1"
	B=$1
else
	exit
fi

for ((i = A; i <= B + 1; i++)); do

	if [[ $i -eq $A ]]; then
		printf "%4s" " "
	else
		printf "%4d" "$((i - 1))"
	fi
	for ((j = A; j <= B; j++)); do

		if [[ $i -eq $A ]]; then
			printf "%4d" $j
		else
			printf "%4d" "$(((i - 1) * j))"
		fi
	done
	printf "\n"
done
