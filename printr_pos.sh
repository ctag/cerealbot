#!/bin/bash

# This script will report the location of the printer's hotend

RESPONSE=`curl -H "X-Api-Key: $OCTO_API_KEY" -F command=M114 "bns-daedalus.256.makerslocal.org:8081/api/printer/command"`

echo ${RESPONSE}

