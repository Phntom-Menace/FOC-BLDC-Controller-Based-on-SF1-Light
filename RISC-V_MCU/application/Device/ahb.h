#include <stdio.h>
#include "nuclei.h"

#ifndef APPLICATION_DEVICE_PWM_H_
#define APPLICATION_DEVICE_PWM_H_

#define ENABLE  1
#define DISABLE 0

#define REGP(x) ((volatile unsigned int*)(x))
#define REG(x) (*((volatile unsigned int*)(x)))
#define REGP_8(x) (((volatile uint8_t*)(x)))

#define AHB_REGISTER_BASE_ADDR 0x40000000

#define HALL_EN	  	    AHB_REGISTER_BASE_ADDR + 0x0
#define HALL_ANGLE     	AHB_REGISTER_BASE_ADDR + 0x4
#define HALL_ERROR	    AHB_REGISTER_BASE_ADDR + 0x8
#define HALL_LOST     AHB_REGISTER_BASE_ADDR + 0xC
#define HALL_STEP     AHB_REGISTER_BASE_ADDR + 0x10

#define hall_en 		REG(HALL_EN)
#define hall_angle     	REG(HALL_ANGLE)
#define hall_error     	REG(HALL_ERROR)
#define hall_lost 		REG(HALL_LOST)
#define hall_step 		REG(HALL_STEP)

void set_hall_en(uint8_t en);

uint32_t get_hall_en(void);
uint32_t get_hall_angle(void);
uint32_t get_hall_error(void);
uint32_t get_hall_lost(void);
uint32_t get_hall_step(void);

#endif /* APPLICATION_DEVICE_PWM_H_ */
