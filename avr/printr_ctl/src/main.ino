#include <Arduino.h>
#include <Wire.h>
#include <EEPROM.h>

// http://davidegironi.blogspot.com/2013/07/amt1001-humidity-and-temperature-sensor.html
#include "amt1001_ino.h"
#include "Adafruit_PWMServoDriver.h"

/**
 * Cerealbot Arduino
 * Christopher [ctag] Bero - bigbero@gmail.com
 *
 * Commands
 * [sf1] 	Set fan on
 * [sf0] 	Set fan off
 * [sft] 	Set fan toggle
 * [sl1] 	Set light on
 * [sl0] 	Set light off
 * [slt] 	Set light toggle
 * [gf] 	Get fan state
 * [gl] 	Get light state
 * [sl1]	Set light on
 * [sl0]	Set light off
 * [slt]	Set light toggle
 * [gl]		Get light state
 * [gp]		Get plastic (filament) state
 * [gt] 	Get temperature
 * [gtv] 	Get temperature raw value
 * [gh] 	Get humidity
 * [ghv] 	Get humidity raw value
 * [sb100] 	Set base servo degrees
 * [gb] 	Get base servo degrees
 * [su100] 	Set shdr servo degrees
 * [gu] 	Get shdr servo degrees
 * [se100] 	Set elbo servo degrees
 * [ge] 	Get elbo servo degrees
 * [gd]		Get pwm delay (msec)
 * [sd100]	Set pwm delay (msec)
 * [le]		Load default settings
 * [la] 	Load default states
 * 
 * Events
 * !p0!		The filament has run out!
 * 
 */

/**
 * Definitions
 */
const unsigned short int BUF_LEN = 32;
const unsigned int SETTINGS_ADDR = 0;

typedef struct {
	unsigned short int BASE_MIN; // pulse
	unsigned short int BASE_MAX; // pulse
	unsigned short int BASE_RANGE; // degrees
	
	unsigned short int SHDR_MIN; // pulse
	unsigned short int SHDR_MAX; // pulse
	unsigned short int SHDR_RANGE; // degrees
	
	unsigned short int ELBO_MIN; // pulse
	unsigned short int ELBO_MAX; // pulse
	unsigned short int ELBO_RANGE; // degrees
	
	unsigned int PWM_DELAY; // Millisec
} settings;

// Default settings
settings system_settings;

settings default_settings = {
	100, // BASE_MIN
	620, // BASE_MAX
	200, // BASE_RANGE
	250, // SHDR_MIN
	600, // SHDR_MAX
	140, // SHDR_RANGE
	260, // ELBO_MIN
	620, // ELBO_MAX
	145, // ELBO_RANGE
	20 // PWM_DELAY
};

const unsigned int STATES_ADDR = sizeof(system_settings)+10;

typedef struct {
	unsigned short int BASE_POS;
	unsigned short int SHDR_POS;
	unsigned short int ELBOW_POS;
	boolean FAN;
	boolean LIGHT;
} states;

// Default system state
states system_states;

states default_states = {
	10,
	10,
	10,
	0,
	1
};

/**
 * Global Variables
 */
char in_char = '\0';
char in_buffer[BUF_LEN+1];
unsigned short buffer_index = 0;
short int input_state = 0; // Current state for reading serial input.

/* Serial State Machine
 * 0: Out of state, discard. ':' -> go to 1.
 * 1: Record command. '\n' -> go to 2.
 * 2: Process command and go to 0.
 */

/**
 * Pin Mappings
 */
unsigned short int fanPin = 3; // Relay trigger for hotbed fans
unsigned short int lightPin = 4; // Relay trigger for lights
unsigned short int plasticPin = A2; // Filament detector
unsigned short int humPin = A0; // Humidity sensor
unsigned short int tempPin = A1; // Temperature sensor
Adafruit_PWMServoDriver armPWM = Adafruit_PWMServoDriver(0x40);

/**
 * Function prototypes
 */
void reset_buffer ();

