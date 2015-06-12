#!/bin/bash

# Helper script
# Sends one or more commands to the printrbot via API

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Check if the dirs are sourced
if [ ! -d "$UTIL_DIR" ]; then
	. "$LOCAL_DIR/dirs"
fi

. $UTIL_DIR/config

# Set logfile
LOG=/tmp/printr_cmd.sh

cmds=""

for cmd in "$@"
	do
	#$CB_DIR/write_msg.sh "STD,LOG" "[$cmd]" "$LOG"
	if [ "$cmd" = "$1" ]; then
		cmds="\"${cmd}\""
	else
		cmds="${cmds},\"${cmd}\""
	fi
done

$UTIL_DIR/write_msg.sh "STD,LOG" "Sending printer commands: $cmds" "$LOG"

# Set resty url
api_url='http://localhost/api'
# resty output like: http://localhost/api* ''
# We want everything before the '*'
resty_url=`resty -v | awk -F '*' '{ print $1 }'`
if [ "$resty_url" != "$api_url" ]; then
resty "$api_url"
fi
POST /printer/command "{\"commands\":[$cmds]}"
