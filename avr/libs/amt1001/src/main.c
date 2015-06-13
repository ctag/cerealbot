
#include <stdlib.h>
#include <string.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#include "adc/adc.h"

#define UART_BAUD_RATE 2400
#include "uart/uart.h"

#include "amt1001/amt1001.h"

int main(void) {
	char printbuff[100];
	//init uart
	uart_init( UART_BAUD_SELECT(UART_BAUD_RATE,F_CPU) );

	//init adc
	adc_init();

	//init interrupt
	sei();

	for (;;) {
		uart_puts("reading...\r\n");

		double adcvref = acd_getrealvref();

		//get adc H
		uint16_t adcH = adc_read(0);
		//get voltage H
		double adcvoltH = adc_getvoltage(adcH, adcvref);
		//get humidity
		int16_t humidity = amt1001_gethumidity(adcvoltH);

		//get adc T
		uint16_t adcT = adc_read(1);
		//get temperature
		int16_t temperature = amt1001_gettemperature(adcT);

		//humidity output
		itoa(adcH, printbuff, 10);
		uart_puts("adcH     "); uart_puts(printbuff); uart_puts("\r\n");
		dtostrf(adcvoltH, 3, 5, printbuff);
		uart_puts("voltH    "); uart_puts(printbuff); uart_puts("\r\n");
		itoa(humidity, printbuff, 10);
		uart_puts("> hum    "); uart_puts(printbuff); uart_puts("\r\n");

		//temperature output
		itoa(adcT, printbuff, 10);
		uart_puts("adcT     "); uart_puts(printbuff); uart_puts("\r\n");
		itoa(temperature, printbuff, 10);
		uart_puts("> temp   "); uart_puts(printbuff); uart_puts("\r\n");

		uart_puts("\r\n");

		_delay_ms(1000);
	}
	
	return 0;
}
