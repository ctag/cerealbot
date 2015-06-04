#!/bin/bash

# Helper script
# Accept string input and write it to irc channels

# Load user defined variables
. /home/pi/.cerealbox/config

# Set resty url
resty 'https://crump.space/rq'

# Set Logfile
LOG=/tmp/cb_rq_msg.log
MSG=$1

# Write to logfile
$CB_DIR/rq_msg.sh "LOG" "Writing message [$MSG] to RedQueen." "$LOG"

# Make API call
POST /relay "{\"message\":\"${MSG}\", \"channel\":\"##rqtest\", \"isaction\":false, \"key\":\"$RQ_API_KEY\"}" >> $LOG



