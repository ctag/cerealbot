#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

APIKEY=$1
FILE=$2

echo "Key: ${APIKEY}"
echo "File: ${FILE}"

FILE=`echo "${FILE}" | grep -Eo '[[:alnum:]_]+\.gcode\>'` 

MSG="Be aware, [${FILE}] replication has initiated."

curl --data "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \"isaction\":false, \"key\":\"${APIKEY}\"}" https://crump.space/rq/relay -H "Content-Type:application/json"


