#!/bin/bash

# This script will check the status of a print
# and have RedQueen alert me when a print is done.

APIKEY=$1
FILE=$2

#echo "Key: ${APIKEY}"
#echo "File: ${FILE}"

FILE=`echo "${FILE}" | grep -Eo '[[:alnum:]_]+\.gcode\>'` 

MSG="No Status. Something has broken the CerealBot."
if [ "$FILE" = "cycle_hotbed.gcode" ]
then
MSG="End Specilized hotbed code."
else
echo -n ..:fi >> /dev/ttyUSB0
MSG="[${FILE}] has concluded processing. Coolant activated."
fi

curl --data "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \"isaction\":false, \"key\":\"${APIKEY}\"}" https://crump.space/rq/relay -H "Content-Type:application/json"

. pop_part.sh &

