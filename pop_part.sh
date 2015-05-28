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
Z_VAR=$Z_HEIGHT

function ptr_cmd {
resty 'http://localhost/api'
POST /printer/command "{\"command\":\"$1\"}"
}

# G91 is rel
# G90 is abs

function z_rel {
DIST=$1
Z_VAR=$(($Z_VAR+$DIST));
ptr_cmd "G91"
ptr_cmd "G1 Z${DIST} F200"
ptr_cmd "G90"
}

function reset_x {
ptr_cmd "G28 X"
X_VAR=0
}


function initial_z_check {
if [ $Z_VAR -lt 25 ]; then
#. /home/pi/cerealbox/rq_msg.sh "Probe is below allowable servo range. Moving probe up to 25mm."
Z_DELTA=$((25-$Z_VAR))
#. /home/pi/cerealbox/rq_msg.sh "Moving probe by a delta of $Z_DELTA to reach 25mm."
z_rel "$Z_DELTA"
#. /home/pi/cerealbox/rq_msg.sh "New Z val: $Z_VAR"
else
#. /home/pi/cerealbox/rq_msg.sh "Probe is at or above servo range."
z_rel "10"
fi
}

function servo_down {
. /home/pi/cerealbox/servoctl.sh "100"
}

function servo_up {
. /home/pi/cerealbox/servoctl.sh "142"
}

function y_push {
ptr_cmd "G28 Y"
servo_down
ptr_cmd "G1 Y5 F1000"
z_rel "5"
servo_up
ptr_cmd "G28 Y"
z_rel "-5"
}


# Execute bed clearing functions

servo_up
initial_z_check
ptr_cmd "G28 Y"
y_push














