/*
 * foc_controller.h
 *
 *  Created on: 2023年11月10日
 *      Author: 15597
 */

#include <stdio.h>
#include "nuclei.h"

#ifndef APPLICATION_DEVICE_FOC_CONTROLLER_H_
#define APPLICATION_DEVICE_FOC_CONTROLLER_H_

#define ENABLE  1
#define DISABLE 0

#define REGP(x) ((volatile unsigned int*)(x))
#define REG(x) (*((volatile unsigned int*)(x)))
#define REGP_8(x) (((volatile uint8_t*)(x)))

#define AHB_REGISTER_BASE_ADDR 			0x40000000
#define FOC_CONTROLLER_MODULE_BASE_ADDR 0x00100000

// 基础配置
#define FOC_EN              	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0000    // 0x0000 RW 模块使能 高有效
#define FOC_MOTOR_POLEPAIR  	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0004    // 0x0004 RW 电机极对数
#define FOC_MOTOR_DIR       	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0008    // 0x0008 RW 电机方向，0选择uvw顺序驱动电机逆时针转动，1选择uvw顺序驱动电机逆时针转动
#define FOC_ENCODER_SEL     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x000C    // 0x000C RW 选择编码器，0选择as5600磁编码器，1选择霍尔编码器
#define FOC_ENCODER_DIR     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0010    // 0x0010 RW 编码器方向，0选择角度增长方向与电机正转同向，1选择角度增长方向与电机正转逆向
// 控制模式选择和目标量设置
#define FOC_CONTROL_MODE    	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0100    // 0x0100 RW 闭环控制模式 0电流环 1速度环 2位置环 3开环
#define FOC_CURRENT_ID_AIM  	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0104    // 0x0104 RW 电流环id目标电流
#define FOC_CURRENT_IQ_AIM  	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0108    // 0x0108 RW 电流环iq目标电流
#define FOC_VELOCITY_AIM    	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x010C    // 0x010C RW 速度环目标转速
#define FOC_POSITION_AIM    	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0110    // 0x0110 RW 位置环目标角度
#define FOC_VOLTAGE_VD      	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0114    // 0x0114 RW 开环vd电压
#define FOC_VOLTAGE_VQ      	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0118    // 0x0118 RW 开环vq电压
// PI和前馈参数
#define FOC_CURRENT_ID_KP   	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0200    // 0x0200 RW 电流环id PI控制器 Kp
#define FOC_CURRENT_ID_KI   	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0204    // 0x0204 RW 电流环id PI控制器 Ki
#define FOC_CURRENT_ID_FG   	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0208    // 0x0208 RW 电流环id 前馈控制器 Gain
#define FOC_CURRENT_IQ_KP   	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x020C    // 0x020C RW 电流环iq PI控制器 Kp
#define FOC_CURRENT_IQ_KI   	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0210    // 0x0210 RW 电流环iq PI控制器 Ki
#define FOC_CURRENT_IQ_FG   	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0214    // 0x0214 RW 电流环iq 前馈控制器 Gain
#define FOC_VELOCITY_KP     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0218    // 0x0218 RW 速度环 PI控制器 Kp
#define FOC_VELOCITY_KI     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x021C    // 0x021C RW 速度环 PI控制器 Ki
#define FOC_VELOCITY_FG     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0220    // 0x0220 RW 速度环 前馈控制器 Gain
#define FOC_POSITION_KP     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0224    // 0x0224 RW 位置环 PI控制器Kp
#define FOC_POSITION_KI     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0228    // 0x0228 RW 位置环 PI控制器 Ki
#define FOC_POSITION_FG     	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x022C    // 0x022C RW 位置环 前馈控制器 Gain
// 需要被读取的数据
#define FOC_INIT_DONE       	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0300    // 0x0300 RO 初始化完成信号
#define FOC_CURRENT_ID      	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0304    // 0x0304 RO 当前id电流量
#define FOC_CURRENT_IQ      	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0308    // 0x0308 RO 当前iq电流量
#define FOC_VELOCITY        	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x030C    // 0x030C RO 当前速度量
#define FOC_POSITION        	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0310    // 0x0310 RO 当前位置量
#define FOC_ANGLE_ELE       	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0314    // 0x0314 RO 转子电角度
#define FOC_ANGLE_MEC       	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0318    // 0x0318 RO 转子机械角度
#define FOC_HALL_STEP       	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x031C    // 0x031C RO 霍尔编码器所在区间
#define FOC_CURRENT_IA      	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0320    // 0x0320 RO A相电流值
#define FOC_CURRENT_IB      	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0324    // 0x0324 RO B相电流值
#define FOC_CURRENT_IC      	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0328    // 0x0328 RO C相电流值
#define FOC_VOLTAGE_VR_RHO  	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x032C    // 0x032C RO 转子极坐标系上的电压矢量的幅值
#define FOC_VOLTAGE_VR_THETA	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0330    // 0x0330 RO 转子极坐标系上的电压矢量的角度
#define FOC_VOLTAGE_VS_RHO  	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0334    // 0x0334 RO 定子极坐标系上的电压矢量的幅值
#define FOC_VOLTAGE_VS_THETA	AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0338    // 0x0338 RO 定子极坐标系上的电压矢量的角度
#define FOC_MID_CURRENT_ID_AIM  AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x033C	 // 0x033C RO 电流环转子d轴（直轴）的目标电流值
#define FOC_MID_CURRENT_IQ_AIM  AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0340	 // 0x0340 RO 电流环转子q轴（交轴）的目标电流值
#define FOC_MID_VELOCITY_AIM    AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0344	 // 0x0344 RO 速度环目标转速
#define FOC_MID_POSITION_AIM    AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0348	 // 0x0348 RO 位置环目标角度
#define FOC_MID_VOLTAGE_VD      AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x034C	 // 0x034C RO 开环vd电压
#define FOC_MID_VOLTAGE_VQ      AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0350	 // 0x0350 RO 开环vq电压
#define FOC_ANGLE_VELOCITY      AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x0354	 // 0x0354 RO 机械角度转速
#define FOC_ANGLE_POSITION      AHB_REGISTER_BASE_ADDR + FOC_CONTROLLER_MODULE_BASE_ADDR + 0x035C	 // 0x035C RO 累计机械角度

