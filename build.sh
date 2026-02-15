#!/bin/bash

# Script to zip each subfolder in 'system' and place the zip in '../system'

set -e

# System Directory
echo "System Directory"
echo "----------------"
SYSTEM_SRC="src/system"
SYSTEM_OUT="public/system"

mkdir -p "$SYSTEM_OUT"
for dir in "$SYSTEM_SRC"/*/; do
	folder_name=$(basename "$dir")
	if [ "$folder_name" = "ScummVM" ]; then
		continue
	fi
	echo "- $folder_name"
	[ ! -f "$SYSTEM_OUT/$folder_name.zip" ] && zip -r "$SYSTEM_OUT/$folder_name.zip" -j "$dir"
done

# System: ScummVM
[ ! -f "$SYSTEM_OUT/ScummVM.zip" ] && curl -L -o "$SYSTEM_OUT/ScummVM.zip" "https://buildbot.libretro.com/assets/system/ScummVM.zip"

# Index Files
echo ""
echo "Index Files"
echo "-----------"
for target in public/cores public/frontend public/system; do
	find "$target" -type d | while read -r d; do
		(
			echo "$target/$d"
			cd "$d"
			find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort > .index-dirs
			find . -mindepth 1 -maxdepth 1 -type f ! -name '.*' -printf '%P\n' | sort > .index
		)
	done
done

# Trim all .index and .index-dirs files
# find public -type f \( -name ".index" -o -name ".index-dirs" \) | while read -r idxfile; do
# 	sed -i 's/^[ \t]*//;s/[ \t]*$//' "$idxfile"
# done