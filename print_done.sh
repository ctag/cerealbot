#!/bin/bash

# This script will check the status of a print
# and have RedQueen alert me when a print is done.

LOG=/tmp/print_start.log
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

if [ $Z_VAR -lt 2 ]; then
$CB_DIR/rq_msg.sh "Z-HEIGHT is invalid, aborting part removal. Manual intervention required."
exit
fi

$CB_DIR/pop_part.sh $Z_VAR

