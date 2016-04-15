#include <Arduino.h>
#include <Wire.h>
#include <EEPROM.h>
#include <Timer.h> /* pio install 75 */

// Screen
#include <LiquidCrystal_I2C.h>

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
 * [sf1]  Set fan on
 * [sf0]  Set fan off
 * [sft]  Set fan toggle
 * [sl1]  Set light on
 * [sl0]  Set light off
 * [slt]  Set light toggle
 * [gf]   Get fan state
 * [gl]   Get light state
 * [sl1]	Set light on
 * [sl0]	Set light off
 * [slt]	Set light toggle
 * [gl]		Get light state
 * [gp]		Get plastic (filament) state
 * [gt]   Get temperature
 * [gtv]  Get temperature raw value
 * [gh]   Get humidity
 * [ghv]  Get humidity raw value
 * [la]   Load default states
 *
 * Events
 * !p0!		The filament has run out!
 *
 */

/**
 * Pin Mappings
 */
unsigned short int pinFanRelay = 3;  // Relay trigger for hotbed fans
unsigned short int pinLightRelay = 4;  // Relay trigger for lights
unsigned short int pinPlasticSensor = 5;  // Filament detector
unsigned short int pinHumSensor = A0;  // Humidity sensor
unsigned short int pinTempSensor = A1;  // Temperature sensor
unsigned short int pinLightSensor = A2;  // Photoresistor
// pinSDA = A4;
// pinSCL = A5;

/**
 * Definitions
 */
const unsigned short int BUF_LEN = 32;
const unsigned int STATES_ADDR = 0;
const char BACKSPACE[] = {'\b', ' ', '\b', '\0'};

typedef struct {
        short int LEDTHRESHOLD;
        boolean LEDAUTO;
        boolean FAN;
        boolean LIGHT;
        char LCDBUFFER_0[21];
        char LCDBUFFER_1[21];
        char LCDBUFFER_2[21];
        char LCDBUFFER_3[21];
} states;

// Default system state
states system_states;

