#!/bin/bash

API_KEY=47CEB560F2AD4B7F851E7DF1C7C31CA1

PRINTR_STATUS=`curl -H "X-Api-Key:$API_KEY" http://localhost:8081/api/printer -o /tmp/printr_status.json`

echo `cat /tmp/printr_status.json | grep ready`

