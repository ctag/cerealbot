#!/bin/bash

# This script will check the status of a print
# and have RedQueen alert me when a print is done.

# Source helper scripts and variables
. util.sh

LOG=/tmp/print_done.log
FILE=$1
Z_HEIGHT=$2
Z_VAR=${Z_HEIGHT%.*}

MSG="No Status for print_done.sh. Something has broken."
if [ "$FILE" = "cycle_hotbed.gcode" ]
then
MSG="End Specilized hotbed code."
else
fanctl "on"
MSG="[${FILE}] has concluded processing at [$Z_VAR]mm. Coolant activated."
fi

write_msg "RQ,LOG" "$MSG" "$LOG"

if [ $Z_VAR -lt 2 ]; then
MSG="Z-HEIGHT is invalid, aborting part removal. Manual intervention required."
write_msg "RQ,LOG" "$MSG" $LOG
exit
fi

write_msg "LOG" "Sleeping to let buildplate cool off." "$LOG"
sleep 20m

write_msg "LOG,STD" "Deleting $FILE from server queue." "$LOG"
DELETE "/files/local/$FILE"

$CB_DIR/pop_part.sh "$FILE" "$Z_VAR"

# Release flag set in print_start.sh
export CB_BUSY=0
