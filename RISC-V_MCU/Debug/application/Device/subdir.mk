################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../application/Device/ahb.c \
../application/Device/foc_controller.c \
../application/Device/forward_feed.c \
../application/Device/pid.c 

OBJS += \
./application/Device/ahb.o \
./application/Device/foc_controller.o \
./application/Device/forward_feed.o \
./application/Device/pid.o 

C_DEPS += \
./application/Device/ahb.d \
./application/Device/foc_controller.d \
./application/Device/forward_feed.d \
./application/Device/pid.d 


# Each subdirectory must supply rules for building sources it contributes
application/Device/%.o: ../application/Device/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-nuclei-elf-gcc -march=rv32imac -mabi=ilp32 -mcmodel=medany -mno-save-restore -O0 -ffunction-sections -fdata-sections -fno-common  -g -DDOWNLOAD_MODE=DOWNLOAD_MODE_WORK3 -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\sf1_sdk\SoC\anlogic\Board\sf1_eval\Include" -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\application" -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\sf1_sdk\NMSIS\Core\Include" -I"C:\Users\15597\Desktop\sf1\FutureDynasty_workspace\foc_controller\sf1_sdk\SoC\anlogic\Common\Include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


