#include <Arduino.h>
#include <Servo.h>
// http://davidegironi.blogspot.com/2013/07/amt1001-humidity-and-temperature-sensor.html
#include <amt1001.h>

/**
 * Cereally 3D Arduino
 * Christopher [ctag] Bero - bigbero@gmail.com
 */

/**
 * Working Commands
 * :f - Fan
 *  :fo - Fan OFF
 *  :fi - Fan ON
 * :s - Servo
 *  :sNNN - Set servo to NNN degrees
 * 
 * TODO
 * - Set up fan and servo status reporting
 */

/**
 * Definitions
 */
const unsigned short int BUF_LEN = 32;

/**
 * Global Variables
 */
char in_char = '\0';
char in_buffer[BUF_LEN+1];
unsigned short buffer_index = 0;
Servo servoPopbar;
short int state = 0; // Current state for reading serial input.

/* Serial State Machine
 * 0: Out of state, discard. ':' -> go to 1.
 * 1: Record command. '\n' -> go to 2.
 * 2: Process command and go to 0.
 */

/**
 * Pin Mappings
 */
short fanPin = 3; // Relay trigger for hotbed fans
short popbarPin = 9; // PWM pin for servo mounted to printer extruder
short acPin = A2; // AC bucket water sensor
short humPin = A0; // Humidity sensor
short tempPin = A1; // Temperature sensor

/**
 * Function prototypes
 */
void reset_buffer ();

void setup()
{
	pinMode(fanPin, OUTPUT);
	digitalWrite(fanPin, LOW);
	
	pinMode(humPin, INPUT);
	pinMode(tempPin, INPUT);
	pinMode(acPin, INPUT);
	
	Serial.begin(9600);
	
	servoPopbar.attach(popbarPin);
	
	delay(50);
	
	reset_buffer();
	
	delay(50);
}

void reset_buffer ()
{
	//Serial.println("Clearing input buffer.");
	buffer_index = 0;
	for (buffer_index = 0; buffer_index < BUF_LEN; ++buffer_index)
	{
		in_buffer[buffer_index] = '\0';
	}
	buffer_index = 0;
}

void process_buffer()
{
	Serial.println(in_buffer);
	//Serial.print(" Processing input buffer: ");
	if (strcmp(in_buffer, "fan on") == 0)
	{
		Serial.println("Turning fan ON.");
		digitalWrite(fanPin, LOW);
		reset_buffer();
	}
	else if (strcmp(in_buffer, "fan off") == 0)
	{
		Serial.println("Turning fan OFF.");
		digitalWrite(fanPin, HIGH);
		reset_buffer();
	}
	else if (strcmp(in_buffer, "ac status") == 0) {
		Serial.println(analogRead(acPin));
	}
	else if (strstr(in_buffer, "servo") != NULL)
	{
		Serial.println("Checking for servo command.");
		char tmp_val[3];
		tmp_val[0] = in_buffer[6];
		tmp_val[1] = in_buffer[7];
		tmp_val[2] = in_buffer[8];
		int servo_val = atoi(tmp_val);
		//Serial.print("Servo val: ");
		Serial.println(servo_val);
		if (servo_val >= 0 && servo_val <= 180)
		{
			Serial.println("Sending to servo.");
			servoPopbar.write(servo_val);
		}
		reset_buffer();
	}
	else {
		//Serial.println("No action taken.");
	}
}

void loop()
{
	if (Serial.available())
	{
		in_char = Serial.read();
		Serial.print(in_char);
		
		if (in_char == '\r') {
			Serial.print("\n");
		}
		
		switch (state) {
			case 0:
				if (in_char == ':') {
					reset_buffer();
					state = 1;
					//Serial.("\n\r:");
				}
			break;
			case 1:
				//Serial.print(in_char);
				if (in_char == '\n' || in_char == '\r' || buffer_index == BUF_LEN) {
					//Serial.print("\n\r");
					process_buffer();
					state = 0;
				} else if (in_char == ':') {
					reset_buffer();
					state = 1;
				} else {
					in_buffer[buffer_index++] = in_char;
				}
			break;
			default:
				Serial.println("Error, switch encountered default case.");
				state=0;
			break;
		}
		
		in_char = '\0';
	}
}








