#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

# "Locks" printer for our use
export CB_BUSY=1

# Source helper scripts and variables
. util.sh

FILE=$1

fanctl "off"

MSG="Be aware, [${FILE}] replication has initiated. Coolant deactivated."
write_msg "RQ" "$MSG"


