#include <stdio.h>
#include "ahb.h"


void set_hall_en(uint8_t en) {
	hall_en = en;
}

uint32_t get_hall_en(void) {
	return hall_en;
}

uint32_t get_hall_angle(void) {
	return hall_angle;
}

uint32_t get_hall_error(void) {
	return hall_error;
}

uint32_t get_hall_lost(void) {
	return hall_lost;
}

uint32_t get_hall_step(void) {
	return hall_step;
}


