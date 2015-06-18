import serial
import sys
#import requests

dev=serial.Serial()
dev.baudrate=9600
dev.port=sys.argv[1]
dev.timeout=1

try:
  dev.open()
except:
  print "-1"
  sys.exit()

if not dev.isOpen():
  print "-1"
  sys.exit()

dev.read(100)

val = -1

if sys.argv[2] == "temp":
  dev.write("[t]")
  val=dev.read(2)
  dev.readline()
else:
  dev.write("[h]")
  val=dev.read(2)
  dev.readline()

print val
