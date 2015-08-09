#!/bin/bash

# This script will report the location of the printer's hotend

RESPONSE=`curl -H "X-Api-Key: $OCTO_API_KEY" -F command=M114 "bns-daedalus.berocs.com/api/printer/command"`

echo ${RESPONSE}

