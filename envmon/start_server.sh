#!/bin/bash

# This script manages ac_mon.py

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Setup virtualenv
. $LOCAL_DIR/venv/bin/activate

python -m SimpleHTTPServer 8001

deactivate

