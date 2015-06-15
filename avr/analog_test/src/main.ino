//#include <Servo.h>
// http://davidegironi.blogspot.com/2013/07/amt1001-humidity-and-temperature-sensor.html
//#include <amt1001.h>


/**
 * Definitions
 */
const unsigned short int BUF_LEN = 5;

/**
 * Global Variables
 */
char in_char = '\0';
char in_buffer[BUF_LEN+1] = "000";

/**
 * Pin Mappings
 */
short analogPin = A2;

/**
 * Function prototypes
 */
void reset_buffer ();

void setup()
{
	pinMode(analogPin, INPUT);
	
	Serial.begin(9600);
	
	delay(50);
}

void loop()
{
	if ((millis()%10000) == 0) {
		int val = analogRead(analogPin);
		Serial.print("Analog: [");
		Serial.print(val);
		Serial.println("].");
	}
}








