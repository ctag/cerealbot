#!/bin/bash

# Helper script
# Accept string input and write it to irc channels

# Load user defined variables
if [ ! -d "$CB_DIR" ]; then
	CB_DIR=`dirname $0`
fi
. $CB_DIR/config

# Set resty url
resty 'https://crump.space/rq'

# Set Logfile
LOG=/tmp/cb_rq_msg.log
MSG=$1

if [ "$RQ_ENABLED" = "true" ]; then
	# Write to logfile
	$CB_DIR/write_msg.sh "LOG" "Writing message [$MSG] to RedQueen." "$LOG"
	# Make API call
	POST /relay "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \
\"isaction\":false, \"key\":\"$RQ_API_KEY\"}" >> $LOG
else
	$CB_DIR/write_msg.sh "LOG" "NOT writing message [$MSG] to RedQueen. Disabled in config." "$LOG"
fi




