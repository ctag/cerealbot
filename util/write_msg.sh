#!/bin/bash

# Helper script
# Writes a message to multiple outputs

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
LOG=/tmp/write_msg.log
RETVAL=0

# Check for proper number of arguments
if [ "$#" -gt 3 ] || [ "$#" -lt 2 ]; then
	METHOD="STD,LOG,RQ"
	MSG="Alert - write_msg function is being called with bad arguments. \
Details in ${LOG}."
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
	$UTIL_DIR/send_rq_msg.sh "[CB]: $MSG"
;;
esac

# Check for Logfile output
case "$METHOD" in
*LOG*)
	echo "`date`: ${MSG}" >> $MSG_LOG
;;
esac

if [ "$RETVAL" -eq 1 ]; then
	for arg in $@
	do
		echo "`date`: Arg: $arg" >> $MSG_LOG
	done
fi

exit $RETVAL








