################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../application/main.c 

OBJS += \
./application/main.o 

C_DEPS += \
./application/main.d 


# Each subdirectory must supply rules for building sources it contributes
application/%.o: ../application/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-nuclei-elf-gcc -march=rv32imac -mabi=ilp32 -mcmodel=medany -mno-save-restore -O0 -ffunction-sections -fdata-sections -fno-common  -g -DDOWNLOAD_MODE=DOWNLOAD_MODE_WORK3 -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\sf1_sdk\SoC\anlogic\Board\sf1_eval\Include" -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\application" -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\sf1_sdk\NMSIS\Core\Include" -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\sf1_sdk\SoC\anlogic\Common\Include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


