#!/bin/bash

ino build -m atmega328
ino upload -m atmega328 -p /dev/ttyAMA0
