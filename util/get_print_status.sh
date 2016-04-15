#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

APIKEY=$1
URL="bns-daedalus.256.makerslocal.org:8080"

RESPONSE=`curl -i -H "Accept: application/json" -H "X-Api-Key: ${APIKEY}" "${URL}/api/job"`

echo ${RESPONSE}

