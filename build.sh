#!/bin/bash

# Builds the assets server:
#   - zips each subfolder of src/system into public/system
#   - downloads the ScummVM system files
#   - generates the .index / .index-dirs / .index-extended files RetroArch reads
#
# The frontend assets (assets.zip, overlays.zip, ...) are downloaded by the
# Makefile's `frontend` target, so run `make` for a complete build (see README).

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
	zip_file="$SYSTEM_OUT/$folder_name.zip"
	# Rebuild when the zip is missing or any source file is newer than it,
	# so a submodule update actually refreshes the served zips.
	if [ ! -f "$zip_file" ] || [ -n "$(find "$dir" -newer "$zip_file" -print -quit)" ]; then
		echo "- $folder_name"
		rm -f "$zip_file"
		zip -r "$zip_file" -j "$dir"
	fi
done

# System: ScummVM
[ ! -f "$SYSTEM_OUT/ScummVM.zip" ] && curl -L -o "$SYSTEM_OUT/ScummVM.zip" "https://buildbot.libretro.com/assets/system/ScummVM.zip"

# Index Files
echo ""
echo "Index Files"
echo "-----------"
mkdir -p public/cores public/frontend public/system
for target in public/cores public/frontend public/system; do
	find "$target" -type d | while read -r d; do
		(
			echo "$d"
			cd "$d"
			find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort > .index-dirs
			find . -mindepth 1 -maxdepth 1 -type f ! -name '.*' -printf '%P\n' | sort > .index

			# Cores also need .index-extended (date + CRC-32 of the file *inside*
			# each zip) so RetroArch's Core Updater can detect changed cores.
			if [ "$target" = "public/cores" ]; then
				: > .index-extended
				find . -mindepth 1 -maxdepth 1 -type f -name '*.zip' -printf '%P\n' | sort | while read -r zip; do
					crc=$(unzip -v "$zip" | awk '$1 ~ /^[0-9]+$/ { print $7; exit }')
					printf '%s %s %s\n' "$(date -r "$zip" +%Y-%m-%d)" "$crc" "$zip" >> .index-extended
				done
			fi
		)
	done
done

# Trim all .index and .index-dirs files
# find public -type f \( -name ".index" -o -name ".index-dirs" \) | while read -r idxfile; do
# 	sed -i 's/^[ \t]*//;s/[ \t]*$//' "$idxfile"
# done