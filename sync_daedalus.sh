#!/bin/bash
rsync -rvz --exclude '{data.js,data/*,last_reading.js,*venv*/}' . bns-daedalus:/home/berocs/cerealbox
