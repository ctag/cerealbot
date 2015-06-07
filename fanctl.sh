#!/bin/bash

if [ -z $1 ]
then
echo "Usage: ./fanctl.sh on|off"
exit
fi

if [ $1 == on ]
then
echo Turning on the fan.
echo -n ..:fi >> /dev/ttyAMA0
exit
fi
if [ $1 == off ]
then
echo Turning off the fan.
echo -n ..:fo >> /dev/ttyAMA0
exit
fi

echo "Usage: ./fanctl.sh on|off"
