#!/bin/bash

# This script will check the status of a print
# and have ReqQueen alert me when a print is done.

APIKEY=$1

RESPONSE=`curl -i -H "Accept: application/json" -H "X-Api-Key: ${APIKEY}" "bns-daedalus.256.makerslocal.org:8081/api/job"`

echo ${RESPONSE}
