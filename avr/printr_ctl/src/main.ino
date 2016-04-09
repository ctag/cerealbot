#include <Arduino.h>
#include <Wire.h>
#include <EEPROM.h>
#include <Timer.h> /* pio install 75 */

// Interrupts
// #include <avr/io.h>
// #include <avr/interrupt.h>

// http://davidegironi.blogspot.com/2013/07/amt1001-humidity-and-temperature-sensor.html
#include "amt1001_ino.h"

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
 * [la] 	Load default states
 *
 * Events
 * !p0!		The filament has run out!
 *
 */

 /**
  * Pin Mappings
  */
 unsigned short int pinFanRelay = 3; // Relay trigger for hotbed fans
 unsigned short int pinLightRelay = 4; // Relay trigger for lights
 unsigned short int pinPlasticSensor = 5; // Filament detector
 unsigned short int pinHumSensor = A0; // Humidity sensor
 unsigned short int pinTempSensor = A1; // Temperature sensor
 unsigned short int pinLightSensor = A2; // Photoresistor

/**
 * Definitions
 */
const unsigned short int BUF_LEN = 32;
const unsigned int STATES_ADDR = 0;

typedef struct {
	unsigned int LEDMIN;
	unsigned int LEDMAX;
	unsigned int LEDTHRESHOLD;
	boolean LEDAUTO;
	boolean FAN;
	boolean LIGHT;
} states;

// Default system state
states system_states;

