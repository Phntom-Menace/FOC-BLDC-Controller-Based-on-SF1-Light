#include "nuclei_sdk_soc.h"
#include "./Device/foc_controller.h"
#include "../../../SoC/anlogic/Board/sf1_eval/Include/nuclei_sdk_hal.h"
#include "nuclei_uart.h"
#include <math.h>

#define SWIRQ_INTLEVEL_HIGHER   1

#define HIGHER_INTLEVEL         2
#define LOWER_INTLEVEL          1

#define TIMER_TICKS             (0.0001 * SOC_TIMER_FREQ) // 100us

//#define V_KP 3000
//#define V_KI 2000
//#define V_KD 100
//#define V_KG 3500
#define V_KP (200)
#define V_KI (200)
#define V_KD (5000)
#define V_KG (300)
#define V_SUM_UPLIMIT   (50)
#define V_SUM_DOWNLIMIT (-50)
#define V_OUT_UPLIMIT   (4000)
#define V_OUT_DOWNLIMIT (-4000)

#define P_KP 100
#define P_KI 0
#define P_KD 1000
#define P_KG 0
#define P_SUM_UPLIMIT   1000
#define P_SUM_DOWNLIMIT -1000
#define P_OUT_UPLIMIT   50
#define P_OUT_DOWNLIMIT -50


int32_t id_aim, iq_aim, v_aim, p_aim, vd_aim, vq_aim, i_dir = 1, cycle_method = 0;

int32_t inc_dir = 0, inc_value = 0;


int32_t pid_v_update(int32_t aim, int32_t real) {
	int32_t error = aim - real;
	static int32_t error_sum = 0, last_error = 0;
	error_sum += error;
	int32_t out = (error * V_KP + error_sum * V_KI + (error-last_error) * V_KD + aim * V_KG)/10;
//	int32_t out = error * pid.kp;
	if(error_sum > V_SUM_UPLIMIT) error_sum = V_SUM_UPLIMIT;
	if(error_sum < V_SUM_DOWNLIMIT) error_sum = V_SUM_DOWNLIMIT;
	if(out > V_OUT_UPLIMIT) out = V_OUT_UPLIMIT;
	if(out < V_OUT_DOWNLIMIT) out = V_OUT_DOWNLIMIT;
	last_error = error;
	return out;
//	return out + aim * pid.kg;
}


int32_t pid_p_update(int32_t aim, int32_t real) {
	int32_t error = aim - real;
	static int32_t error_sum = 0, last_error = 0;
	error_sum += error;
	int32_t out = (P_KP * error + P_KI * error_sum + P_KD * (error-last_error) + aim * P_KG)/1000;
	if(error_sum > P_SUM_UPLIMIT) error_sum = P_SUM_UPLIMIT;
	if(error_sum < P_SUM_DOWNLIMIT) error_sum = P_SUM_DOWNLIMIT;
	if(out > P_OUT_UPLIMIT) out = P_OUT_UPLIMIT;
	if(out < P_OUT_DOWNLIMIT) out = P_OUT_DOWNLIMIT;
	last_error = error;
	return out;
}

// UART
uint32_t uart_reg;
uint8_t uart_rec;
void uart_receive(void) {
	uart_reg = UART0->RXFIFO;
	if(!(uart_reg & UART_RXFIFO_EMPTY)) {
		uart_rec = uart_reg & 0x000000ff;
		if(uart_rec == '0')
			i_dir = !i_dir;
		if(uart_rec == '1') {
			foc_control_mode = foc_control_mode == 3 ? 0 : foc_control_mode + 1;
		}
		if(uart_rec == '2') {
			cycle_method = !cycle_method;
			inc_dir = 1;
			inc_value = 0;
		}
	}
}

// setup timer
void setup_timer(void)
{
    printf("Initialize timer and start timer interrupt periodly\n\r");
    SysTick_Config(TIMER_TICKS);
}

// timer interrupt handler
// non-vector mode interrupt
// mtip:Machine-mode Timer Interrupt Pending Register
void eclic_mtip_handler(void)
{
    static uint32_t int_t_cnt = 0;    /* timer interrupt counter */
    // trigger software interrupt
    SysTimer_SetSWIRQ();

    // Reload Timer Interrupt
    SysTick_Reload(TIMER_TICKS);

}

