#!/bin/bash

#
# This script is called after a part has been printed
# If the printer status is agreeable, it will then
# activate a .gcode file to loosen the printed part
# Christopher Bero [bigbero@gmail.com]
#

# Collect variables
. /home/pi/.cerealbox/config
Z_VAR=$1

# Initialize resty
. $CB_DIR/resty

# Setup log file
LOG=/tmp/pop_part.log

# function to print to std, rq, and logfile
function write_msg {
    METHOD=$1
    MSG=$2
    case "$METHOD" in
	*STD*)
	    echo "$MSG"
	;;
    esac
    case "$METHOD" in
	*RQ*)
	    $CB_DIR/rq_msg.sh "$MSG"
	;;
    esac
    case "$METHOD" in
	*LOG*)
	    echo "`date`: ${MSG}" >> $LOG
	;;
    esac
}

MSG="Begin pop_part.sh"
write_msg "LOG,STD" "$MSG"

# Fetch Printer Status
PRINTR_STATUS=`curl -H "X-Api-Key:$OCTO_API_KEY" http://bns-daedalus.256.makerslocal.org/api/printer -o /tmp/printr_status.json`
if [ $? -ne 0 ]; then
    MSG="Status failed, exiting."
    write_msg "LOG,RQ,STD" $MSG
    exit
fi

# Verify printer is ready to pop the part

# Check printer state
cat /tmp/printr_status.json | grep "\"state\": 5,"
PTR_ST=$?
write_msg "STD,LOG" "Printer state: $PTR_ST"
if [ $PTR_ST -eq 1 ]; then
    write_msg "STD,LOG" "Exiting due to printer state."
    exit
else
    write_msg "STD,LOG" "Printer reports state 5."
fi

# Check that printer is Operational
cat /tmp/printr_status.json | grep "\"stateString\": \"Operational\","
PTR_OP=$?
echo "`date`: Printer operational: $PTR_OP" >> $LOG
if [ $PTR_OP -eq 1 ]; then
    write_msg "STD,LOG,RQ" "Exiting due to printer operational string."
    exit
else
    write_msg "STD,LOG" "Printer reports operational status."
fi

write_msg "STD,LOG" "Printer looks good, proceeding to loosen part"

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
    write_msg "STD,LOG" "Done with cycle."
}

write_msg "RQ,STD,LOG" "Activating automatic part adherence mitigation. Please stand clear."

cycle_hotbed
cycle_hotbed
cycle_hotbed
cycle_hotbed

sleep 5m

#exit

write_msg "STD,RQ,LOG" "Finished automatic buildplate cycling."

if [ -z $Z_VAR ]; then
    write_msg "STD,LOG,RQ" "Z is null, not moving print head."
    exit
fi


function ptr_cmd {
    write_msg "STD,LOG" "Sending printer command: $1"
    POST /printer/command "{\"command\":\"$1\"}"
}

# G91 is rel
# G90 is abs

function rel {
    DIR=$1
    DIST=$2

    if [ $DIR != X -a $DIR != Y -a $DIR != Z ]; then
    # No valid direction, exiting
	return
    fi

    if [ $DIR = Z ]; then
	Z_NEW=$(($Z_VAR+$DIST));
	if [ $Z_NEW -lt 14 ]; then
            write_msg "STD,LOG,RQ" "Refusing to move Z below 14mm. Z=14mm."
            DIST=$((14-$Z_VAR))
	    Z_NEW=14
	fi
	Z_VAR=$Z_NEW
	write_msg "STD,LOG" "Moving Z relative: ${DIST}mm; final: ${Z_VAR}mm"
	ptr_cmd "G91"
	ptr_cmd "G1 Z${DIST} F400"
	ptr_cmd "G90"
    fi
    if [ $DIR = X ]; then
	X_NEW=$(($X_VAR+$DIST));
	if [ $X_NEW -lt 0 ]; then
            write_msg "STD,LOG" "Refusing to move X to ${X_NEW}mm. X=0mm."
	    X_NEW=0
	    DIST=$((0-$X_VAR))
	fi
	if [ $X_NEW -gt 125 ]; then
	    write_msg "STD,LOG" "Refusing to move X to ${X_NEW}mm. X=130mm."
	    X_NEW=130
	    DIST=$((130-$X_VAR))
	fi
	X_VAR=$X_NEW
	write_msg "STD,LOG" "Moving X relative: ${DIST}mm; final: ${X_VAR}mm"
	ptr_cmd "G91"
	ptr_cmd "G1 X${DIST} F1300"
	ptr_cmd "G90"
    fi
    if [ $DIR = Y ]; then
	Y_NEW=$(($Y_VAR+$DIST));
	if [ $Y_NEW -lt 0 ] || [ $Y_NEW -gt 140 ]; then
	    write_msg "STD,LOG,RQ" "Refusing to move Y to ${DIST}mm. Halting."
	    exit
	fi
	Y_VAR=$Y_NEW
        write_msg "STD,LOG" "Moving Y relative: ${DIST}mm; final: ${Y_VAR}mm"
	ptr_cmd "G91"
	ptr_cmd "G1 Y${DIST} F1300"
	ptr_cmd "G90"
    fi
}

