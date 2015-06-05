#!/bin/bash

# Collection of helper functions for CerealBot
# Source file with '. /.../util.sh'

if [ ! -d "$CB_DIR" ]; then
	CB_DIR=`dirname $0`
fi

. $CB_DIR/config

# Accept string input and write it to irc channels
function rq_msg {
	$CB_DIR/rq_msg.sh "$@"
}

# function to print to std, rq, and logfile
function write_msg {
	$CB_DIR/write_msg.sh "$@"
}

# Forward arguments to servoctl.sh
function servoctl {
	$CB_DIR/servoctl.sh "$@"
}

# Forward arguments to fanctl.sh
function fanctl {
	$CB_DIR/fanctl.sh "$@"
}

# Forward arguments to printr_status.sh
function printr_status {
	$CB_DIR/printr_status.sh "$@"
}

# Forward arguments to printr_cmd.sh
function printr_cmd {
	$CB_DIR/printr_cmd.sh "$@"
}


















