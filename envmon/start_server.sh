#!/bin/bash

# This script manages ac_mon.py

#echo $$ > /tmp/envmon_server.pid

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

cd $LOCAL_DIR

# Setup virtualenv
. $LOCAL_DIR/venv/bin/activate

python -m SimpleHTTPServer 8081 & echo $! > /tmp/envmon_server.pid

deactivate

