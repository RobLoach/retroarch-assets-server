#!/bin/bash

# Builds the assets server:
#   - zips each subfolder of src/system into public/system
#   - downloads the ScummVM system files
#   - generates the .index / .index-dirs / .index-extended files RetroArch reads
#
# The frontend assets (assets.zip, overlays.zip, ...) are downloaded by the
# Makefile's `frontend` target, so run `make` for a complete build (see README).

set -euo pipefail

for cmd in zip unzip curl; do
	command -v "$cmd" >/dev/null 2>&1 || { echo "error: '$cmd' is required but not installed" >&2; exit 1; }
done

# Modification date of a file as %Y-%m-%d, on GNU or BSD userland.
file_date() {
	date -r "$1" +%Y-%m-%d 2>/dev/null || stat -f %Sm -t %Y-%m-%d "$1"
}

mkdir -p public/cores public/frontend public/system

# System Directory
echo "System Directory"
echo "----------------"
SYSTEM_SRC="src/system"
SYSTEM_OUT="public/system"
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
# Download to a temp file so a failed transfer never leaves a partial zip
# behind that would be mistaken for a complete one on the next run.
if [ ! -f "$SYSTEM_OUT/ScummVM.zip" ]; then
	curl -fL --retry 3 --connect-timeout 15 -o "$SYSTEM_OUT/ScummVM.zip.part" "https://buildbot.libretro.com/assets/system/ScummVM.zip"
	mv "$SYSTEM_OUT/ScummVM.zip.part" "$SYSTEM_OUT/ScummVM.zip"
fi

# Index Files
echo ""
echo "Index Files"
echo "-----------"
for target in public/cores public/frontend public/system; do
	while IFS= read -r d; do
		(
			echo "$d"
			cd "$d"
			find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort > .index-dirs
			find . -mindepth 1 -maxdepth 1 -type f ! -name '.*' -printf '%P\n' | sort > .index

			# Cores also need .index-extended (date + CRC-32 of the file *inside*
			# each zip) so RetroArch's Core Updater can detect changed cores.
			if [ "$target" = "public/cores" ]; then
				: > .index-extended
				while IFS= read -r zip; do
					# A core zip holds a single file; take the first entry's CRC.
					crc=$(unzip -v "$zip" | awk '$1 ~ /^[0-9]+$/ && !found { found = 1; print $7 }')
					if [ -z "$crc" ]; then
						echo "warning: no CRC found in $d/$zip, skipping" >&2
						continue
					fi
					printf '%s %s %s\n' "$(file_date "$zip")" "$crc" "$zip" >> .index-extended
				done < <(find . -mindepth 1 -maxdepth 1 -type f -name '*.zip' -printf '%P\n' | sort)
			fi
		)
	done < <(find "$target" -type d)
done