function reset {
    DIR=$1
    if [ $DIR = X ]; then
    ptr_cmd "G28 X"
    X_VAR=0
fi
if [ $DIR = Y ]; then
    ptr_cmd "G28 Y"
    Y_VAR=145
fi
if [ $DIR = Z ]; then
    ptr_cmd "G28 Z"
    Z_VAR=2
fi
}


function initial_z_check {
Z_MIN=15
    if [ $Z_VAR -lt $Z_MIN ]; then
        #$CB_DIR/rq_msg.sh "Probe is below allowable servo range. Moving probe up to ${Z_MIN}mm."
	Z_DELTA=$(($Z_MIN-$Z_VAR))
        #$CB_DIR/rq_msg.sh "Moving probe by a delta of $Z_DELTA to reach ${Z_MIN}mm."
	rel Z "$Z_DELTA"
        #$CB_DIR/rq_msg.sh "New Z val: $Z_VAR"
    fi
}

function servo {
    if [ $Z_VAR -lt 14 ]; then
        write_msg "STD,LOG,RQ" "not moving bar when Z too low"
        return
    fi
    if [ $Z_VAR -lt 24 -a $Y_VAR -gt 105 ]; then
	write_msg "STD,LOG,RQ" "Not lowering the bar, Y is too high."
	return
    fi
    if [ $1 = "deploy" ]; then
	write_msg "STD,LOG" "Deploying bar."
	$CB_DIR/servoctl.sh "$BAR_DEPLOYED"
    fi
    if [ $1 = "store" ]; then
	write_msg "STD,LOG" "Storing bar."
	$CB_DIR/servoctl.sh "$BAR_STORED"
    fi
    if [ $1 = "forward" ]; then
	write_msg "STD,LOG" "Setting bar forward."
	$CB_DIR/servoctl.sh "$BAR_FORWARD"
    fi
    sleep 1s
}

function y_push {
    #ptr_cmd "G28 Y"
    reset Y
    if [ $Z_VAR -lt 24 ]; then
        rel Y "-40"
        sleep 3s
        servo deploy
        #rel Y "-20"
    else
        servo deploy
    fi
    ptr_cmd "G1 Y5 F1700"
    sleep 5s
    servo forward
    Z_REL=5
    if [ $Z_VAR -lt 24 ]; then
	Z_REL=$((24-$Z_VAR))
    fi
    rel Z $Z_REL
    #ptr_cmd "G28 Y"
    reset Y
    sleep 5s
    servo store
    rel Z "-${Z_REL}"
}

function x_scan {
    ptr_cmd "G28 X"
    X_VAR=0
    while [ $X_VAR -lt 125 ];
    do
	write_msg "STD,LOG" "X is ${X_VAR}mm"
	y_push
	rel "X" 25
    done
}

# Execute bed clearing functions

resty 'http://localhost/api' 1>> $LOG

#ptr_cmd "G28 X"
#X_VAR=0
#ptr_cmd "G28 Y"
#Y_VAR=0
reset X
reset Y
sleep 6s

write_msg "STD,LOG,RQ" "Clearing print bed"
$CB_DIR/fanctl.sh off
servo store
initial_z_check
rel Z "6"
while [ $Z_VAR -gt 14 ]
do
    x_scan
    rel Z "-4"
done
x_scan
write_msg "STD,LOG,RQ" "Should be done clearing print bed."