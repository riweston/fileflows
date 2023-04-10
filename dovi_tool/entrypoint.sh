#!/usr/bin/env sh

set -euxo pipefail
IFS=$(echo -en "\n\b")

# Cleanup function to remove any leftover files
cleanup() {
	rm -f "${1%.*}.hevc" "${1%.*}.mkv.tmp"
}

# Sanity check
if [ -z "${1+x}" ]; then
	echo "Usage: $0 <filename>"
	exit 1
fi

if [ ! -f "$1" ]; then
	echo "$1 is not a file"
	exit 1
fi

# Demux the file using ffmpeg and dovi_tool
demux_file() {
	if ! ffmpeg -i "$1" -c:v copy -vbsf hevc_mp4toannexb -f hevc - | dovi_tool -m 2 convert --discard -; then
		echo "Failed to demux $1"
		cleanup "$1"
		exit 1
	fi
}

# Remux the file using mkvmerge
remux_file() {
	if ! mkvmerge -o "${1%.*}.mkv.tmp" -D "$1" BL_RPU.hevc; then
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
	demux_file "$1"
	remux_file "$1"
	overwrite_file "$1"
	cleanup "$1"
}

main "$1"
