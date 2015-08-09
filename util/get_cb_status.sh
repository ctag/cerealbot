#!/bin/bash

# Printer Status
# Returns 0 on success

# Failure code
RETFAIL=1

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

# Check if the dirs are sourced
if [ ! -d "$UTIL_DIR" ]; then
	. "$LOCAL_DIR/dirs"
fi

. $LOCAL_DIR/config

# Fetch Printer Status
PRINTR_STATUS=`curl -H "X-Api-Key:$OCTO_API_KEY" http://bns-daedalus.berocs.com/api/printer -o /tmp/printr_status.json`
if [ $? -ne 0 ]; then
    echo "Status failed, exiting."
    exit "$RETFAIL"
fi

# Verify printer is ready to pop the part

# Check printer state
cat /tmp/printr_status.json | grep "\"state\": 5,"
PTR_ST=$?
echo "Printer state: $PTR_ST"
if [ $PTR_ST -eq 1 ]; then
    echo "Exiting due to printer state."
    exit "$RETFAIL"
else
    echo "Printer reports state 5."
fi

# Check that printer is Operational
cat /tmp/printr_status.json | grep "\"stateString\": \"Operational\","
PTR_OP=$?
echo "`date`: Printer operational: $PTR_OP"
if [ $PTR_OP -eq 1 ]; then
    echo "Exiting due to printer operational string."
    exit "$RETFAIL"
else
    echo "Printer reports operational status."
fi

exit 0



