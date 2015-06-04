#!/bin/bash

# function to print to std, rq, and logfile
# Source this file with '. write_msg.sh' and then
# use the function normally

function write_msg {
	if [ "$#" -ne 2 ]; then
		$CB_DIR/rq_msg.sh "[CB]: Alert - write_msg function is being called with bad arguments. Details in /tmp/write_msg.log."
		echo "`date`: All arguments: $@" >> /tmp/write_msg.log
		return
	fi
    METHOD=$1
    MSG=$2
    case "$METHOD" in
	*STD*)
	    echo "$MSG"
	;;
    esac
    case "$METHOD" in
	*RQ*)
	    $CB_DIR/rq_msg.sh "[CB]: $MSG"
	;;
    esac
    case "$METHOD" in
	*LOG*)
	    echo "`date`: ${MSG}" >> $LOG
	;;
    esac
}
