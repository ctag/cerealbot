#!/bin/bash

#
# This script is called after a part has been printed
# If the printer status is agreeable, it will then
# activate a .gcode file to loosen the printed part
# Christopher Bero [bigbero@gmail.com]
#

# Collect variables
Z_HEIGHT=$1

# Initiate resty
. /home/pi/cerealbox/resty

# Setup log file
LOG=/tmp/pop_part.log
echo "`date`: Begin pop_part.sh" >> $LOG

# Fetch Printer Status
PRINTR_STATUS=`curl -H "X-Api-Key:$OCTO_API_KEY" http://bns-daedalus.256.makerslocal.org/api/printer -o /tmp/printr_status.json`
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
#API_HOTBED=`curl -H "X-Api-Key: $OCTO_API_KEY" -F select=true -F print=true -F file=@gcode/cycle_hotbed.gcode  http://bns-daedalus.256.makerslocal.org/api/files/local -o /tmp/printr_upload.json`

# Set resty url
resty http://bns-daedalus.256.makerslocal.org/api
# Make sure fan is off
/bin/bash fanctl.sh "off"
# Turn on hotbed to 70C
POST /printer/command '{"command":"M140 S70"}'
sleep 8m
# Turn off hotbed
POST /printer/command '{"command":"M140 S0"}'
sleep 2m
/bin/bash /home/pi/cerealbox/fanctl.sh "on"
sleep 25m
/bin/bash /home/pi/cerealbox/fanctl.sh "off"
sleep 5m
echo "`date`: Done with cycle." >> $LOG

}

. /home/pi/cerealbox/rq_msg.sh "Activating automatic part adherence mitigation. Please stand clear."

#cycle_hotbed
#cycle_hotbed
#cycle_hotbed
#cycle_hotbed

. /home/pi/cerealbox/rq_msg.sh "Finished automatic buildplate cycling."

if [ -z $Z_HEIGHT ]; then
. /home/pi/cerealbox/rq_msg.sh "Z is null, not moving print head."
exit
fi

X_VAR=0
Y_VAR=0
Z_VAR=Z_HEIGHT

function ptr_cmd {
resty http://localhost/api
POST /printer/command '{"command":"$1"}'
}

function mv_rel {
DIR=$1
DIST=$2
if 
}

function reset_x {
ptr_cmd "G28 X"
X_VAR=0
}


function initial_z_check {


}


















