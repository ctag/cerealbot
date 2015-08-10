#include <Arduino.h>
#include <Servo.h>
#include <Wire.h>
// http://davidegironi.blogspot.com/2013/07/amt1001-humidity-and-temperature-sensor.html
#include "amt1001_ino.h"
#include "Adafruit_PWMServoDriver.h"

/**
 * Cereally 3D Arduino
 * Christopher [ctag] Bero - bigbero@gmail.com
 */

/**
 * Working Commands
 * [fi] fan on
 * [fo] fan off
 * [t] temp
 * [h] hum
 * [s000] servo 000
 * 
 * TODO
 * - Set up fan and servo status reporting
 */

/**
 * Definitions
 */
const unsigned short int BUF_LEN = 32;

const unsigned short int BASE_MIN = 100; // pulse
const unsigned short int BASE_MAX = 620; // pulse
const unsigned short int BASE_RANGE = 200; // degrees
const unsigned short int BASE_DEFAULT = 190; // degrees


const unsigned short int SHDR_MIN = 250; // pulse
const unsigned short int SHDR_MAX = 600; // pulse
const unsigned short int SHDR_RANGE = 140; // degrees
const unsigned short int SHDR_DEFAULT = 120; // degrees

const unsigned short int ELBO_MIN = 260; // pulse
const unsigned short int ELBO_MAX = 620; // pulse
const unsigned short int ELBO_RANGE = 145; // degrees
const unsigned short int ELBO_DEFAULT = 20; // degrees


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
short humPin = A0; // Humidity sensor
short tempPin = A1; // Temperature sensor
Adafruit_PWMServoDriver armPWM = Adafruit_PWMServoDriver(0x40);

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
	
	armPWM.begin();
	armPWM.setPWMFreq(60);
	uint8_t twbrbackup = TWBR;
	TWBR=12;
	
	Serial.begin(9600);
	
	servoPopbar.attach(popbarPin);
	
	delay(50);
	
	reset_buffer();
	
	delay(50);
}

void reset_buffer ()
{
	for (buffer_index = 0; buffer_index < BUF_LEN; ++buffer_index)
	{
		in_buffer[buffer_index] = '\0';
	}
	buffer_index = 0;
}

