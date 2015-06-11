
LOG=/tmp/print_new.log

# Source variables
if [ ! -d "$CB_DIR" ]; then
        CB_DIR=`dirname $0`
fi
. $CB_DIR/util.sh

printr_status
STATUS=$?

if [ $STATUS -ne 0 ]; then
        write_msg "LOG,STD" "Printer status is non-zero. Exiting $0." "$LOG"
        exit
fi

#ret="GET /files | grep name | awk '{ print $2 }' | sed s/,//"

. resty

resty http://localhost/api >> /dev/null

GET /files/local | grep name | awk '{ print $2 }' | sed s/,// | sed s/\"// | sed s/\"// | while read -r file
do
echo "file: $file"
file_status=`GET "/files/local/$file"`
echo $file_status | grep '"failure": 0' | grep '"success": 0' >> /dev/null
if [ $? -eq 0 ]; then
  echo "File hasn't been printed yet: $file"
  POST "/files/local/$file" '{"command":"select","print":"true"}'
  exit
fi
done







