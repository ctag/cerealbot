import serial
import sys
#import requests

dev=serial.Serial(sys.argv[1],9600,timeout=1)

if not dev.isOpen():
  exit

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
