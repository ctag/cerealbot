#!/bin/bash

# This script is called by octoprint on print initialization
# It will:
# - Turn off the fan
# - Send a message to RedQueen
#

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Check if the dirs are sourced
if [ ! -d "$UTIL_DIR" ]; then
	. "$LOCAL_DIR/dirs"
fi

# Source helper scripts and variables
. $UTIL_DIR/util

FILE=$1

fanctl "off"

MSG="Be aware, [${FILE}] replication has initiated. Coolant deactivated."
write_msg "RQ" "$MSG"


