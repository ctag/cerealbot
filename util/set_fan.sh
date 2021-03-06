#!/bin/bash

# Fan Control

# Set local directory
LOCAL_DIR=`dirname $0`

. "$LOCAL_DIR/dirs"

. "$UTIL_DIR/config"

if [ -z $1 ]
then
echo "Usage: ./set_fan.sh on|off"
exit
fi

if [ $1 == on ]
then
echo Turning on the fan.
echo ..:sf1 >> "$AVR_DEV"
node /home/berocs/cerealbot-serial/request/fanOn.js
exit
fi

if [ $1 == off ]
then
echo Turning off the fan.
echo ..:sf0 >> "$AVR_DEV"
node /home/berocs/cerealbot-serial/request/fanOff.js
exit
fi

echo "Usage: ./fanctl.sh on|off"