// 基础配置
#define foc_en              	REG(FOC_EN  				)    // 0x0000 RW 模块使能 高有效
#define foc_motor_polePair  	REG(FOC_MOTOR_POLEPAIR      )    // 0x0004 RW 电机极对数
#define foc_motor_dir       	REG(FOC_MOTOR_DIR       	)    // 0x0008 RW 电机方向，0选择uvw顺序驱动电机逆时针转动，1选择uvw顺序驱动电机逆时针转动
#define foc_encoder_sel     	REG(FOC_ENCODER_SEL     	)    // 0x000C RW 选择编码器，0选择as5600磁编码器，1选择霍尔编码器
#define foc_encoder_dir     	REG(FOC_ENCODER_DIR     	)    // 0x0010 RW 编码器方向，0选择角度增长方向与电机正转同向，1选择角度增长方向与电机正转逆向
// 控制模式选择和目标量设置
#define foc_control_mode    	REG(FOC_CONTROL_MODE    	)    // 0x0100 RW 闭环控制模式 0电流环 1速度环 2位置环 3开环
#define foc_current_id_aim  	REG(FOC_CURRENT_ID_AIM  	)    // 0x0104 RW 电流环id目标电流
#define foc_current_iq_aim  	REG(FOC_CURRENT_IQ_AIM  	)    // 0x0108 RW 电流环iq目标电流
#define foc_velocity_aim    	REG(FOC_VELOCITY_AIM    	)    // 0x010C RW 速度环目标转速
#define foc_position_aim    	REG(FOC_POSITION_AIM    	)    // 0x0110 RW 位置环目标角度
#define foc_voltage_vd      	REG(FOC_VOLTAGE_VD      	)    // 0x0114 RW 开环vd电压
#define foc_voltage_vq      	REG(FOC_VOLTAGE_VQ      	)    // 0x0118 RW 开环vq电压
// PI和前馈参数
#define foc_current_id_kp   	REG(FOC_CURRENT_ID_KP   	)    // 0x0200 RW 电流环id PI控制器 Kp
#define foc_current_id_ki   	REG(FOC_CURRENT_ID_KI   	)    // 0x0204 RW 电流环id PI控制器 Ki
#define foc_current_id_fg   	REG(FOC_CURRENT_ID_FG   	)    // 0x0208 RW 电流环id 前馈控制器 Gain
#define foc_current_iq_kp   	REG(FOC_CURRENT_IQ_KP   	)    // 0x020C RW 电流环iq PI控制器 Kp
#define foc_current_iq_ki   	REG(FOC_CURRENT_IQ_KI   	)    // 0x0210 RW 电流环iq PI控制器 Ki
#define foc_current_iq_fg   	REG(FOC_CURRENT_IQ_FG   	)    // 0x0214 RW 电流环iq 前馈控制器 Gain
#define foc_velocity_kp     	REG(FOC_VELOCITY_KP     	)    // 0x0218 RW 速度环 PI控制器 Kp
#define foc_velocity_ki     	REG(FOC_VELOCITY_KI     	)    // 0x021C RW 速度环 PI控制器 Ki
#define foc_velocity_fg     	REG(FOC_VELOCITY_FG     	)    // 0x0220 RW 速度环 前馈控制器 Gain
#define foc_position_kp     	REG(FOC_POSITION_KP     	)    // 0x0224 RW 位置环 PI控制器Kp
#define foc_position_ki     	REG(FOC_POSITION_KI     	)    // 0x0228 RW 位置环 PI控制器 Ki
#define foc_position_fg     	REG(FOC_POSITION_FG     	)    // 0x022C RW 位置环 前馈控制器 Gain
// 需要被读取的数据
#define foc_init_done       	REG(FOC_INIT_DONE       	)    // 0x0300 RO 初始化完成信号
#define foc_current_id      	REG(FOC_CURRENT_ID      	)    // 0x0304 RO 当前id电流量
#define foc_current_iq      	REG(FOC_CURRENT_IQ      	)    // 0x0308 RO 当前iq电流量
#define foc_velocity        	REG(FOC_VELOCITY        	)    // 0x030C RO 当前速度量
#define foc_position        	REG(FOC_POSITION        	)    // 0x0310 RO 当前位置量
#define foc_angle_ele       	REG(FOC_ANGLE_ELE       	)    // 0x0314 RO 转子电角度
#define foc_angle_mec       	REG(FOC_ANGLE_MEC       	)    // 0x0318 RO 转子机械角度
#define foc_hall_step       	REG(FOC_HALL_STEP       	)    // 0x031C RO 霍尔编码器所在区间
#define foc_current_ia      	REG(FOC_CURRENT_IA      	)    // 0x0320 RO A相电流值
#define foc_current_ib      	REG(FOC_CURRENT_IB      	)    // 0x0324 RO B相电流值
#define foc_current_ic      	REG(FOC_CURRENT_IC      	)    // 0x0328 RO C相电流值
#define foc_voltage_vr_rho  	REG(FOC_VOLTAGE_VR_RHO  	)    // 0x032C RO 转子极坐标系上的电压矢量的幅值
#define foc_voltage_vr_theta	REG(FOC_VOLTAGE_VR_THETA	)    // 0x0330 RO 转子极坐标系上的电压矢量的角度
#define foc_voltage_vs_rho  	REG(FOC_VOLTAGE_VS_RHO  	)    // 0x0334 RO 定子极坐标系上的电压矢量的幅值
#define foc_voltage_vs_theta	REG(FOC_VOLTAGE_VS_THETA	)    // 0x0338 RO 定子极坐标系上的电压矢量的角度
#define foc_mid_current_id_aim  REG(FOC_MID_CURRENT_ID_AIM	)	 // 0x033C RO 电流环转子d轴（直轴）的目标电流值
#define foc_mid_current_iq_aim  REG(FOC_MID_CURRENT_IQ_AIM	)	 // 0x0340 RO 电流环转子q轴（交轴）的目标电流值
#define foc_mid_velocity_aim    REG(FOC_MID_VELOCITY_AIM  	)	 // 0x0344 RO 速度环目标转速
#define foc_mid_position_aim    REG(FOC_MID_POSITION_AIM  	)	 // 0x0348 RO 位置环目标角度
#define foc_mid_voltage_vd      REG(FOC_MID_VOLTAGE_VD    	)	 // 0x034C RO 开环vd电压
#define foc_mid_voltage_vq      REG(FOC_MID_VOLTAGE_VQ    	)	 // 0x0350 RO 开环vq电压
#define foc_angle_velocity      REG(FOC_ANGLE_VELOCITY    	)	 // 0x0354 RO 机械角度转速
#define foc_angle_position      REG(FOC_ANGLE_POSITION    	)	 // 0x035C RO 累计机械角度

void foc_set(volatile unsigned int* addr, uint32_t value);
uint32_t foc_get(volatile unsigned int* addr);

#endif /* APPLICATION_DEVICE_FOC_CONTROLLER_H_ */
