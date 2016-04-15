#!/bin/bash

# This script will halt a print

APIKEY="A8C4243A942E47ACB5A227C75C3AD338"
URL="bns-daedalus.256.makerslocal.org:8080"

RESPONSE=`curl -H "X-Api-Key: ${APIKEY}" -H "Content-Type: application/json" -d '{"command" : "pause"}' "${URL}/api/job"`

echo ${RESPONSE}

