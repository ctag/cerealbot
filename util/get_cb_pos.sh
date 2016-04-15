#!/bin/bash

# This script will report the location of the printer's hotend

OCTO_API_KEY=$1

RESPONSE=`curl -H "X-Api-Key: $OCTO_API_KEY" -H "Content-Type: application/json" -d '{"command" : "M114"}' "bns-daedalus.256.makerslocal.org:8080/api/printer/command"`

echo ${RESPONSE}

