#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

APIKEY=$1
FILE=$2

echo "Key: ${APIKEY}"
echo "File: ${FILE}"

FILE=`echo "${FILE}" | grep -Eo '[[:alnum:]_]+\.gcode\>'` 

MSG="No Status."
if [ "$FILE" = "cycle_hotbed.gcode" ]
then
MSG="Begin task for removing adhered part from heated build platform."
exec /home/pi/cerealbox/cycle_fan.sh &
else
echo -n ..:fo >> /dev/ttyUSB0
MSG="Be aware, [${FILE}] replication has initiated. Coolant deactivated."
fi

. rq_msg.sh $MSG

