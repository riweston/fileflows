#!/usr/bin/env sh

set -eo pipefail
IFS=$(echo -en "\n\b")

# Sanity check
if ! command -v mediainfo >/dev/null 2>&1; then
	echo "mediainfo could not be found"
	exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
	echo "ffmpeg could not be found"
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
	rm -f "${1%.*}.hevc" "${1%.*}.mkv.tmp" "${1%.*}.mkv.copy" BL_RPU.hevc
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

# Demux the file using ffmpeg and dovi_tool
demux_file() {
	echo "Demuxing $1..."
	echo "------------------"
	echo "ffmpeg -i $1 -c:v copy -vbsf hevc_mp4toannexb -f hevc - | dovi_tool -m 2 convert --discard -"
	echo "------------------"
	if ! ffmpeg -i "$1" -c:v copy -vbsf hevc_mp4toannexb -f hevc - | dovi_tool -m 2 convert --discard -; then
		echo "Failed to demux $1"
		cleanup "$1"
		exit 1
	fi
}

# Remux the file using mkvmerge
remux_file() {
	echo "Remuxing $1..."
	echo "------------------"
	echo "mkvmerge -o ${1%.*}.mkv.tmp BL_RPU.hevc -D $1"
	echo "------------------"
	if ! mkvmerge -o "${1%.*}.mkv.tmp" BL_RPU.hevc -D "$1"; then
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
