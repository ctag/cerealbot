#!/bin/bash

# This script is a cron job
# It will look for unprinted files and print them

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Check if the dirs are sourced
if [ ! -d "$UTIL_DIR" ]; then
	. "$LOCAL_DIR/dirs"
fi

# Source helper functions
. $UTIL_DIR/util

LOG=/tmp/do_proc_q.log

function check_status {
printr_status
STATUS=$?
if [ $STATUS -ne 0 ]; then
        write_msg "LOG,STD" "Printer status is non-zero. Exiting." "$LOG"
        exit
fi
if [ -e ${LOCKFILE} ]; then
    write_msg "LOG,STD" "CB_BUSY lockfile in place. Exiting." "$LOG"
    exit
fi
}

check_status

sleep 5m

check_status

write_msg "LOG,STD" "Printer appears to be free, looking for something to print." "$LOG"

. "$UTIL_DIR/resty"

resty http://localhost/api >> /dev/null

GET /files/local | grep name | awk '{ print $2 }' | sed s/,// | sed s/\"// | sed s/\"// | while read -r file
do
write_msg "LOG,STD" "Checking file: $file" "$LOG"
file_status=`GET "/files/local/$file"`
echo $file_status | grep '"failure": 0' | grep '"success": 0' >> /dev/null
if [ $? -eq 0 ]; then
  write_msg "STD,LOG" "Oh look, a new one. I suppose [$file] can be processed.." "$LOG"
  POST "/files/local/$file" '{"command":"select","print":"true"}'
  break
fi
done

