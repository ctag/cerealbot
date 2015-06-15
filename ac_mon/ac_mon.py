import serial
import sys

print "opening "+sys.argv[1]

dev=serial.Serial(sys.argv[1],9600,timeout=1)
dev.read(100)
dev.write("[ac]")
status=dev.read();

print status
