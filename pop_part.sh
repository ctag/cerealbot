#!/bin/bash

#
# This script is called after a part has been printed
# If the printer status is agreeable, it will then
# activate a .gcode file to loosen the printed part
# Christopher Bero [bigbero@gmail.com]
#

# Collect variables
Z_VAR=$1

# Initiate resty
. $CB_DIR/resty

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
resty http://localhost/api
# Make sure fan is off
$CB_DIR/fanctl.sh "off"
# Turn on hotbed to 70C
POST /printer/command '{"command":"M140 S70"}'
sleep 8m
# Turn off hotbed
POST /printer/command '{"command":"M140 S0"}'
sleep 2m
$CB_DIR/fanctl.sh "on"
sleep 25m
$CB_DIR/fanctl.sh "off"
sleep 5m
echo "`date`: Done with cycle." >> $LOG

}

#$CB_DIR/rq_msg.sh "Activating automatic part adherence mitigation. Please stand clear."

#cycle_hotbed
#cycle_hotbed
#cycle_hotbed
#cycle_hotbed

#$CB_DIR/rq_msg.sh "Finished automatic buildplate cycling."

if [ -z $Z_VAR ]; then
MSG="Z is null, not moving print head."
$CB_DIR/rq_msg.sh $MSG
echo $MSG >> $LOG
exit
fi


function ptr_cmd {
echo "Sending printer command: $1"
POST /printer/command "{\"command\":\"$1\"}" 1>> $LOG
}

# G91 is rel
# G90 is abs

function z_rel {
DIST=$1
Z_NEW=$(($Z_VAR+$DIST));
if [ $Z_NEW -lt 25 ]; then
echo "Refusing to move Z below 25mm. Setting Z = 25mm."
DIST=$((25-$Z_VAR))
fi
Z_VAR=$(($Z_VAR+$DIST));
echo "Moving Z relative: ${DIST}mm; final: ${Z_VAR}mm"
ptr_cmd "G91"
ptr_cmd "G1 Z${DIST} F400"
ptr_cmd "G90"
}

function reset_x {
ptr_cmd "G28 X"
X_VAR=0
}


function initial_z_check {
if [ $Z_VAR -lt 22 ]; then
#$CB_DIR/rq_msg.sh "Probe is below allowable servo range. Moving probe up to 22mm."
Z_DELTA=$((22-$Z_VAR))
#$CB_DIR/rq_msg.sh "Moving probe by a delta of $Z_DELTA to reach 22mm."
z_rel "$Z_DELTA"
#$CB_DIR/rq_msg.sh "New Z val: $Z_VAR"
fi
}

function servo {
if [ $1 = "deploy" ]; then
echo "Activating bar."
$CB_DIR/servoctl.sh "$BAR_DEPLOYED"
fi
if [ $1 = "store" ]; then
echo "Storing bar."
$CB_DIR/servoctl.sh "$BAR_STORED"
fi
if [ $1 = "forward" ]; then
echo "Setting bar forward."
$CB_DIR/servoctl.sh "$BAR_FORWARD"
fi
sleep 1s
}

function y_push {
ptr_cmd "G28 Y"
servo deploy
ptr_cmd "G1 Y5 F1700"
sleep 5s
servo forward
z_rel "10"
ptr_cmd "G28 Y"
sleep 5s
servo store
z_rel "-10"
}

function x_scan {
ptr_cmd "G28 X"
X_VAR=0
while [ $X_VAR -lt 120 ];
do
echo "X is ${X_VAR}mm"
y_push
X_VAR=$(($X_VAR+20))
ptr_cmd "G1 X${X_VAR} F1500"
done
}

# Execute bed clearing functions

ptr_cmd "G28 X"
X_VAR=0
ptr_cmd "G28 Y"
Y_VAR=0
sleep 6s

resty 'http://localhost/api' 1>> $LOG
MSG="Clearing print bed"
echo $MSG >> $LOG
$CB_DIR/fanctl.sh off
servo store
initial_z_check
z_rel "6"
while [ $Z_VAR -gt 22 ]
do
x_scan
z_rel "-2"
done













