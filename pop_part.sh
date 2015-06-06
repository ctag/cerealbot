#!/bin/bash

#
# This script is called after a part has been printed
# If the printer status is agreeable, it will then
# do things.
# Christopher Bero [bigbero@gmail.com]
#

# Source config
if [ ! -d "$CB_DIR" ]; then
	CB_DIR=`dirname $0`
fi

# Source common config/vars
. $CB_DIR/util.sh

# Set log file
LOG=/tmp/pop_part.log

# Check number of variables
if [ "$#" -ne 2 ]; then
	write_msg "STD,LOG" "$0 started without 2 arguments. Exiting." "$LOG"
	exit
fi

# Collect variables
FILE=$1
Z_VAR=$2

MSG="Begin pop_part.sh"
write_msg "LOG,STD" "$MSG" "$LOG"

STATUS=printr_status

if [ "$STATUS" -ne 0 ]; then
	write_msg "LOG,STD" "Printer status is non-zero. Exiting $0." "$LOG"
	exit
fi

write_msg "STD,LOG" "Printer looks good, proceeding with build plate cycling." "$LOG"

function cycle_hotbed {
# Set resty url
    resty http://localhost/api
# Make sure fan is off
    fanctl "off"
# Turn on hotbed
    printr_cmd "M140 S60"
    sleep 6m
# Turn off hotbed
    printr_cmd "M140 S0"
    sleep 30s
    fanctl "on"
    sleep 20m
    fanctl "off"
    sleep 1m
    write_msg "STD,LOG" "Done with cycle." "$LOG"
}

write_msg "RQ,STD,LOG" "Activating automatic part adherence mitigation. Please stand clear." "$LOG"
cycle_hotbed
cycle_hotbed
cycle_hotbed
#cycle_hotbed
write_msg "STD,RQ,LOG" "Finished automatic buildplate cycling." "$LOG"










