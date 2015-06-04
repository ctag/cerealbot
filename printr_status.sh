#!/bin/bash

# Printer Status
# Returns 0 on success

# Failure code
RETFAIL=1

# Setup log file
LOG=/tmp/printr_status.log
. /home/pi/.cerealbox/config
. /home/pi/cerealbox/write_msg.sh

# Fetch Printer Status
PRINTR_STATUS=`curl -H "X-Api-Key:$OCTO_API_KEY" http://bns-daedalus.256.makerslocal.org/api/printer -o /tmp/printr_status.json`
if [ $? -ne 0 ]; then
    MSG="Status failed, exiting."
    write_msg "LOG,STD" $MSG
    exit "$RETFAIL"
fi

# Verify printer is ready to pop the part

# Check printer state
cat /tmp/printr_status.json | grep "\"state\": 5,"
PTR_ST=$?
write_msg "STD,LOG" "Printer state: $PTR_ST"
if [ $PTR_ST -eq 1 ]; then
    write_msg "STD,LOG" "Exiting due to printer state."
    exit "$RETFAIL"
else
    write_msg "STD,LOG" "Printer reports state 5."
fi

# Check that printer is Operational
cat /tmp/printr_status.json | grep "\"stateString\": \"Operational\","
PTR_OP=$?
echo "`date`: Printer operational: $PTR_OP" >> $LOG
if [ $PTR_OP -eq 1 ]; then
    write_msg "STD,LOG" "Exiting due to printer operational string."
    exit "$RETFAIL"
else
    write_msg "STD,LOG" "Printer reports operational status."
fi

exit 0



