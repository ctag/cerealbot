#include <Servo.h>

/**
 * Cereally 3D Arduino
 * Christopher Bero - 2015
 */

/**
 * Global Variables
 */
char in_buffer = '\0';
char in_text[] = "000";
Servo servoPopbar;
Servo servoSweeper;
unsigned int popbarUp = 170;
unsigned int popbarDown = 10;
unsigned int popbarMiddle = 90;
unsigned int sweeperStored = 160;
unsigned int sweeperAction = 70;

/**
 * Pin Mappings
 */
short fanPin = 3;
short popbarPin = 9;
short sweeperPin = 10;
short resetPin = 11;


void setup()
{
	pinMode(resetPin, OUTPUT);
	digitalWrite(resetPin, LOW);
	
	pinMode(fanPin, OUTPUT);
	digitalWrite(fanPin, LOW);
	
	pinMode(A0, INPUT);
	
	Serial.begin(9600);
	
	servoPopbar.attach(popbarPin);
	servoPopbar.write(popbarMiddle);
	
	servoSweeper.attach(sweeperPin);
	servoSweeper.write(sweeperStored);
	
	delay(50);
}

void reset_printer ()
{
	digitalWrite(resetPin, HIGH);
	delay(2000);
	digitalWrite(resetPin, LOW);
}

void up_servo ()
{
	servoPopbar.write(popbarUp);
	delay(2000);
	servoPopbar.write(popbarMiddle);
}

void down_servo ()
{
	servoPopbar.write(popbarDown);
	delay(2000);
	servoPopbar.write(popbarMiddle);
}

void loop()
{
	if (Serial.available())
	{
		in_buffer = Serial.read();
		
		Serial.print("Recieved: ");
		Serial.println(in_buffer);
		
		if (in_buffer == 'r')
		{
			Serial.println("resetting printer!");
			reset_printer();
		}
		else if (in_buffer == 'u')
		{
			Serial.println("pushing servo up!");
			up_servo();
		}
		else if (in_buffer == 'd') {
			Serial.println("pushing servo down!");
			down_servo();
		}
		else if (in_buffer == 'f') {
			digitalWrite(fanPin, !digitalRead(fanPin));
		}
		in_buffer = '\0';
	}
}