states default_states = {
	30000,
	0,
	350,
	1,
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
Timer timer;
// bool filament_alert = false;

/* Serial State Machine
 * 0: Out of state, discard. ':' -> go to 1.
 * 1: Record command. '\n' -> go to 2.
 * 2: Process command and go to 0.
 */

/**
 * Function prototypes
 */
void reset_buffer ();
void ledToggle ();

void setup()
{
	load_states();
	pinMode(pinFanRelay, OUTPUT);
	pinMode(pinLightRelay, OUTPUT);
	if (system_states.FAN == 1) {
		digitalWrite(pinFanRelay, LOW);
	} else {
		digitalWrite(pinFanRelay, HIGH);
	}
	if (system_states.LIGHT == 1) {
		digitalWrite(pinLightRelay, LOW);
	} else {
		digitalWrite(pinLightRelay, HIGH);
	}

	pinMode(pinHumSensor, INPUT);
	pinMode(pinTempSensor, INPUT);
  pinMode(pinPlasticSensor, INPUT_PULLUP);

	Serial.begin(9600);

	delay(50);

	reset_buffer();
	//Serial.println("ATmega reset");

	delay(50);
  timer.every(15000, ledToggle);

  // Filament sensor
  // attachInterrupt(0, filament_sensor_interrupt, RISING);
  // interrupts();
}

// void filament_sensor_interrupt()
// {
//   filament_alert = true;
// }

void ledToggle()
{
  if (system_states.LEDAUTO)
  {
    if (!system_states.LIGHT && analogRead(pinLightSensor) <= system_states.LEDTHRESHOLD)
  	{
  		set_light(true);
  	}
  	else if (system_states.LIGHT && analogRead(pinLightSensor) > system_states.LEDTHRESHOLD)
  	{
  		set_light(false);
  	}
  }
}

void reset_buffer ()
{
	for (buffer_index = 0; buffer_index < BUF_LEN; ++buffer_index)
	{
		in_buffer[buffer_index] = '\0';
	}
	buffer_index = 0;
}

void save_states ()
{
	EEPROM.put(STATES_ADDR, system_states);
}

void load_states ()
{
	EEPROM.get(STATES_ADDR, system_states);
}

void set_light(bool val)
{
	digitalWrite(pinLightRelay, !val);
	system_states.LIGHT = val;
	save_states();
}

void process_buffer(bool loud = false)
{
	if (loud) {
		Serial.print("\n\rProcessing: ");
		Serial.println(in_buffer);
	}
	if (in_buffer[0] == 's') // Set
	{
		if (in_buffer[1] == 's') // Set sensor
		{
			char tmp_buf[4];
      tmp_buf[0] = in_buffer[3];
      tmp_buf[1] = in_buffer[4];
      tmp_buf[2] = in_buffer[5];
			tmp_buf[3] = in_buffer[6];
      unsigned int tmp_int = atoi(tmp_buf);
			if (in_buffer[2] == 't') // Set sensor threshold
			{
				system_states.LEDTHRESHOLD = tmp_int;
				save_states();
			}
			else if (in_buffer[2] == 'a') // Set sensor Toggle Autotoggle
			{
				if (system_states.LEDAUTO == 1)
				{
					system_states.LEDAUTO = 0;
				} else {
					system_states.LEDAUTO = 1;
				}
				save_states();
			}
		}
		else if (in_buffer[1] == 'f') // Set Fan
		{
			if (loud) Serial.print("Turning fan: ");
			if (in_buffer[2] == '1') // Set Fan On
			{
				if (loud) Serial.println("ON.");
				digitalWrite(pinFanRelay, LOW);
				system_states.FAN = 1;
				save_states();
			}
			else if (in_buffer[2] == '0') // Set Fan Off
			{
				if (loud) Serial.println("OFF.");
				digitalWrite(pinFanRelay, HIGH);
				system_states.FAN = 0;
				save_states();
			}
			else if (in_buffer[2] == 't') // Set Fan Toggle
			{
				if (system_states.FAN == 0) {
					if (loud) Serial.println("ON.");
					digitalWrite(pinFanRelay, LOW);
					system_states.FAN = 1;
					save_states();
				} else {
					if (loud) Serial.println("OFF.");
					digitalWrite(pinFanRelay, HIGH);
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
				set_light(true);
			}
			else if (in_buffer[2] == '0') // Set Light Off
			{
				if (loud) Serial.println("OFF.");
				set_light(false);
			}
			else if (in_buffer[2] == 't') // Set Light Toggle
			{
				if (system_states.LIGHT == 0) {
					if (loud) Serial.println("ON.");
					digitalWrite(pinLightRelay, LOW);
					system_states.LIGHT = 1;
					save_states();
				} else {
					if (loud) Serial.println("OFF.");
					digitalWrite(pinLightRelay, HIGH);
					system_states.LIGHT = 0;
					save_states();
				}
			}
			else // Set Light Undefined
			{
				Serial.println("\n\r\n\r>>> Error in process_buffer. sl.");
			}
		} // end Set Light
		else // Set undefined
		{
			Serial.println("\n\r\n\r>>> Error in process_buffer. s.");
		}
	} // end Set

	else if (in_buffer[0] == 'g') // Get
	{
		if (in_buffer[1] == 's') // Get Sensor
		{
			if (in_buffer[2] == 't') // Get Sensor Threshold
			{
				Serial.println(system_states.LEDTHRESHOLD);
			}
			else if (in_buffer[2] == 'a') // Get Sensor AutoToggle
			{
				Serial.println(system_states.LEDAUTO);
			}
      else if (in_buffer[2] == 'v') // Get Sensor Value
			{
				Serial.println(analogRead(pinLightSensor));
			}
		}
		else if (in_buffer[1] == 'f') // Get Fan
		{
			short unsigned int fanState = digitalRead(pinFanRelay);
			if (fanState == 1) {
				Serial.println('0');
			} else {
				Serial.println('1');
			}
		} // end get fan
		else if (in_buffer[1] == 'l') // Get Light
		{
			short unsigned int lightState = digitalRead(pinLightRelay);
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
				Serial.println(analogRead(pinTempSensor));
			}
			else // Get Temperature
			{
				uint16_t step = analogRead(pinTempSensor);
				uint16_t temperature = amt1001_gettemperature(step);
				Serial.println(temperature);
			}
		} // end Get Temperature
		else if (in_buffer[1] == 'h') // Get Humidity
		{
			if (in_buffer[2] == 'v') // Get Humidity Value
			{
				Serial.println(analogRead(pinHumSensor));
			}
			else // Get Temperature
			{
				int step = analogRead(pinHumSensor);
				double volt = (double)step * (5.0 / 1023.0);
				uint16_t humidity = amt1001_gethumidity(volt);
				Serial.println(humidity);
			}
		} // end Get Humidity
		else // Get Undefined
		{
			Serial.println("\n\r\n\r>>> Error in process_buffer. g.");
		}
	} // end Get

	else if (in_buffer[0] == 'l') // Load default
	{
		if (in_buffer[1] == 'a') // Load default states
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
  timer.update();

  if (digitalRead(pinPlasticSensor) == HIGH)
  {
    Serial.println("!p0!");
    while (digitalRead(pinPlasticSensor) == HIGH) {
      delay(1000);
    }
  }
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
