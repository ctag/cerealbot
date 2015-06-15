#!/bin/bash

# This script manages ac_mon.py

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Check if the dirs are sourced
if [ ! -d "$UTIL_DIR" ]; then
	. "$LOCAL_DIR/dirs"
fi

# Source helper scripts and variables
. $UTIL_DIR/util

# Setup virtualenv
. $LOCAL_DIR/venv/bin/activate

# Check that the right serial port is available
python -m serial.tools.list_ports | while read -r port
do
    if [ $AVR_DEV = $port ]; then
        # The right device exists, check's good
        python $LOCAL_DIR/ac_mon.py
        deactivate
        exit
    fi
done



