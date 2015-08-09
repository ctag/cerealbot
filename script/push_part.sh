#!/bin/bash

# Push part off bed

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Check if the dirs are sourced
if [ ! -d "$UTIL_DIR" ]; then
	. "$LOCAL_DIR/dirs"
fi

# Source common config/vars
. $UTIL_DIR/util

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

printr_status
STATUS=$?

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

    if [ "$DIR" != "X" ] && [ "$DIR" != "Y" ] && [ "$DIR" != "Z" ]; then
    # No valid direction, exiting
	return
    fi

    if [ "$DIR" = "Z" ]; then
		Z_NEW=$(($Z_VAR+$DIST));
		if [ $Z_NEW -lt $Z_MIN ]; then
			write_msg "STD,LOG" "Refusing to move Z by ${DIST} to ${Z_NEW}mm. Z=${Z_MIN}mm." "$LOG"
			DIST=$(($Z_MIN - $Z_VAR))
			Z_NEW=$Z_MIN
		fi
		Z_VAR=$Z_NEW
		write_msg "STD,LOG" "Moving Z relative: ${DIST}mm; final: ${Z_VAR}mm" "$LOG"
		printr_cmd "G91" "G1 Z${DIST} F800" "G90"
    fi
    if [ "$DIR" = "X" ]; then
		X_NEW=$(($X_VAR+$DIST));
		if [ $X_NEW -lt $X_MIN ]; then
			write_msg "STD,LOG" "Refusing to move X by ${DIST} to ${X_NEW}mm. X=${X_MIN}mm." "$LOG"
			X_NEW=$X_MIN
			DIST=$(($X_MIN-$X_VAR))
		elif [ $X_NEW -gt $X_MAX ]; then
			write_msg "STD,LOG" "Refusing to move X by ${DIST} to ${X_NEW}mm. X=${X_MAX}mm." "$LOG"
			X_NEW=$X_MAX
			DIST=$(($X_MAX-$X_VAR))
		fi
		X_VAR=$X_NEW
		write_msg "STD,LOG" "Moving X relative: ${DIST}mm; final: ${X_VAR}mm" "$LOG"
		printr_cmd "G91" "G1 X${DIST} F5000" "G90"
    fi
    if [ "$DIR" = "Y" ]; then
		Y_NEW=$(($Y_VAR + $DIST));
		if [ $Y_NEW -lt $Y_MIN ]; then
			write_msg "STD,LOG" "Refusing to move Y by ${DIST} to ${Y_NEW}mm. Y=${Y_MIN}mm." "$LOG"
			Y_NEW=$Y_MIN
			DIST=$(($Y_MIN-$Y_VAR))
		elif [ $Y_NEW -gt $Y_MAX ]; then
			write_msg "STD,LOG" "Refusing to move Y by ${DIST} to ${Y_NEW}mm. Y=${Y_MAX}mm." "$LOG"
			Y_NEW=$Y_MAX
			DIST=$(($Y_MAX-$Y_VAR))
		fi
		Y_VAR=$Y_NEW
		write_msg "STD,LOG" "Moving Y relative: ${DIST}mm; final: ${Y_VAR}mm"
		printr_cmd "G91" "G1 Y${DIST} F5000" "G90"
    fi
}

function reset {
    DIR=$1
    if [ "$DIR" = "X" ]; then
		printr_cmd "G28 X"
		X_VAR=$X_MIN
	fi
	if [ "$DIR" = "Y" ]; then
		printr_cmd "G28 Y"
		Y_VAR=$Y_MAX
	fi
	if [ "$DIR" = "Z" ]; then
		printr_cmd "G28 Z"
		Z_VAR=2
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
    if [ "$1" = "deploy" ]; then
		write_msg "STD,LOG" "Deploying bar." "$LOG"
		servoctl "$BAR_DEPLOYED"
    fi
    if [ "$1" = "store" ]; then
		write_msg "STD,LOG" "Storing bar." "$LOG"
		servoctl "$BAR_STORED"
    fi
    if [ "$1" = "forward" ]; then
		write_msg "STD,LOG" "Setting bar forward." "$LOG"
		servoctl "$BAR_FORWARD"
    fi
    if [ "$1" = "push" ]; then
		write_msg "STD,LOG" "Setting bar to push." "$LOG"
		servoctl "$BAR_PUSH"
    fi
    sleep 1s
}

function y_push {
    if [ "$FINAL_SCAN" != 'true' ]; then
	if [ $Z_VAR -lt $Z_SWING ]; then
            rel "Y" "$Y_SWING"
            sleep 3s
	fi
	servo deploy
    fi
    printr_cmd "G1 Y${Y_MIN} F5000"
    Y_VAR=$Y_MIN
    sleep 3s
    if [ "$FINAL_SCAN" != 'true' ]; then
	servo forward
	Z_REL=0
	if [ $Z_VAR -lt $Z_SWING ]; then
	    Z_REL=$(($Z_SWING-$Z_VAR))
	    rel "Z" "$Z_REL"
	fi
    fi
    printr_cmd "G1 Y${Y_MAX} F5000"
    Y_VAR=$Y_MAX
    sleep 3s
    if [ "$FINAL_SCAN" != 'true' ]; then
	servo store
	if [ $Z_REL -ne 0 ]; then
	    rel Z "-${Z_REL}"
	fi
    fi
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
	write_msg "STD,LOG" "X is ${X_VAR}mm" "$LOG"
 	y_push
}

# Execute bed clearing functions

reset X
reset Y
sleep 10s

write_msg "STD,LOG,RQ" "Clearing print bed" "$LOG"
fanctl "off"
servo store

rel "Z" "$Z_STEP"

while [ $Z_VAR -gt $Z_MIN ]
do
    x_scan
    rel "Z" "-${Z_STEP}"
done
x_scan

function not_implemented {
FINAL_SCAN='true'
reset X
reset Y
printr_cmd "G0 Z30 F400"
Z_VAR=30
sleep 4s
servo push
sleep 4s
printr_cmd "G0 Z2 F400"
Z_VAR=2
x_scan
printr_cmd "G0 Z30 F400"
Z_VAR=30
sleep 6s
servo store
Z_VAR=2
FINAL_SCAN='false'
}

not_implemented

write_msg "STD,LOG,RQ" "Should be done clearing print bed." "$LOG"