// timer software interrupt handler
// vector mode interrupt
// msip:Machine mode Software Interrupt Pending Register机器模式软件中断等待寄存�?
__INTERRUPT void eclic_msip_handler(void)
{
    static uint32_t int_sw_cnt = 0;   /* software interrupt counter */

    // save CSR context
    SAVE_IRQ_CSR_CONTEXT();
    uart_receive();
    if(cycle_method == 1) {
    	if(inc_value >= 1000) {
    		inc_dir = -1;
    	}
    	if(inc_value <= -1000) {
    		inc_dir = 1;
    	}
    	inc_value += inc_dir;
    }

    // foc 控制
    switch(foc_control_mode) {
    	// 电流环
    	case 0:
    		foc_current_id_aim = id_aim;
    		foc_current_iq_aim = iq_aim;
    		anl_printf("%d, %d, %d, %d, %d\n", foc_control_mode, foc_current_id_aim, foc_current_id, foc_current_iq_aim, foc_current_iq, foc_angle_velocity);

    		break;
    	// 速度环
    	case 1:
    		foc_current_id_aim = id_aim;
    		if(i_dir == 1) {
    			foc_current_iq_aim = -(int32_t)pid_v_update(v_aim, foc_angle_velocity);
    		} else {
    			foc_current_iq_aim = (int32_t)pid_v_update(v_aim, foc_angle_velocity);
    		}
    		anl_printf("%d, %d, %d\n", foc_control_mode, v_aim, foc_angle_velocity);
    		break;
		// 位置环
		case 2:
    		foc_current_id_aim = id_aim;
    		if(i_dir == 1) {
        		foc_current_iq_aim = -(int32_t)pid_v_update(pid_p_update(p_aim, foc_angle_position), foc_angle_velocity);
        	} else {
        		foc_current_iq_aim = (int32_t)pid_v_update(pid_p_update(p_aim, foc_angle_position), foc_angle_velocity);
        	}
    		anl_printf("%d, %d, %d\n", foc_control_mode, p_aim, foc_angle_position);

			break;
		// 开环
		case 3:
			foc_voltage_vd = (int32_t)vd_aim;
			foc_voltage_vq = (int32_t)vq_aim;
    		anl_printf("%d, %d, %d\n", foc_control_mode, vd_aim, vq_aim);

			break;
    }
    SysTimer_ClearSWIRQ();
    // restore CSR context
    RESTORE_IRQ_CSR_CONTEXT();
}

void init();


int main(void)
{
	init();
	while (!foc_init_done);
	
    while(1) {

//    	delay_1ms(10);
    	if(cycle_method == 0) {
        	if (foc_control_mode == 0) {
            	// 电流环
            	iq_aim = 2000;
            	delay_1ms(1000);
            	iq_aim = -2000;
            	delay_1ms(1000);
        	} else if (foc_control_mode == 1){
            	// 速度环
            	v_aim = 50;
            	delay_1ms(1000);
            	v_aim = -50;
            	delay_1ms(1000);
        	} else if (foc_control_mode == 2){
            	// 位置环
            	p_aim = 1024;
            	delay_1ms(1000);
            	p_aim = -1024;
            	delay_1ms(1000);
        	} else if (foc_control_mode == 3){
            	// 开环
        		vq_aim = 1000;
            	delay_1ms(1000);
            	vq_aim = -1000;
            	delay_1ms(1000);
        	}
    	} else {
        	delay_1ms(1);
        	if (foc_control_mode == 0) {
            	// 电流环
            	iq_aim = inc_value * 2;
        	} else if (foc_control_mode == 1){
            	// 速度环
            	v_aim = inc_value * 0.040;
        	} else if (foc_control_mode == 2){
            	// 位置环
            	p_aim = inc_value * 2;
        	} else if (foc_control_mode == 3){
            	// 开环
        		foc_voltage_vq = inc_value;
        	}
    	}


    }
    return 0;
}

void init() {

	// uart
    uart_init(UART0, 115200,UART_BIT_LENGTH_8);
    uart_config_stopbit(UART0,UART_STOP_BIT_1);

    // foc
	foc_motor_polePair = 7;
	foc_encoder_sel = 0;
	foc_encoder_dir = 1;
	foc_control_mode = 2;
	if (foc_control_mode == 0) {
    	// 电流环
		vd_aim = 0;
		vq_aim = 0;
	} else if (foc_control_mode == 1){
    	// 速度环
		id_aim = 0;
		v_aim = 0;
	} else if (foc_control_mode == 2){
    	// 位置环
    	p_aim = 0;
	} else if (foc_control_mode == 3){
    	// 开环
		vd_aim = 0;
		vq_aim = 0;
	}


	foc_current_id_kp = 30000;
	foc_current_id_ki = 3000;
	foc_current_iq_kp = 30000;
	foc_current_iq_ki = 3000;
	foc_en = 1;

	// timer
	uint8_t timer_intlevel, swirq_intlevel;
#if SWIRQ_INTLEVEL_HIGHER == 1
    timer_intlevel = LOWER_INTLEVEL;
    swirq_intlevel = HIGHER_INTLEVEL;
#else
    timer_intlevel = HIGHER_INTLEVEL;
    swirq_intlevel = LOWER_INTLEVEL;
#endif


    // initialize software interrupt as vector interrupt
    ECLIC_Register_IRQ(SysTimerSW_IRQn, ECLIC_VECTOR_INTERRUPT,
                    ECLIC_LEVEL_TRIGGER, swirq_intlevel, 0, eclic_msip_handler);

    // inital timer interrupt as non-vector interrupt
    ECLIC_Register_IRQ(SysTimer_IRQn, ECLIC_NON_VECTOR_INTERRUPT,
                    ECLIC_LEVEL_TRIGGER, timer_intlevel, 0, eclic_mtip_handler);

    // Enable interrupts in general.
    __enable_irq();

    // initialize timer
    setup_timer();

    anl_printf("Init done\r\n");
}
