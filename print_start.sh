#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

# "Locks" printer for our use
export CB_BUSY=true

# Source config
if [ ! -d "$CB_DIR" ]; then
	CB_DIR=`dirname $0`
fi

# Source helper scripts and variables
. $CB_DIR/util.sh

FILE=$1

fanctl "off"

MSG="Be aware, [${FILE}] replication has initiated. Coolant deactivated."
write_msg "RQ" "$MSG"


