#!/bin/bash
rsync -rvz --exclude '{data.js,data/*,last_reading.js}' . bns-daedalus:/home/pi/cerealbox