void process_buffer(bool loud = false)
{
	if (loud) {
		Serial.print("\n\rProcessing: ");
		Serial.println(in_buffer);
	}
	if (strcmp(in_buffer, "fan on") == 0 || strcmp(in_buffer, "fi") == 0)
	{
		if (loud) Serial.println("Turning fan ON.");
		digitalWrite(fanPin, LOW);
	}
	else if (strcmp(in_buffer, "fan off") == 0 || strcmp(in_buffer, "fo") == 0)
	{
		if (loud) Serial.println("Turning fan OFF.");
		digitalWrite(fanPin, HIGH);
	}
	else if (strcmp(in_buffer, "temp val") == 0 || strcmp(in_buffer, "tv") == 0) {
		Serial.println(analogRead(tempPin));
	}
	else if (strcmp(in_buffer, "temp") == 0 || in_buffer[0] == 't') {
		uint16_t step = analogRead(tempPin);
		uint16_t temperature = amt1001_gettemperature(step);
		Serial.println(temperature);
	}
	else if (strcmp(in_buffer, "hum val") == 0 || strcmp(in_buffer, "hv") == 0) {
		Serial.println(analogRead(humPin));
	}
	else if (strcmp(in_buffer, "hum") == 0 || in_buffer[0] == 'h') {
		int step = analogRead(humPin);
		double volt = (double)step * (5.0 / 1023.0);
		uint16_t humidity = amt1001_gethumidity(volt);
		Serial.println(humidity);
	}
	else if (strstr(in_buffer, "base ") != NULL || in_buffer[0] == 'b')
	{
		if (loud) Serial.println("Checking for servo command.");
		char tmp_val[3];
		if (strlen(in_buffer) > 4) {
			tmp_val[0] = in_buffer[5];
			tmp_val[1] = in_buffer[6];
			tmp_val[2] = in_buffer[7];
		} else {
			tmp_val[0] = in_buffer[1];
			tmp_val[1] = in_buffer[2];
			tmp_val[2] = in_buffer[3];
		}
		int servo_val = atoi(tmp_val);
		if (loud) {
			Serial.print("\n\rServo val: ");
			Serial.println(servo_val);
		}
		if (servo_val >= 0 && servo_val <= BASE_RANGE)
		{
			if (loud) Serial.println("Sending to servo.");
			//servoPopbar.write(servo_val);
			short unsigned int pulselen = map(servo_val, 0, BASE_RANGE, BASE_MIN, BASE_MAX);
			armPWM.setPWM(0, 0, pulselen);
		}
	}
	else if (strstr(in_buffer, "shdr ") != NULL || in_buffer[0] == 'u')
	{
		if (loud) Serial.println("Checking for servo command.");
		char tmp_val[3];
		if (strlen(in_buffer) > 4) {
			tmp_val[0] = in_buffer[5];
			tmp_val[1] = in_buffer[6];
			tmp_val[2] = in_buffer[7];
		} else {
			tmp_val[0] = in_buffer[1];
			tmp_val[1] = in_buffer[2];
			tmp_val[2] = in_buffer[3];
		}
		int servo_val = atoi(tmp_val);
		if (loud) {
			Serial.print("\n\rServo val: ");
			Serial.println(servo_val);
		}
		if (servo_val >= 0 && servo_val <= SHDR_RANGE)
		{
			if (loud) Serial.println("Sending to servo.");
			//servoPopbar.write(servo_val);
			short unsigned int pulselen = map(servo_val, 0, SHDR_RANGE, SHDR_MIN, SHDR_MAX);
			armPWM.setPWM(2, 0, pulselen);
		}
	}
	else if (strstr(in_buffer, "elbo ") != NULL || in_buffer[0] == 'e')
	{
		if (loud) Serial.println("Checking for servo command.");
		char tmp_val[3];
		if (strlen(in_buffer) > 4) {
			tmp_val[0] = in_buffer[5];
			tmp_val[1] = in_buffer[6];
			tmp_val[2] = in_buffer[7];
		} else {
			tmp_val[0] = in_buffer[1];
			tmp_val[1] = in_buffer[2];
			tmp_val[2] = in_buffer[3];
		}
		int servo_val = atoi(tmp_val);
		if (loud) {
			Serial.print("\n\rServo val: ");
			Serial.println(servo_val);
		}
		if (servo_val >= 0 && servo_val <= ELBO_RANGE)
		{
			if (loud) Serial.println("Sending to servo.");
			//servoPopbar.write(servo_val);
			short unsigned int pulselen = map(servo_val, 0, ELBO_RANGE, ELBO_MIN, ELBO_MAX);
			armPWM.setPWM(1, 0, pulselen);
		}
	}
	reset_buffer();
}

void loop()
{
	if (Serial.available())
	{
		in_char = Serial.read();
		if (in_char == '.') {
			Serial.println("\n\rUsage:");
			Serial.println(":cmd or [cmd]");
			Serial.println("[servo 111] - [fan on/off][fo][fi] - [hum][humv][h][hv] - [temp][tempv][t][tv]");
		}
		
		switch (state) {
			case 0: /* State 0: disregard input */
				if (in_char == ':') {
					reset_buffer();
					state = 1;
				}
				if (in_char == '[') {
					reset_buffer();
					state = 2;
				}
			break;
			case 1: /* State 1: load buffer, noisily echo input */
				if (in_char == '\n' || in_char == '\r' || buffer_index == BUF_LEN) {
					process_buffer(true);
					state = 0;
				} else if (in_char == ':') {
					reset_buffer();
					state = 1;
				} else if (in_char == '[') {
					reset_buffer();
					state = 2;
				} else if (in_char == 0) {
					Serial.println(". Input Cancelled.");
					reset_buffer();
					state = 0;
				} else {
					Serial.print(in_char);
					in_buffer[buffer_index++] = in_char;
				}
			break;
			case 2: /* State 2: load buffer silently */
				if (in_char == ']' || buffer_index == BUF_LEN) {
					process_buffer();
					state = 0;
				} else if (in_char == ':') {
					reset_buffer();
					state = 1;
				} else if (in_char == '[') {
					reset_buffer();
					state = 2;
				} else if (in_char == 0) {
					reset_buffer();
					state = 0;
				} else {
					in_buffer[buffer_index++] = in_char;
				}
			break;
			default:
				Serial.println(" Error, switch encountered default case.");
				state=0;
			break;
		} // end switch
		if (buffer_index == 0 && state == 1) {
			Serial.print("\n\r> ");
		}
		in_char = '\0';
	} // End if Serial.available
} // end loop()








