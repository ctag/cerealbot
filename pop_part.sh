#!/bin/bash

#
# This script is called after a part has been printed
# If the printer status is agreeable, it will then
# activate a .gcode file to loosen the printed part
# Christopher Bero [bigbero@gmail.com]
#

# Initiate resty
. resty
resty http://localhost:8081/api

# Setup log file
LOG=/tmp/pop_part.log
echo "`date`: Begin pop_part.sh" >> $LOG

# Fetch Printer Status
PRINTR_STATUS=`curl -H "X-Api-Key:$OCTO_API_KEY" http://localhost:8081/api/printer -o /tmp/printr_status.json`
if [ $? -ne 0 ]; then
echo "`date`: curl failed, exiting." >> $LOG
exit
fi

# Verify printer is ready to pop the part

# Check printer state
cat /tmp/printr_status.json | grep "\"state\": 5,"
PTR_ST=$?
echo "`date`: Printer state: $PTR_ST" >> $LOG
if [ $PTR_ST -eq 1 ]; then
echo "`date`: Exiting due to printer state." >> $LOG
exit
else
echo "`date`: Printer reports state 5." >> $LOG
fi

# Check that printer is Operational
cat /tmp/printr_status.json | grep "\"stateString\": \"Operational\","
PTR_OP=$?
echo "`date`: Printer operational: $PTR_OP" >> $LOG
if [ $PTR_OP -eq 1 ]; then
echo "`date`: Exiting due to printer operational string." >> $LOG
exit
else
echo "`date`: Printer reports operational status." >> $LOG
fi

echo "`date`: Printer looks good, proceeding to loosen part" >> $LOG

function cycle_hotbed {

# Run the hotbed code
#curl -H "X-Api-Key: $api_key" -F select=true -F print=false -F file=@$f http://beaglebone.local:5000/api/files/local
#API_HOTBED=`curl -H "X-Api-Key: $OCTO_API_KEY" -F select=true -F print=true -F file=@gcode/cycle_hotbed.gcode  http://localhost:8081/api/files/local -o /tmp/printr_upload.json`

POST /printer/command '{"command":"M140 S70"}'
sleep 5m
/bin/bash fanctl.sh on
sleep 5m
POST /printer/command '{"command":"M140 S0"}'
sleep 20m
/bin/bash fanctl.sh off
sleep 3m
echo "`date`: Done with cycle." >> $LOG

}

#cycle_hotbed
#cycle_hotbed
#cycle_hotbed
#cycle_hotbed

resty https://crump.space/rq

MSG="Finished automatic buildplate cycling. RQ API via resty."

#curl --data "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \"isaction\":false, \"key\":\"${APIKEY}\"}" https://crump.space/rq/relay -H "Content-Type:application/json"
POST /relay "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \"isaction\":false, \"key\":\"12345\"}"

