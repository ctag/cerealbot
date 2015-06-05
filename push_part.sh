#!/bin/bash

# Push part off bed

# Source config
if [ ! -d "$CB_DIR" ]; then
	CB_DIR=`dirname $0`
fi

# Source common config/vars
. $CB_DIR/util.sh

# Set log file
LOG=/tmp/push_part.log

# Check number of variables
if [ $# -ne 2 ]; then
	write_msg "STD,LOG" "$0 started without 2 arguments. Exiting." "$LOG"
	exit
fi

# Collect variables
FILE=$1
Z_VAR=$2

MSG="Begin push_part.sh"
write_msg "LOG,STD" "$MSG" "$LOG"

STATUS=printr_status

if [ $STATUS -ne 0 ]; then
	write_msg "LOG,STD" "Printer status is non-zero. Exiting $0." "$LOG"
	exit
fi

if [ -z $Z_VAR ]; then
    write_msg "STD,LOG,RQ" "Z is null, not moving print head." "$LOG"
    exit
fi

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
	if [ $Z_NEW -lt $Z_MIN ]; then
            write_msg "STD,LOG,RQ" "Refusing to move Z below 14mm. Z=14mm." "$LOG"
            DIST=$(($Z_MIN - $Z_VAR))
	    Z_NEW=$Z_MIN
	fi
	Z_VAR=$Z_NEW
	write_msg "STD,LOG" "Moving Z relative: ${DIST}mm; final: ${Z_VAR}mm" "$LOG"
	printr_cmd "G91" "G1 Z${DIST} F800" "G90"
    fi
    if [ $DIR = X ]; then
	X_NEW=$(($X_VAR+$DIST));
	if [ $X_NEW -lt $X_MIN ]; then
            write_msg "STD,LOG" "Refusing to move X to ${X_NEW}mm. X=0mm." "$LOG"
	    X_NEW=0
	    DIST=$((0-$X_VAR))
	fi
	if [ $X_NEW -gt $X_MAX ]; then
	    write_msg "STD,LOG" "Refusing to move X to ${X_NEW}mm. X=130mm." "$LOG"
	    X_NEW=130
	    DIST=$(($X_MAX-$X_VAR))
	fi
	X_VAR=$X_NEW
	write_msg "STD,LOG" "Moving X relative: ${DIST}mm; final: ${X_VAR}mm" "$LOG"
	printr_cmd "G91" "G1 X${DIST} F5000" "G90"
    fi
    if [ $DIR = Y ]; then
	Y_NEW=$(($Y_VAR+$DIST));
	if [ $Y_NEW -lt $Y_MIN ] || [ $Y_NEW -gt $Y_MAX ]; then
	    write_msg "STD,LOG,RQ" "Refusing to move Y to ${DIST}mm. Halting." "$LOG"
	    exit
	fi
	Y_VAR=$Y_NEW
        write_msg "STD,LOG" "Moving Y relative: ${DIST}mm; final: ${Y_VAR}mm"
	printr_cmd "G91" "G1 Y${DIST} F5000" "G90"
    fi
}

function reset {
    DIR=$1
    if [ $DIR = X ]; then
    printr_cmd "G28 X"
    X_VAR=0
fi
if [ $DIR = Y ]; then
    printr_cmd "G28 Y"
    Y_VAR=145
fi
if [ $DIR = Z ]; then
    printr_cmd "G28 Z"
    Z_VAR=2
fi
}


function initial_z_check {
    if [ $Z_VAR -lt $Z_MIN ]; then
        #$CB_DIR/rq_msg.sh "Probe is below allowable servo range. Moving probe up to ${Z_MIN}mm."
	Z_DELTA=$(($Z_MIN-$Z_VAR))
        #$CB_DIR/rq_msg.sh "Moving probe by a delta of $Z_DELTA to reach ${Z_MIN}mm."
	rel Z "$Z_DELTA"
        #$CB_DIR/rq_msg.sh "New Z val: $Z_VAR"
    fi
}

function servo {
    if [ $Z_VAR -lt $Z_MIN ]; then
        write_msg "STD,LOG" "not moving bar when Z too low" "$LOG"
        return
    fi
    if [ $Z_VAR -lt $Z_STEP ] && [ $Y_VAR -gt $(($Y_MAX-$Y_SWING)) ]; then
	write_msg "STD,LOG" "Not lowering the bar, Y is too high." "$LOG"
	return
    fi
    if [ $1 = "deploy" ]; then
	write_msg "STD,LOG" "Deploying bar." "$LOG"
	servoctl "$BAR_DEPLOYED"
    fi
    if [ $1 = "store" ]; then
	write_msg "STD,LOG" "Storing bar." "$LOG"
	servoctl "$BAR_STORED"
    fi
    if [ $1 = "forward" ]; then
	write_msg "STD,LOG" "Setting bar forward." "$LOG"
	servoctl "$BAR_FORWARD"
    fi
    sleep 1s
}

function y_push {
    reset Y
    if [ $Z_VAR -lt $Z_SWING ]; then
        rel Y "$Y_SWING"
        sleep 3s
        servo deploy
    else
        servo deploy
    fi
    printr_cmd "G1 Y${Y_MIN} F5000"
    sleep 3s
    servo forward
    Z_REL=5
    if [ $Z_VAR -lt 24 ]; then
	Z_REL=$(($Z_SWING-$Z_VAR))
    fi
    rel "Z" "$Z_REL"
    printr_cmd "G1 Y${Y_MAX} F5000"
    sleep 3s
    servo store
    rel Z "-${Z_REL}"
}

function x_scan {
    printr_cmd "G28 X"
    X_VAR=0
    while [ $X_VAR -lt $X_MAX ];
    do
	write_msg "STD,LOG" "X is ${X_VAR}mm" "$LOG"
	y_push
	rel "X" "$X_STEP"
    done
}

# Execute bed clearing functions

resty 'http://localhost/api' 1>> $LOG

reset X
reset Y
sleep 4s

write_msg "STD,LOG,RQ" "Clearing print bed" "$LOG"
$CB_DIR/fanctl.sh off
servo store
initial_z_check
rel "Z" "${Z_STEP}"
while [ $Z_VAR -gt $Z_MIN ]
do
    x_scan
    rel "Z" "-${Z_STEP}"
done
x_scan
write_msg "STD,LOG,RQ" "Should be done clearing print bed." "$LOG"



