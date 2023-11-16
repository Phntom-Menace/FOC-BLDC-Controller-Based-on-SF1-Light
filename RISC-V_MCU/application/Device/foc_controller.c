/*
 * foc_controller.c
 *
 *  Created on: 2023年11月10日
 *      Author: 15597
 */

#include <stdio.h>
#include "foc_controller.h"


void foc_set(volatile unsigned int* addr, uint32_t value) {
	REG(addr) = value;
}
uint32_t foc_get(volatile unsigned int* addr) {
	return REG(addr);
}


