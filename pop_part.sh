#!/bin/bash

#
# This script is called after a part has been printed
# If the printer status is agreeable, it will then
# do things.
# Christopher Bero [bigbero@gmail.com]
#

# Source common config/vars
. /home/pi/.cerealbox/config
. /home/pi/.cerealbox/write_msg.sh

# Set log file
LOG=/tmp/pop_part.log

# Check number of variables
if [ "$#" -ne 2 ]; then
	write_msg "STD,LOG" "$0 started without 2 arguments. Exiting."
	exit
fi

# Collect variables
FILE=$1
Z_VAR=$2

MSG="Begin pop_part.sh"
write_msg "LOG,STD" "$MSG"

STATUS=`$CB_DIR/printr_status.sh`

if [ "$STATUS" -ne 0 ]; then
	write_msg "LOG,STD" "Printer status is non-zero. Exiting $0."
	exit
fi

write_msg "STD,LOG" "Printer looks good, proceeding with build plate cycling."

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
write_msg "STD,RQ,LOG" "Finished automatic buildplate cycling."

sleep 3m

if [ -z $Z_VAR ]; then
    write_msg "STD,LOG,RQ" "Z is null, not moving print head."
    exit
fi


function ptr_cmd {
    write_msg "STD,LOG" "Sending printer command: $1"
    POST /printer/command "{\"command\":\"$1\"}"
}

function ptr_cmds {
    cmds=""
    for cmd in "$@"
    do
	write_msg "STD,LOG" "[$cmd]"
	if [ "$cmd" = "$1" ]; then
	    cmds="\"${cmd}\""
	else
	    cmds="${cmds},\"${cmd}\""
	fi
    done
    write_msg "STD,LOG" "Sending printer commands: $cmds"
    POST /printer/command "{\"commands\":[$cmds]}"
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
	#ptr_cmd "G91"
	ptr_cmds "G91" "G1 Z${DIST} F800" "G90"
	#ptr_cmd "G90"
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
	#ptr_cmd "G91"
	ptr_cmds "G91" "G1 X${DIST} F5000" "G90"
	#ptr_cmd "G90"
    fi
    if [ $DIR = Y ]; then
	Y_NEW=$(($Y_VAR+$DIST));
	if [ $Y_NEW -lt 0 ] || [ $Y_NEW -gt 140 ]; then
	    write_msg "STD,LOG,RQ" "Refusing to move Y to ${DIST}mm. Halting."
	    exit
	fi
	Y_VAR=$Y_NEW
        write_msg "STD,LOG" "Moving Y relative: ${DIST}mm; final: ${Y_VAR}mm"
	#ptr_cmd "G91"
	ptr_cmds "G91" "G1 Y${DIST} F5000" "G90"
	#ptr_cmd "G90"
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
        write_msg "STD,LOG" "not moving bar when Z too low"
        return
    fi
    if [ $Z_VAR -lt 24 -a $Y_VAR -gt 115 ]; then
	write_msg "STD,LOG" "Not lowering the bar, Y is too high."
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
        rel Y "-30"
        sleep 3s
        servo deploy
    else
        servo deploy
    fi
    ptr_cmd "G1 Y5 F5000"
    sleep 3s
    servo forward
    Z_REL=5
    if [ $Z_VAR -lt 24 ]; then
	Z_REL=$((24-$Z_VAR))
    fi
    rel Z $Z_REL
    #ptr_cmd "G28 Y"
    ptr_cmd "G1 Y145 F5000"
    sleep 3s
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
sleep 4s

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

# Release flag set in print_start.sh
export CB_BUSY=0

