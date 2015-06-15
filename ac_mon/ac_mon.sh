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

RET=$(python $LOCAL_DIR/ac_mon.py $AVR_DEV)

echo "Return status: $RET"

MSG="Testing cron job; "

if [ $RET -eq 1 ]; then
	MSG+="Fablab ac bucket is full!"
else
	MSG+="Fablab ac bucket is not full."
fi

write_msg "RQ" "$MSG"

deactivate

function check_port {
echo "Checking $AVR_DEV against"
# Check that the right serial port is available
python -m serial.tools.list_ports | while read -r port
do
    echo "$port"
    if [ "$AVR_DEV" = "$port" ]; then
        # The right device exists, check's good
        python $LOCAL_DIR/ac_mon.py
        deactivate
        exit
    fi
done
}


