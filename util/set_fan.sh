#!/bin/bash

# Fan Control

# Set local directory
LOCAL_DIR=`dirname $0`

. "$LOCAL_DIR/dirs"

. "$UTIL_DIR/config"

if [ -z $1 ]
then
echo "Usage: ./fanctl.sh on|off"
exit
fi

if [ $1 == on ]
then
echo Turning on the fan.
echo -n ..:fi >> "$AVR_DEV"
exit
fi
if [ $1 == off ]
then
echo Turning off the fan.
echo -n ..:fo >> "$AVR_DEV"
exit
fi

echo "Usage: ./fanctl.sh on|off"
