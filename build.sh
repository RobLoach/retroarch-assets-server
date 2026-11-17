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
		# Build to a hidden temp file and swap it in, so the served zip is
		# never missing or half-written.
		tmp_zip="$SYSTEM_OUT/.$folder_name.zip.tmp"
		rm -f "$tmp_zip"
		zip -r "$tmp_zip" -j "$dir"
		mv "$tmp_zip" "$zip_file"
	fi
done

# Remove zips whose source folder no longer exists, since `make update`
# refreshes in place instead of cleaning first.
for zip_file in "$SYSTEM_OUT"/*.zip; do
	[ -f "$zip_file" ] || continue
	folder_name=$(basename "$zip_file" .zip)
	if [ "$folder_name" != "ScummVM" ] && [ ! -d "$SYSTEM_SRC/$folder_name" ]; then
		echo "- removing $folder_name"
		rm -f "$zip_file"
	fi
done

# System: ScummVM
# Only download when upstream is newer than the local copy (-z). Download to
# a hidden temp file and swap it in only if something was received, so a
# failed or unchanged transfer never removes or truncates the served zip.
scummvm_zip="$SYSTEM_OUT/ScummVM.zip"
scummvm_part="$SYSTEM_OUT/.ScummVM.zip.part"
since=()
if [ -f "$scummvm_zip" ]; then
	since=(-z "$scummvm_zip")
fi
curl -fL --retry 3 --connect-timeout 15 ${since[@]+"${since[@]}"} -R -o "$scummvm_part" "https://buildbot.libretro.com/assets/system/ScummVM.zip"
if [ -s "$scummvm_part" ]; then
	mv "$scummvm_part" "$scummvm_zip"
else
	rm -f "$scummvm_part"
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
			# Write each index to a hidden temp file and swap it in, so readers
			# never see a half-written index.
			find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort > .index-dirs.tmp
			mv .index-dirs.tmp .index-dirs
			find . -mindepth 1 -maxdepth 1 -type f ! -name '.*' -printf '%P\n' | sort > .index.tmp
			mv .index.tmp .index

			# Cores also need .index-extended (date + CRC-32 of the file *inside*
			# each zip) so RetroArch's Core Updater can detect changed cores.
			if [ "$target" = "public/cores" ]; then
				: > .index-extended.tmp
				while IFS= read -r zip; do
					# A core zip holds a single file; take the first entry's CRC.
					crc=$(unzip -v "$zip" | awk '$1 ~ /^[0-9]+$/ && !found { found = 1; print $7 }')
					if [ -z "$crc" ]; then
						echo "warning: no CRC found in $d/$zip, skipping" >&2
						continue
					fi
					printf '%s %s %s\n' "$(file_date "$zip")" "$crc" "$zip" >> .index-extended.tmp
				done < <(find . -mindepth 1 -maxdepth 1 -type f -name '*.zip' -printf '%P\n' | sort)
				mv .index-extended.tmp .index-extended
			fi
		)
	done < <(find "$target" -type d)
done