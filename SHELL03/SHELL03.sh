#!/bin/bash
# Author: Oliwier Strek

set -o pipefail

REPLACE_WITH_HARDLINKS=0
MAX_DEPTH=""
HASH_ALGO="md5sum"

while [[ $# -gt 0 ]]; do
	case "$1" in
	--replace-with-hardlinks)
		REPLACE_WITH_HARDLINKS=1
		shift
		;;
	--max-depth=*)
		N="${1#*=}"
		MAX_DEPTH="-maxdepth $N"
		shift
		;;
	--hash-algo=*)
		HASH_ALGO="${1#*=}"
		shift
		;;
	--help)
		printf "\nUsage:\n\t%s [--replace-with-hardlinks] [--max-depth=N] [--hash-algo=ALGO] DIRNAME\n\n" "$0"
		exit 0
		;;
	*)
		if [[ -z "$DIRNAME" ]]; then
			DIRNAME="$1"
			shift
		else
			shift
		fi
		;;
	esac
done

if [[ -z "$DIRNAME" ]]; then
	echo "directory not specified" >&2
	exit 1
fi

if ! command -v "$HASH_ALGO" >/dev/null 2>&1; then
	echo "$HASH_ALGO not supported"
	exit 1
fi

AAA=0
BBB=0
CCC=0

TMP_FIND=$(mktemp tmpXXXXXXXXX)
TMP_SORT=$(mktemp tmpXXXXXXXXX)
TMP_DUPE=$(mktemp tmpXXXXXXXXX)
TMP_HASH=$(mktemp tmpXXXXXXXXX)

make_clean() {
	rm -f "$TMP_FIND" "$TMP_SORT" "$TMP_DUPE" "$TMP_HASH"
}
trap make_clean EXIT

find "$DIRNAME" $MAX_DEPTH -type f -printf "%s\t%p\n" >"$TMP_FIND" 2>/dev/null
AAA=$(wc -l <"$TMP_FIND")

sort -n -k1,1 "$TMP_FIND" >"$TMP_SORT"
cut -f1 "$TMP_SORT" | uniq -d >"$TMP_DUPE"

while read -r size; do

	TMP_DUPE_FILES=$(mktemp tmpXXXXXXXXX)
	grep -P "^${size}\t" "$TMP_SORT" | cut -f2- >"$TMP_DUPE_FILES"

	group_count=$(wc -l <"$TMP_DUPE_FILES")
	if ((group_count <= 1)); then
		rm -f "$TMP_DUPE_FILES"
		continue
	fi

	: >"$TMP_HASH"
	while IFS= read -r file; do

		hash=$($HASH_ALGO "$file" 2>/dev/null | awk '{print $1}')
		echo -e "${hash}\t${file}" >>"$TMP_HASH"

	done <"$TMP_DUPE_FILES"

	TMP_HASH_DUPLICATES=$(mktemp tmpXXXXXXXXX)
	cut -f1 "$TMP_HASH" | sort | uniq -d >"$TMP_HASH_DUPLICATES"
	if [[ -s "$TMP_HASH_DUPLICATES" ]]; then
		while read -r hash; do

			TMP_HASH_SAME=$(mktemp tmpXXXXXXXXX)
			grep -P "^${hash}\t" "$TMP_HASH" | cut -f2- >"$TMP_HASH_SAME"

			cnt=$(wc -l <"$TMP_HASH_SAME")
			if ((cnt <= 1)); then
				rm -f "$TMP_HASH_SAME"
				continue
			fi

			read -r master <"$TMP_HASH_SAME"
			while IFS= read -r candidate; do

				if [[ "$candidate" == "$master" ]]; then
					continue
				fi

				if cmp -s -- "$master" "$candidate"; then
					((BBB++))

					if ((REPLACE_WITH_HARDLINKS)); then
						rm -f -- "$candidate" 2>/dev/null

						if ln -- "$master" "$candidate" 2>/dev/null; then
							((CCC++))
						else
							echo "[$candidate] hardlink not created" >&2
						fi
					fi
				fi
			done <"$TMP_HASH_SAME"

			rm -f "$TMP_HASH_SAME"
		done <"$TMP_HASH_DUPLICATES"
	fi

	rm -f "$TMP_DUPE_FILES" "$TMP_HASH_DUPLICATES"
done <"$TMP_DUPE"

echo "Processed files: $AAA"
echo "Found duplicates: $BBB"
echo "Replaced duplicates: $CCC"
