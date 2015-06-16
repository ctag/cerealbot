#!/bin/bash

# Set local directory variable
if [ ! -d "$LOCAL_DIR" ]; then
	LOCAL_DIR="$( dirname "$( readlink -f "$0" )" )"
fi

t_data="temp_data=["
h_data="hum_data=["

function load_data {
echo "All: $@"
temp=$1
hum=$2
echo "Loading: $temp $hum"
if [ $t_data == "[" ]; then
t_data+="$temp"
h_data+="$hum"
else
t_data+=",$temp"
h_data+=",$hum"
fi
}

DIR=$LOCAL_DIR/data

#for YEAR in $DIR/*
#do

#for MONTH in $DIR/$YEAR/*
#do

#for DAY in $DIR/$YEAR/$MONTH/*
#do

#for FILE in $DIR/$YEAR/$MONTH/$DAY/*
for FILE in $DIR/*/*/*/*
do

#cat $DIR/$YEAR/$MONTH/$DAY/$FILE | load_data
echo "$FILE"
load_data $(cat $FILE)

done # hour

#done # day

#done # month

#done # year

t_data+="];"
h_data+="];"

echo "$t_data" > data.js 
echo "$h_data" >> data.js

