#!/bin/bash
if [ $1 == on ]
then
echo Turning on the fan.
echo -n .. :fi >> /dev/ttyUSB0
fi
if [ $1 == off ]
then
echo Turning off the fan.
echo -n ..:fo >> /dev/ttyUSB0
fi
