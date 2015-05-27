#!/bin/bash

# Accept string input and write it to irc channels

# set up resty
. resty
resty 'https://crump.space/rq'

# Log action
LOG=/tmp/rq_msg.log
echo "`date`: Writing message [$1] to RedQueen." >> $LOG

POST /relay "{\"message\":\"$1\", \"channel\":\"##rqtest\", \"isaction\":false, \"key\":\"$RQ_API_KEY\"}"



