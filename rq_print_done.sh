#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

APIKEY=$1
FILE=$2

#echo "Key: ${APIKEY}"
#echo "File: ${FILE}"

FILE=`echo "${FILE}" | grep -Eo '[[:alnum:]_]+\.gcode\>'` 

MSG="No Status."
if [ "$FILE" = "cycle_hotbed.gcode" ]
then
MSG="End Specilized hotbed code, fan should be off"
#echo f > /dev/ttyUSB0
else
MSG="[${FILE}] has finished processing. Send someone expendable to retrieve it, ctag perhaps?"
fi

curl --data "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \"isaction\":false, \"key\":\"${APIKEY}\"}" https://crump.space/rq/relay -H "Content-Type:application/json"



