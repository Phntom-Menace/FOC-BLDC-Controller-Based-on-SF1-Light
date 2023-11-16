/*
 * pid.h
 *
 *  Created on: 2023年11月10日
 *      Author: 15597
 */

#include <stdio.h>
#include "nuclei.h"
#ifndef APPLICATION_DEVICE_PID_H_
#define APPLICATION_DEVICE_PID_H_


static int64_t sum;
typedef struct {
	int32_t kp, ki, kg;
	int32_t error_sum;
	int32_t up_limit, down_limit;
} PID_STRUCT;

int32_t pid_update(PID_STRUCT pid, int32_t aim, int32_t real);


#endif /* APPLICATION_DEVICE_PID_H_ */
