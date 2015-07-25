#!/bin/bash

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

#. $LOCAL_DIR/config

# Setup virtualenv
. $LOCAL_DIR/venv/bin/activate

AVR_DEV=/dev/ttyAMA0

TEMP=$(python $LOCAL_DIR/collect.py $AVR_DEV temp)
HUM=$(python $LOCAL_DIR/collect.py $AVR_DEV hum)

LOOP=0

while [ $LOOP -lt 6 ] && ( [ $TEMP -lt 1 ] || [ $HUM -lt 1 ] )
do
	echo "Serial busy, waiting 5 minutes. $LOOP"
	LOOP=$((LOOP+1))
	sleep 2s
	TEMP=$(python $LOCAL_DIR/collect.py $AVR_DEV temp)
	HUM=$(python $LOCAL_DIR/collect.py $AVR_DEV hum)
done

TZ='America/Chicago'
export TZ

YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`
HOUR=`date +%H`
DATA_DIR="${LOCAL_DIR}/data/${YEAR}/${MONTH}/${DAY}"
DATA_FILE="${DATA_DIR}/${HOUR}"

echo "Writing to: ${DATA_FILE}"

mkdir -p "$DATA_DIR"

echo "${TEMP} ${HUM}" > "$DATA_FILE"

LONGTIME=`date +%c`
LR=$LOCAL_DIR/last_reading.js

echo "time=\"${LONGTIME}\";" > $LR
echo "temp=${TEMP};" >> $LR
echo "hum=${HUM};" >> $LR

$LOCAL_DIR/assemble.sh

exit












if [ $RET -eq 0 ] && [ $VAL -eq 0 ]; then
	MSG="Sensors indicate the Fabrication Laboratory's condensed humidity reservior has reached maximum capacity."
	curl --request POST \
	--url https://crump.space/rq-dev/api/v1.0/messages \
	--header 'content-type: application/json' \
	--data "{\"type\":\"command\",\"key\":\"${RQ_ML_KEY}\",\"destination\":\"rqirc\",\"data\":{\"channel\":\"##rqtest\",\"isaction\":false,\"message\":\"${MSG}\"}}"
fi

#write_msg "RQ" "$MSG"

#deactivate

function check_port {
echo "Checking $AVR_DEV against"
# Check that the right serial port is available
python -m serial.tools.list_ports | while read -r port
do
    echo "$port"
    if [ "$AVR_DEV" = "$port" ]; then
        # The right device exists, check's good
        python $LOCAL_DIR/ac_mon.py
        deactivate
        exit
    fi
done
}


