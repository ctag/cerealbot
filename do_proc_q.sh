
LOG=/tmp/print_new.log

# Source variables
if [ ! -d "$CB_DIR" ]; then
        CB_DIR=`dirname $0`
fi
. $CB_DIR/util.sh

printr_status
STATUS=$?

function check_status {
if [ $STATUS -ne 0 ]; then
        write_msg "LOG,STD" "Printer status is non-zero. Exiting $0." "$LOG"
        exit
fi
if [ $CB_BUSY = "true" ]; then
        write_msg "LOG,STD" "CB_BUSY variable is set. Exiting $0." "$LOG"
	exit
fi
}

check_status

sleep 5m

check_status

write_msg "LOG,STD" "Printer appears to be free, looking for something to print." "$LOG"

. resty

resty http://localhost/api >> /dev/null

GET /files/local | grep name | awk '{ print $2 }' | sed s/,// | sed s/\"// | sed s/\"// | while read -r file
do
write_msg "LOG,STD" "Checking file: $file" "$LOG"
file_status=`GET "/files/local/$file"`
echo $file_status | grep '"failure": 0' | grep '"success": 0' >> /dev/null
if [ $? -eq 0 ]; then
  write_msg "LOG,STD" "Printing new file: $file" "$LOG"
  POST "/files/local/$file" '{"command":"select","print":"true"}'
  exit
fi
done







