#!/bin/bash

# This script is called by octoprint on print initialization
# It will:
# - Turn off the fan
# - Send a message to RedQueen
#

# Set local directory
LOCAL_DIR=`dirname $0`

# Source directory paths
. $LOCAL_DIR/dirs

# Source helper scripts and variables
. $UTIL_DIR/util

FILE=$1

fanctl "off"

MSG="Be aware, [${FILE}] replication has initiated. Coolant deactivated."
write_msg "RQ" "$MSG"