states default_states = {
        500,
        0,
        0,
        1,
        /* lcd.print("   Hello, world!    "); */
        {' ', ' ', ' ', 'H', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd', '!', ' ', ' ', ' ', ' ', '\0'},
        /* lcd.print(" This is Cerealbot. "); */
        {' ', ' ', 'I', ' ', 'a', 'm', ' ', 'C', 'e', 'r', 'e', 'a', 'l', 'b', 'o', 't', '.', ' ', ' ', ' ', '\0'},
        /* lcd.print("===================="); */
        {'=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '=', '\0'},
        /* lcd.print("  Chris 'ctag' Bero "); */
        {' ', ' ', 'C', 'h', 'r', 'i', 's', ' ', '\'', 'c', 't', 'a', 'g', '\'', ' ', 'B', 'e', 'r', 'o', ' ', '\0'}
};

/**
 * Global Variables
 */
char in_char = '\0';
char in_buffer[BUF_LEN+1];
unsigned short buffer_index = 0;
short int input_state = 0; // Current state for reading serial input.
Timer timer;
LiquidCrystal_I2C lcd(0x27,20,4); // I2C address 0x27, 20 char, 4 lines
// bool filament_alert = false;

/* Serial State Machine
 * 0: Out of state, discard. ':' -> go to 1.
 * 1: Record command. '\n' -> go to 2.
 * 2: Process command and go to 0.
 */

void lcdRefresh()
{
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print(system_states.LCDBUFFER_0);
        lcd.setCursor(0,1);
        lcd.print(system_states.LCDBUFFER_1);
        lcd.setCursor(0,2);
        lcd.print(system_states.LCDBUFFER_2);
        lcd.setCursor(0,3);
        lcd.print(system_states.LCDBUFFER_3);
}

void lcdWriteLine(char * text, int line)
{
        for (int i = 0; i < 20; i++)
        {
                system_states.LCDBUFFER_0[i+(21*line)] = text[i];
        }
        lcd.setCursor(0,line);
        lcd.print(text);
}

void ledToggle()
{
        if (system_states.LEDAUTO)
        {
                if (!system_states.LIGHT && analogRead(pinLightSensor) >= system_states.LEDTHRESHOLD)
                {
                        set_light(true);
                }
                else if (system_states.LIGHT && analogRead(pinLightSensor) < system_states.LEDTHRESHOLD)
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

void process_buffer_error(char const * region)
{
        Serial.print("\n\r\n\r>>> Error in process_buffer: [");
        Serial.print(region);
        Serial.println("] <<<");
        Serial.println("\n\r>>> Buffer Contents <<<");
        for (short int i = 0; i < BUFFER_LENGTH; i++)
        {
                Serial.print("[");
                Serial.print(i);
                Serial.print("]\t");
                Serial.print(in_buffer[i]);
                if (i%4 == 0)
                {
                        Serial.print("\n\r");
                }
        }
        reset_buffer();
}

void process_buffer(bool loud = false)
{
        if (loud) {
                Serial.print("\n\rProcessing: ");
                Serial.println(in_buffer);
        }

        /*
         * SET
         */
        if (in_buffer[0] == 's') // Set
        {
                if (in_buffer[1] == 'd') // Set display
                {
                        if (in_buffer[2] == 'r') // Set display refresh
                        {
                                lcdRefresh();
                        }
                        else
                        {
                            char tmp_buf[21];
                            for (short int i = 0; i < 20; i++)
                            {
                                    tmp_buf[i] = in_buffer[i+3];
                                    if (in_buffer[i+3] == '\0')
                                            break;
                            }
                            tmp_buf[20] = '\0';
                            if (in_buffer[2] == '0') // Set display line 0
                            {
                                    lcdWriteLine(tmp_buf, 0);
                            }
                            else if (in_buffer[2] == '1') // Set display line 1
                            {
                                    lcdWriteLine(tmp_buf, 1);
                            }
                            else if (in_buffer[2] == '2') // Set display line 2
                            {
                                    lcdWriteLine(tmp_buf, 2);
                            }
                            else if (in_buffer[2] == '3') // Set display line 3
                            {
                                    lcdWriteLine(tmp_buf, 3);
                            }
                            else
                            {
                                    process_buffer_error("sd");
                                    return;
                            }
                            save_states();
                        }
                }
                else if (in_buffer[1] == 's') // Set sensor
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
                                process_buffer_error("sf");
                                return;
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
                                process_buffer_error("sl");
                                return;
                        }
                } // end Set Light
                else // Set undefined
                {
                        process_buffer_error("s");
                        return;
                }
        } // end Set

        /*
         * GET
         */
        else if (in_buffer[0] == 'g') // Get
        {
                if (in_buffer[1] == 'd') // Get display
                {
                    if (in_buffer[2] == '0')
                    {
                        Serial.println(system_states.LCDBUFFER_0);
                    }
                    else if (in_buffer[2] == '1')
                    {
                        Serial.println(system_states.LCDBUFFER_1);
                    }
                    else if (in_buffer[2] == '2')
                    {
                        Serial.println(system_states.LCDBUFFER_2);
                    }
                    else if (in_buffer[2] == '3')
                    {
                        Serial.println(system_states.LCDBUFFER_3);
                    }
                    else
                    {
                        process_buffer_error("gd");
                        return;
                    }
                }
                else if (in_buffer[1] == 's') // Get Sensor
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
                        else
                        {
                            process_buffer_error("gs");
                            return;
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
                        process_buffer_error("g");
                        return;
                }
        } // end Get

        /*
         * LOAD
         */
        else if (in_buffer[0] == 'l')  // Load default
        {
                if (in_buffer[1] == 'a') // Load default states
                {
                        system_states = default_states;
                        save_states();
                }
                else                   // Load undefined
                {
                        process_buffer_error("l");
                        return;
                }
        } // end Load

        reset_buffer();
} // end process_buffer()

int main ()
{
        // Setup
        init(); // masked in normal setup()

        // Load variables
        load_states();

        // Set up pins
        pinMode(pinFanRelay, OUTPUT);
        pinMode(pinLightRelay, OUTPUT);
        pinMode(pinHumSensor, INPUT);
        pinMode(pinTempSensor, INPUT);
        pinMode(pinPlasticSensor, INPUT_PULLUP);

        // initialize the lcd
        lcd.init();
        lcd.backlight();

        // Configure devices as they were previously set
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
        lcdRefresh();

        // Initialize Serial
        Serial.begin(9600);
        delay(50);

        reset_buffer();
        delay(50);

        // Init timer for light sensor
        timer.every(15000, ledToggle);

        // MAIN LOOP
        while (1)
        {
                // Update light sensor timer
                timer.update();

                // Check on filament sensor
                if (digitalRead(pinPlasticSensor) == HIGH)
                {
                        Serial.println("!p0!");
                        while (digitalRead(pinPlasticSensor) == HIGH) {
                                delay(1000);
                        }
                }

                // Check on serial buffer
                if (Serial.available())
                {
                        in_char = Serial.read();

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
                                if (in_char == '\n' || in_char == '\r' || buffer_index == (BUF_LEN-1)) {
                                        in_buffer[buffer_index++] = '\0';
                                        process_buffer(true);
                                        input_state = 0;
                                } else if (in_char == '\b') {
                                        Serial.print(BACKSPACE);
                                        buffer_index--;
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
                                if (in_char == ']' || buffer_index == (BUF_LEN-1)) {
                                        in_buffer[buffer_index++] = '\0';
                                        process_buffer();
                                        input_state = 0;
                                } else if (in_char == '\b') {
                                        Serial.print(BACKSPACE);
                                        buffer_index--;
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
        } // End while-1 loop

        Serial.println("Arduino program exiting! D:");
        return(-1); // There is no spoon
} // end loop()
