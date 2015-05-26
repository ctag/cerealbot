#include <Servo.h>

/**
 * Cereally 3D Arduino
 * Christopher [ctag] Bero - bigbero@gmail.com
 */

/**
 * Definitions
 */
const unsigned short int BUF_LEN = 5;

/**
 * Global Variables
 */
char in_char = '\0';
char in_buffer[BUF_LEN+1] = "000";
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
	digitalWrite(powerLedPin, HIGH);
	
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
	Serial.println("Clearing input buffer.");
	buffer_index = 0;
	for (buffer_index = 0; buffer_index < BUF_LEN; ++buffer_index)
	{
		in_buffer[buffer_index] = '\0';
	}
	buffer_index = 0;
}

void process_buffer()
{
	Serial.print("Processing input buffer: ");
	if (strcmp(in_buffer, ":fi") == 0)
	{
		Serial.println("Turning fan ON.");
		digitalWrite(fanPin, LOW);
		reset_buffer();
	}
	else if (strcmp(in_buffer, ":fo") == 0)
	{
		Serial.println("Turning fan OFF.");
		digitalWrite(fanPin, HIGH);
		reset_buffer();
	}
	else if (strstr(in_buffer, ":s") != NULL)
	{
		Serial.println("Checking for servo command.");
		char tmp_val[3];
		tmp_val[0] = in_buffer[2];
		tmp_val[1] = in_buffer[3];
		tmp_val[2] = in_buffer[4];
		int servo_val = atoi(tmp_val);
		//servo_val = servo_val * 10;
		Serial.print("Servo val: ");
		Serial.println(servo_val);
		if (servo_val >= 0 && servo_val <= 180)
		{
			Serial.println("Sending to servo.");
			servoPopbar.write(servo_val);
		}
	}
	else {
		Serial.println("No action taken.");
	}
}

void loop()
{
	if (Serial.available())
	{
		digitalWrite(powerLedPin, HIGH);
		
		in_char = Serial.read();
		
		//Serial.print("Recieved [");
		Serial.println(in_char);
		//Serial.println("]");
		
		if (in_char == '.' || in_char == '\n' || in_char == '\0') 
		{
			reset_buffer();
		}
		else if (buffer_index < BUF_LEN)
		{
			if (in_char == ':')
			{
				buffer_index = 0;
			}
			in_buffer[buffer_index] = in_char;
			++buffer_index;
			process_buffer();
		}
		else 
		{
			reset_buffer();
		}
		in_char = '\0';
		
		digitalWrite(powerLedPin, LOW);
	}
}








