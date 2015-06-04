#!/bin/bash

# Helper script
# Writes a message to multiple outputs

# Load user defined variables
. /home/pi/.cerealbox/config

# Set logfile
LOG=/tmp/write_msg.log
RETVAL=0

# Check for proper number of arguments
if [ "$#" -gt 3 ] || [ "$#" -lt 2 ]; then
	METHOD="STD,LOG,RQ"
	MSG="Alert - write_msg function is being called with bad arguments. \
		Details in /tmp/write_msg.log."
	MSG_LOG=$LOG
	RETVAL=1
else
	METHOD=$1
	MSG=$2
	if [ -e "$3" ]; then
		MSG_LOG=$3
	else
		MSG_LOG=$LOG
	fi
fi

# Check for Standard output
case "$METHOD" in
*STD*)
	echo "$MSG"
;;
esac

# Check for RedQueen output
case "$METHOD" in
*RQ*)
	rq_msg "[CB]: $MSG"
;;
esac

# Check for Logfile output
case "$METHOD" in
*LOG*)
	echo "`date`: ${MSG}" >> $MSG_LOG
;;
esac

exit $RETVAL








