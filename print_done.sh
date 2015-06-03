#!/bin/bash

# This script will check the status of a print
# and have RedQueen alert me when a print is done.

LOG=/tmp/print_done.log
FILE=$1
Z_HEIGHT=$2
Z_VAR=${Z_HEIGHT%.*}

MSG="No Status. Something has broken the CerealBot."
if [ "$FILE" = "cycle_hotbed.gcode" ]
then
MSG="End Specilized hotbed code."
else
echo -n "..:fi" >> /dev/ttyUSB0
MSG="[${FILE}] has concluded processing at [$Z_VAR]mm. Coolant activated."
fi

$CB_DIR/rq_msg.sh "$MSG"
echo "`date`: $MSG" >> $LOG

if [ $Z_VAR -lt 2 ]; then
MSG="Z-HEIGHT is invalid, aborting part removal. Manual intervention required."
$CB_DIR/rq_msg.sh "$MSG"
echo "`date`: $MSG" >> $LOG
exit
fi

$CB_DIR/pop_part.sh "$Z_VAR"