void setup()
{
	load_settings();
	load_states();
	pinMode(fanPin, OUTPUT);
	pinMode(lightPin, OUTPUT);
	if (system_states.FAN == 1) {
		digitalWrite(fanPin, LOW);
	} else {
		digitalWrite(fanPin, HIGH);
	}
	if (system_states.LIGHT == 1) {
		digitalWrite(lightPin, LOW);
	} else {
		digitalWrite(lightPin, HIGH);
	}
	
	pinMode(humPin, INPUT);
	pinMode(tempPin, INPUT);
	
	armPWM.begin();
	armPWM.setPWMFreq(60);
	uint8_t twbrbackup = TWBR;
	TWBR=12;
	
	Serial.begin(9600);
	
	delay(50);
	
	reset_buffer();
	//Serial.println("ATmega reset");
	
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

void save_settings ()
{
	EEPROM.put(SETTINGS_ADDR, system_settings);
}

void load_settings ()
{
	EEPROM.get(SETTINGS_ADDR, system_settings);
}

void save_states ()
{
	EEPROM.put(STATES_ADDR, system_states);
}

void load_states ()
{
	EEPROM.get(STATES_ADDR, system_states);
}

void slow_pwm (short unsigned int pin, short unsigned from_pulse, short unsigned int to_pulse)
{
	if (from_pulse < to_pulse)
	{
		for (; from_pulse <= to_pulse; from_pulse++)
		{
			armPWM.setPWM(pin, 0, from_pulse);
			delay(system_settings.PWM_DELAY);
		}
	} else {
		for (; from_pulse >= to_pulse; from_pulse--)
		{
			armPWM.setPWM(pin, 0, from_pulse);
			delay(system_settings.PWM_DELAY);
		}
	}
	
}

void process_buffer(bool loud = false)
{
	if (loud) {
		Serial.print("\n\rProcessing: ");
		Serial.println(in_buffer);
	}
	if (in_buffer[0] == 's') // Set
	{
		if (in_buffer[1] == 'f') // Set Fan
		{
			if (loud) Serial.print("Turning fan: ");
			if (in_buffer[2] == '1') // Set Fan On
			{
				if (loud) Serial.println("ON.");
				digitalWrite(fanPin, LOW);
				system_states.FAN = 1;
				save_states();
			} 
			else if (in_buffer[2] == '0') // Set Fan Off
			{
				if (loud) Serial.println("OFF.");
				digitalWrite(fanPin, HIGH);
				system_states.FAN = 0;
				save_states();
			}
			else if (in_buffer[2] == 't') // Set Fan Toggle
			{
				if (system_states.FAN == 0) {
					if (loud) Serial.println("ON.");
					digitalWrite(fanPin, LOW);
					system_states.FAN = 1;
					save_states();
				} else {
					if (loud) Serial.println("OFF.");
					digitalWrite(fanPin, HIGH);
					system_states.FAN = 0;
					save_states();
				}
			}
			else // Set Fan Undefined
			{
				Serial.println("\n\r\n\r>>> Error in process_buffer. sf.");
			}
		} // end Set Fan
		else if (in_buffer[1] == 'l') // Set Light
		{
			if (loud) Serial.print("Turning light: ");
			if (in_buffer[2] == '1') // Set Light On
			{
				if (loud) Serial.println("ON.");
				digitalWrite(lightPin, LOW);
				system_states.LIGHT = 1;
				save_states();
			}
			else if (in_buffer[2] == '0') // Set Light Off
			{
				if (loud) Serial.println("OFF.");
				digitalWrite(lightPin, HIGH);
				system_states.LIGHT = 0;
				save_states();
			}
			else if (in_buffer[2] == 't') // Set Light Toggle
			{
				if (system_states.LIGHT == 0) {
					if (loud) Serial.println("ON.");
					digitalWrite(lightPin, LOW);
					system_states.LIGHT = 1;
					save_states();
				} else {
					if (loud) Serial.println("OFF.");
					digitalWrite(lightPin, HIGH);
					system_states.LIGHT = 0;
					save_states();
				}
			}
			else // Set Light Undefined
			{
				Serial.println("\n\r\n\r>>> Error in process_buffer. sl.");
			}
		} // end Set Light
		else if (in_buffer[1] == 'b') // Set Base servo
		{
			if (loud) Serial.println("BASE Servo: ");
			char tmp_val[3];
			tmp_val[0] = in_buffer[2];
			tmp_val[1] = in_buffer[3];
			tmp_val[2] = in_buffer[4];
			short unsigned int servo_deg = atoi(tmp_val);
			if (loud) {
				Serial.println(servo_deg);
			}
			if (servo_deg >= 0 && servo_deg <= system_settings.BASE_RANGE)
			{
				if (loud) Serial.println("Sending to servo.");
				short unsigned int pulselen = map(servo_deg, 0, system_settings.BASE_RANGE, system_settings.BASE_MIN, system_settings.BASE_MAX);
				short unsigned int from_pulse = map(system_states.BASE_POS, 0, system_settings.BASE_RANGE, system_settings.BASE_MIN, system_settings.BASE_MAX);
				slow_pwm(0, from_pulse, pulselen);
				system_states.BASE_POS = servo_deg;
				save_states();
			} else {
				Serial.println("\n\r\n\r>>> Error in process_buffer. sb.");
			}
		} // end Set Base
		else if (in_buffer[1] == 'u') // Set SHDR servo
		{
			if (loud) Serial.println("SHDR Servo: ");
			char tmp_val[3];
			tmp_val[0] = in_buffer[2];
			tmp_val[1] = in_buffer[3];
			tmp_val[2] = in_buffer[4];
			short unsigned int servo_deg = atoi(tmp_val);
			if (loud) {
				Serial.println(servo_deg);
			}
			if (servo_deg >= 0 && servo_deg <= system_settings.SHDR_RANGE)
			{
				if (loud) Serial.println("Sending to servo.");
				short unsigned int pulselen = map(servo_deg, 0, system_settings.SHDR_RANGE, system_settings.SHDR_MIN, system_settings.SHDR_MAX);
				short unsigned int from_pulse = map(system_states.SHDR_POS, 0, system_settings.SHDR_RANGE, system_settings.SHDR_MIN, system_settings.SHDR_MAX);
				slow_pwm(1, from_pulse, pulselen);
				system_states.SHDR_POS = servo_deg;
				save_states();
			} else {
				Serial.println("\n\r\n\r>>> Error in process_buffer. su.");
			}
		} // end Set SHDR
		else if (in_buffer[1] == 'e') // Set ELBO servo
		{
			if (loud) Serial.println("ELBO Servo: ");
			char tmp_val[3];
			tmp_val[0] = in_buffer[2];
			tmp_val[1] = in_buffer[3];
			tmp_val[2] = in_buffer[4];
			short unsigned int servo_deg = atoi(tmp_val);
			if (loud) {
				Serial.println(servo_deg);
			}
			if (servo_deg >= 0 && servo_deg <= system_settings.ELBO_RANGE)
			{
				if (loud) Serial.println("Sending to servo.");
				short unsigned int pulselen = map(servo_deg, 0, system_settings.ELBO_RANGE, system_settings.ELBO_MIN, system_settings.ELBO_MAX);
				short unsigned int from_pulse = map(system_states.ELBOW_POS, 0, system_settings.ELBO_RANGE, system_settings.ELBO_MIN, system_settings.ELBO_MAX);
				slow_pwm(2, from_pulse, pulselen);
				system_states.ELBOW_POS = servo_deg;
				save_states();
			} else {
				Serial.println("\n\r\n\r>>> Error in process_buffer. se.");
			}
		} // end Set ELBO
		else if (in_buffer[1] == 'd') // Set pwm delay
		{
			if (loud) Serial.println("PWM Delay: ");
			char tmp_val[3];
			tmp_val[0] = in_buffer[2];
			tmp_val[1] = in_buffer[3];
			tmp_val[2] = in_buffer[4];
			short unsigned int newDelay = atoi(tmp_val);
			if (loud) Serial.println(newDelay);
			system_settings.PWM_DELAY = newDelay;
			save_states();
		} // end Set pwm delay
		else // Set undefined
		{
			Serial.println("\n\r\n\r>>> Error in process_buffer. s.");
		}
	} // end Set
	
	else if (in_buffer[0] == 'g') // Get
	{
		if (in_buffer[1] == 'f') // Get Fan
		{
			short unsigned int fanState = digitalRead(fanPin);
			if (fanState == 1) {
				Serial.println('0');
			} else {
				Serial.println('1');
			}
		} // end get fan
		else if (in_buffer[1] == 'l') // Get Light
		{
			short unsigned int lightState = digitalRead(lightPin);
			if (lightState == 1) {
				Serial.println('0');
			} else {
				Serial.println('1');
			}
		} // end get light
		else if (in_buffer[1] == 't') // Get Temperature
		{
			if (in_buffer[2] == 'v') // Get Temperature Value
			{
				Serial.println(analogRead(tempPin));
			}
			else // Get Temperature
			{
				uint16_t step = analogRead(tempPin);
				uint16_t temperature = amt1001_gettemperature(step);
				Serial.println(temperature);
			}
		} // end Get Temperature
		else if (in_buffer[1] == 'h') // Get Humidity
		{
			if (in_buffer[2] == 'v') // Get Humidity Value
			{
				Serial.println(analogRead(humPin));
			}
			else // Get Temperature
			{
				int step = analogRead(humPin);
				double volt = (double)step * (5.0 / 1023.0);
				uint16_t humidity = amt1001_gethumidity(volt);
				Serial.println(humidity);
			}
		} // end Get Humidity
		else if (in_buffer[1] == 'b') // Get BASE
		{
			Serial.println(system_states.BASE_POS);
		}
		else if (in_buffer[1] == 'u') // Get SHDR
		{
			Serial.println(system_states.SHDR_POS);
		}
		else if (in_buffer[1] == 'e') // Get ELBO
		{
			Serial.println(system_states.ELBOW_POS);
		}
		else if (in_buffer[1] == 'd') // Get pwm delay
		{
			Serial.println(system_settings.PWM_DELAY);
		}
		else // Get Undefined
		{
			Serial.println("\n\r\n\r>>> Error in process_buffer. g.");
		}
	} // end Get
	
	else if (in_buffer[0] == 'l') // Load default
	{
		if (in_buffer[1] == 'e') // Load default settings
		{
			system_settings = default_settings;
			save_settings();
		}
		else if (in_buffer[1] == 'a') // Load default states
		{
			system_states = default_states;
			save_states();
		}
		else // Load undefined
		{
			Serial.println("\n\r\n\r>>> Error in process_buffer. l.");
		}
	} // end Load
	
	reset_buffer();
} // end process_buffer()

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
		
		switch (input_state) {
			case 0: /* State 0: disregard input */
				if (in_char == ':') {
					reset_buffer();
					input_state = 1;
				}
				if (in_char == '[') {
					reset_buffer();
					input_state = 2;
				}
			break;
			case 1: /* State 1: load buffer, noisily echo input */
				if (in_char == '\n' || in_char == '\r' || buffer_index == BUF_LEN) {
					process_buffer(true);
					input_state = 0;
				} else if (in_char == ':') {
					reset_buffer();
					input_state = 1;
				} else if (in_char == '[') {
					reset_buffer();
					input_state = 2;
				} else if (in_char == 0) {
					Serial.println(". Input Cancelled.");
					reset_buffer();
					input_state = 0;
				} else {
					Serial.print(in_char);
					in_buffer[buffer_index++] = in_char;
				}
			break;
			case 2: /* State 2: load buffer silently */
				if (in_char == ']' || buffer_index == BUF_LEN) {
					process_buffer();
					input_state = 0;
				} else if (in_char == ':') {
					reset_buffer();
					input_state = 1;
				} else if (in_char == '[') {
					reset_buffer();
					input_state = 2;
				} else if (in_char == 0) {
					reset_buffer();
					input_state = 0;
				} else {
					in_buffer[buffer_index++] = in_char;
				}
			break;
			default:
				Serial.println(" Error, switch encountered default case.");
				input_state=0;
			break;
		} // end switch
		if (buffer_index == 0 && input_state == 1) {
			Serial.print("\n\r> ");
		}
		in_char = '\0';
	} // End if Serial.available
} // end loop()








