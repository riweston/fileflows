#!/usr/bin/env sh

set -euxo pipefail
IFS=$(echo -en "\n\b")

trap 'echo "Error: $0:$LINENO: Command \`$BASH_COMMAND\` on line $LINENO failed with exit code $?" >&2; cleanup $1' ERR

# Set input arguments
INPUT_FILE=$1
PROFILE=$2

# Get DV profile information using mediainfo
DVHE_PROFILE=$(mediainfo --Output=JSON "${INPUT_FILE}" | jq '.media.track[].HDR_Format_Profile' | grep "${PROFILE}" || true)

# Check if the DV profile is found
if [ -n "${DVHE_PROFILE}" ]; then
	# DV profile is found
	exit 0
else
	# DV profile is not found
	exit 1
fi
