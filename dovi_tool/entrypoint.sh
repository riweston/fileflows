#!/usr/bin/env sh

set -eo pipefail
IFS=$(echo -en "\n\b")

# Sanity check
if ! command -v mediainfo >/dev/null 2>&1; then
	echo "mediainfo could not be found"
	exit 1
fi

if ! command -v dovi_tool >/dev/null 2>&1; then
	echo "dovi_tool could not be found"
	exit 1
fi

if ! command -v mkvmerge >/dev/null 2>&1; then
	echo "mkvmerge could not be found"
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "jq could not be found"
	exit 1
fi

if [ -z "${1+x}" ] || [ -z "${2+x}" ]; then
	echo "Usage: $0 <filename> <profile>"
	echo "Valid profiles: dvhe.07"
	exit 1
fi

if [ ! -f "$1" ]; then
	echo "$1 is not a file"
	exit 1
fi

# Cleanup function to remove any leftover files
cleanup() {
	echo "Cleaning up working files..."
	rm -f "${1%.*}.hevc" "${1%.*}.mkv.tmp" "${1%.*}.mkv.copy" "${1%.*}.dv8.hevc" "${1%.*}.rpu.bin"
}

# Get DV profile information using mediainfo
get_dvhe_profile() {
	echo "Checking for Dolby Vision ${2} profile..."
	echo "------------------"
	echo "mediainfo --Output=JSON $1 | jq '.media.track[].HDR_Format_Profile' | grep ${2}"
	echo "------------------"
	DVHE_PROFILE=$(mediainfo --Output=JSON "$1" | jq '.media.track[].HDR_Format_Profile' | grep "${2}" || true)

	# Check if the DV profile is found
	if [ -n "${DVHE_PROFILE}" ]; then
		# DV profile is found, proceed with conversion
		echo "DVHE ${2} profile found"
	else
		# DV profile is not found, exit without processing
		echo "DVHE ${2} profile not found"
		exit 0
	fi
}

extract_mkv() {
	echo "Extracting $1..."
	echo "------------------"
	echo "mkvextract $1 tracks 0:${1%.*}.hevc"
	echo "------------------"
	if ! mkvextract "$1" tracks 0:"${1%.*}.hevc"; then
		echo "Failed to extract $1"
		cleanup "$1"
		exit 1
	fi
}

convert_mkv() {
	echo "Converting $1..."
	echo "------------------"
	echo "dovi_tool --edit-config /config/dovi_tool.config.json convert --discard ${1%.*}.hevc -o ${1%.*}.dv8.hevc"
	echo "------------------"
	if ! dovi_tool --edit-config /config/dovi_tool.config.json convert --discard "${1%.*}.hevc" -o "${1%.*}.dv8.hevc"; then
		echo "Failed to convert $1"
		cleanup "$1"
		exit 1
	fi
}

extract_rpu() {
	echo "Extracting RPU from ${1%.*}.dv8.hevc..."
	echo "------------------"
	echo "dovi_tool extract-rpu ${1%.*}.dv8.hevc -o ${1%.*}.rpu.bin"
	echo "------------------"
	if ! dovi_tool extract-rpu "${1%.*}.dv8.hevc" -o "${1%.*}.rpu.bin"; then
		echo "Failed to extract RPU from ${1%.*}.dv8.hevc"
		cleanup "$1"
		exit 1
	fi
}

create_plot() {
	echo "Creating plot from RPU..."
	echo "------------------"
	echo "dovi_tool plot ${1%.*}.rpu.bin -o ${1%.*}.l1_plot.png"
	echo "------------------"
	if ! dovi_tool plot "${1%.*}.rpu.bin" -o "${1%.*}.l1_plot.png"; then
		echo "Failed to create plot from RPU"
		cleanup "$1"
		exit 1
	fi
}

# Demux the file using ffmpeg and dovi_tool
demux_file() {
	# These functions are lifted from this post, all credit to author speedy
	# https://community.firecore.com/t/dolby-vision-profile-7-8-support-ts-mkv-files/19713/846?page=43
	echo "Demuxing $1..."
	echo "------------------"
	extract_mkv "$1"
	convert_mkv "$1"
	extract_rpu "$1"
	create_plot "$1"
}

# Remux the file using mkvmerge
remux_file() {
	echo "Remuxing $1..."
	echo "------------------"
	echo "mkvmerge -o ${1%.*}.mkv.tmp -D $1 ${1%.*}.dv8.hevc --track-order 1:0"
	echo "------------------"
	if ! mkvmerge -o "${1%.*}.mkv.tmp" -D "$1" "${1%.*}.dv8.hevc" --track-order 1:0; then
		echo "Failed to remux $1"
		cleanup "$1"
		exit 1
	fi
}

# Overwrite the original file with the remuxed file using atomic linking
overwrite_file() {
	# Create a copy of the temporary file using a symbolic link
	if ! ln "${1%.*}.mkv.tmp" "${1%.*}.mkv.copy"; then
		echo "Failed to copy ${1%.*}.mkv.tmp to ${1%.*}.mkv.copy"
		cleanup "$1"
		exit 1
	fi

	# Rename the symbolic link to the original filename, effectively overwriting the original file
	if ! mv "${1%.*}.mkv.copy" "$1"; then
		echo "Failed to overwrite $1"
		cleanup "$1"
		exit 1
	fi

	# Remove the temporary file
	if ! rm "${1%.*}.mkv.tmp"; then
		echo "Failed to remove ${1%.*}.mkv.tmp"
		cleanup "$1"
		exit 1
	fi

	if [ -f "${1%.*}.mkv.tmp" ]; then
		echo "Failed to remove ${1%.*}.mkv.tmp"
		cleanup "$1"
		exit 1
	fi
}

main() {
	trap 'echo "Error: $0:$LINENO: Command \`$BASH_COMMAND\` on line $LINENO failed with exit code $?" >&2; cleanup $1' ERR
	get_dvhe_profile "$1" "$2"
	demux_file "$1"
	remux_file "$1"
	overwrite_file "$1"
	cleanup "$1"
}

main "$1" "$2"
