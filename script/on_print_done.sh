#!/bin/bash

# On Print Done
# Called by octoprint when a part is finished
# Will:
# - Message RedQueen
# - Set a lockfile on the printer
# - Cycle the hotbed
# - Push off the part
#

# Set the local directory
LOCAL_DIR=`dirname $0`

# Source directories
. $LOCAL_DIR/dirs

# Source helper scripts and variables
. $UTIL_DIR/util

LOG=/tmp/print_done.log
FILE=$1
Z_HEIGHT=$2
Z_VAR=${Z_HEIGHT%.*}

# Check lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    write_msg "STD,LOG,RQ" "Cannot proceed with part removal, lockfile exists." "$LOG"
    exit
fi
# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

fanctl "on"

MSG="[${FILE}] has concluded processing at [$Z_VAR]mm. Coolant activated."
write_msg "RQ,LOG" "$MSG" "$LOG"

if [ $Z_VAR -lt 2 ]; then
	MSG="Z-HEIGHT is invalid, aborting part removal. Manual intervention required."
	write_msg "RQ,LOG" "$MSG" $LOG
	exit
fi

if [ "$TIMEOUT_ENABLED" = "true" ]; then
	write_msg "LOG" "Sleeping to let buildplate cool off." "$LOG"
	sleep 20m
fi

#write_msg "LOG,STD" "Deleting $FILE from server queue." "$LOG"
# Set resty url
#api_url='http://localhost/api'
# resty output like: http://localhost/api* ''
# We want everything before the '*'
#resty_url=`resty -v | awk -F '*' '{ print $1 }'`
#if [ "$resty_url" != "$api_url" ]; then
#	resty "$api_url"
#fi
#DELETE "/files/local/$FILE"

if [ "$POP_ENABLED" = "true" ]; then
	$SCRIPT_DIR/pop_part.sh "$FILE" "$Z_VAR"
else
	write_msg "STD,LOG" "Not popping parts, disabled in config." "$LOG"
fi

if [ "$PUSH_ENABLED" = "true" ]; then
	$SCRIPT_DIR/push_part.sh "$FILE" "$Z_VAR"
else
	write_msg "STD,LOG" "Not pushing parts, disabled in config." "$LOG"
fi

rm -f ${LOCKFILE}
