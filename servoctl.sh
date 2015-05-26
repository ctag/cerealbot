#!/bin/bash

if [ -z $1 ]
then
echo "Usage: ./servoctl.sh 000-180"
exit
fi

if [ $1 -ge 0 -a $1 -le 180 ]
then
SRV_CMD="..:s${1}"
echo "Sending servo command: ${SRV_CMD}"
echo -n $SRV_CMD >> /dev/ttyUSB0
exit
fi

echo "Usage: ./servoctl.sh 000-180"
