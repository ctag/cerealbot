#include <Servo.h>

/**
 * Cereally 3D Arduino
 * Christopher [ctag] Bero - bigbero@gmail.com
 */

/**
 * Definitions
 */
const int BUF_LEN = 3;

/**
 * Global Variables
 */
char in_char = '\0';
char in_buffer[BUF_LEN] = "000";
unsigned short int buffer_index = 0;
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
short powerLedPin = 13;

void setup()
{
	pinMode(resetPin, OUTPUT);
	digitalWrite(resetPin, LOW);
	
	pinMode(fanPin, OUTPUT);
	digitalWrite(fanPin, LOW);
	
	pinMode(powerLedPin, OUTPUT);
	digitalWrite(powerLedPin, LOW);
	
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

void reset_buffer ()
{
	buffer_index = 0;
	for (buffer_index = 0; buffer_index < BUF_LEN; ++buffer_index)
	{
		in_buffer[buffer_index] = ' ';
	}
	buffer_index = 0;
}

void process_buffer()
{
	if (in_buffer == ":fo")
	{
		Serial.println("Turning fan on.");
	}
	reset_buffer();
}

void loop()
{
	if (Serial.available())
	{
		digitalWrite(powerLedPin, HIGH);
		
		in_char = Serial.read();
		
		Serial.print("Recieved [");
		Serial.print(in_char);
		Serial.println("]");
		
		if (in_char == ' ' || in_char == '.' || in_char == '\n' || in_char == '\0') 
		{
			reset_buffer();
		}
		else if (buffer_index < BUF_LEN)
		{
			in_buffer[buffer_index] = in_char;
			++buffer_index;
			if (buffer_index == BUF_LEN)
			{
				process_buffer();
			}
		}
		else 
		{
			reset_buffer();
		}
		in_char = '\0';
		
		digitalWrite(powerLedPin, LOW);
	}
}








