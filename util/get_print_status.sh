#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

APIKEY=$1

RESPONSE=`curl -i -H "Accept: application/json" -H "X-Api-Key: ${APIKEY}" "bns-daedalus.berocs.com/api/job"`

echo ${RESPONSE}

