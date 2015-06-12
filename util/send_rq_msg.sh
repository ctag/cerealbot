#!/bin/bash

# Helper script
# Accept string input and write it to irc channels

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Check if the dirs are sourced
if [ ! -d "$UTIL_DIR" ]; then
	. "$LOCAL_DIR/dirs"
fi

. $UTIL_DIR/config

# Set resty url
api_url='https://crump.space/rq'
# resty output like: http://localhost/api* ''
# We want everything before the '*'
resty_url=`resty -v | awk -F '*' '{ print $1 }'`
if [ "$resty_url" != "$api_url" ]; then
	resty "$api_url"
fi

# Set Logfile
LOG=/tmp/cb_rq_msg.log
MSG=$1

if [ "$RQ_ENABLED" = "true" ]; then
	# Write to logfile
	$UTIL_DIR/write_msg.sh "LOG" "Writing message [$MSG] to RedQueen." "$LOG"
	# Make API call
	POST /relay "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \
\"isaction\":false, \"key\":\"$RQ_API_KEY\"}" >> $LOG
else
	$UTIL_DIR/write_msg.sh "LOG" "NOT writing message [$MSG] to RedQueen. Disabled in config." "$LOG"
fi




