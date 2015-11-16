#!/bin/bash

# LED Light Control

# Set local directory
LOCAL_DIR=`dirname $0`

. "$LOCAL_DIR/dirs"

. "$UTIL_DIR/config"

if [ -z $1 ]
then
echo "Usage: ./set_light.sh on|off"
exit
fi

if [ $1 == on ]
then
echo Turning on the light.
echo ..:sl1 >> "$AVR_DEV"
node /home/berocs/cerealbot-serial/request/lightOn.js
exit
fi

if [ $1 == off ]
then
echo Turning off the light.
echo ..:sl0 >> "$AVR_DEV"
node /home/berocs/cerealbot-serial/request/lightOff.js
exit
fi

echo "Usage: ./fanctl.sh on|off"
