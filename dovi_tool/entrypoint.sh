#!/usr/bin/env sh

set -euxo pipefail
IFS=$(echo -en "\n\b")

# Bash function to run ffmpeg and dovi_tool
convert_file() {
	ffmpeg -i $1 -c:v copy -vbsf hevc_mp4toannexb -f hevc - | dovi_tool -m 2 convert --discard -
}

convert_file $1
