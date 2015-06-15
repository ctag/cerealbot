#include <Arduino.h>
#include <Servo.h>
// http://davidegironi.blogspot.com/2013/07/amt1001-humidity-and-temperature-sensor.html
//#include "amt1001.h"

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

//
// Begin amt1001 splice
//

//define min and max valid voltage to measure humidity
#define AMT1001_HUMIDITYVMIN 0.0
#define AMT1001_HUMIDITYVMAX 3.0

//slope factor to calculate humidity
#define AMT1001_HUMIDITYSLOPE 33.33

//define min and max valid adc to measure temperature
#define AMT1001_TEMPERATUREVMIN 0.0
#define AMT1001_TEMPERATUREVMAX 0.8

//slope factor to calculate temperature
#define AMT1001_TEMPERATURESLOPE 100.0

//define lookup method variables for temperature
#define amt1001_lookupadcfirst 1 //adc first value of lookup table
#define amt1001_lookupadcstep 10 //step between every table point
#define amt1001_lookuptablesize 103 //size of the lookup table
const float PROGMEM amt1001_lookuptable[amt1001_lookuptablesize] = {
		-86.99 , -59.05 , -49.91 , -43.96 , -39.45 , -35.76 , -32.61 , -29.84 , -27.37 , -25.11 , -23.03 , -21.1 , -19.29 , -17.58 , -15.95 , -14.41 , -12.92 , -11.5 , -10.12 , -8.79 , -7.5 , -6.25 , -5.03 , -3.83 , -2.66 , -1.52 , -0.4 , 0.71 , 1.8 , 2.87 , 3.93 , 4.97 , 6.01 , 7.03 , 8.05 , 9.05 , 10.06 , 11.05 , 12.04 , 13.03 , 14.02 , 15 , 15.98 , 16.96 , 17.95 , 18.93 , 19.92 , 20.9 , 21.9 , 22.89 , 23.89 , 24.9 , 25.91 , 26.93 , 27.96 , 29 , 30.05 , 31.11 , 32.19 , 33.27 , 34.37 , 35.49 , 36.63 , 37.78 , 38.95 , 40.14 , 41.36 , 42.6 , 43.87 , 45.17 , 46.5 , 47.86 , 49.26 , 50.7 , 52.18 , 53.71 , 55.29 , 56.92 , 58.62 , 60.38 , 62.22 , 64.14 , 66.15 , 68.26 , 70.49 , 72.84 , 75.34 , 78.01 , 80.87 , 83.95 , 87.3 , 90.96 , 95 , 99.52 , 104.62 , 110.48 , 117.36 , 125.67 , 136.09 , 149.94 , 170.2 , 206.11 , 330.42
};

/*
 * get humidity based on read voltage
 */
int16_t amt1001_gethumidity(double voltage) {
	if(voltage > AMT1001_HUMIDITYVMIN && voltage < AMT1001_HUMIDITYVMAX)
		return (int16_t)(AMT1001_HUMIDITYSLOPE*voltage);
	else
		return -1;
}

/*
 * get temperature based on read voltage
 */
int16_t amt1001_gettemperature(uint16_t adcvalue) {
	float t = 0.0;
	float mint = 0;
	float maxt = 0;

	//return error for invalid adcvalues
	if(adcvalue<amt1001_lookupadcfirst || adcvalue>amt1001_lookupadcfirst+amt1001_lookupadcstep*(amt1001_lookuptablesize-1)) {
		return -1;
	}

	uint8_t i = 0;
	uint16_t a = amt1001_lookupadcfirst;
	for(i=0; i<amt1001_lookuptablesize; i++) {
		if(adcvalue < a)
			break;
		a += amt1001_lookupadcstep;
	}

	maxt = pgm_read_float(&amt1001_lookuptable[i]); //highest interval value
	if(i==0)
		mint = maxt;
	else
		mint = pgm_read_float(&amt1001_lookuptable[i-1]); //smallest interval value

	//do interpolation
	a = a-amt1001_lookupadcstep;
	t = mint + ((maxt-mint)/amt1001_lookupadcstep) * (adcvalue-a);

	return t;

}



// end amt1001 splice

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
	else if (strcmp(in_buffer, "ac val") == 0 || strcmp(in_buffer, "acv") == 0) {
		Serial.println(analogRead(acPin));
	}
	else if (strcmp(in_buffer, "ac status") == 0 || strcmp(in_buffer, "ac") == 0) {
		if (analogRead(acPin) < 600) {
			Serial.println('1');
		} else {
			Serial.println('0');
		}
	}
	else if (strcmp(in_buffer, "temp val") == 0 || strcmp(in_buffer, "tv") == 0) {
		Serial.println(analogRead(tempPin));
	}
	else if (strcmp(in_buffer, "temperature") == 0 || strcmp(in_buffer, "temp") == 0) {
		uint16_t step = analogRead(tempPin);
		uint16_t temperature = amt1001_gettemperature(step);
		Serial.println(temperature);
	}
	else if (strcmp(in_buffer, "humidity val") == 0 || strcmp(in_buffer, "humv") == 0) {
		Serial.println(analogRead(humPin));
	}
	else if (strcmp(in_buffer, "humidity") == 0 || strcmp(in_buffer, "hum") == 0) {
		int step = analogRead(humPin);
		double volt = step * (5.0 / 1023.0);
		uint16_t humidity = amt1001_gethumidity(volt);
		Serial.println(humidity);
	}
	else if (strstr(in_buffer, "servo") != NULL)
	{
		if (loud) Serial.println("Checking for servo command.");
		char tmp_val[3];
		tmp_val[0] = in_buffer[6];
		tmp_val[1] = in_buffer[7];
		tmp_val[2] = in_buffer[8];
		int servo_val = atoi(tmp_val);
		if (loud) {
			Serial.print("\n\rServo val: ");
			Serial.println(servo_val);
		}
		if (servo_val >= 0 && servo_val <= 180)
		{
			if (loud) Serial.println("Sending to servo.");
			servoPopbar.write(servo_val);
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
			Serial.println(".");
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








