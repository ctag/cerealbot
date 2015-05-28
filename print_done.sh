#!/bin/bash

# This script will check the status of a print
# and have RedQueen alert me when a print is done.

FILE=$1
Z_HEIGHT=$2

MSG="No Status. Something has broken the CerealBot."
if [ "$FILE" = "cycle_hotbed.gcode" ]
then
MSG="End Specilized hotbed code."
else
echo -n "..:fi" >> /dev/ttyUSB0
MSG="[${FILE}] has concluded processing at [${Z_HEIGHT}]mm. Coolant activated."
fi

. /home/pi/cerealbox/rq_msg.sh "$MSG"

. /home/pi/cerealbox/pop_part.sh

