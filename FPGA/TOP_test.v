module TOP_test(
    // 时钟和复位信号 
    input  wire         I_clk_25m,  // 25MHz晶振
    input  wire         I_rstn,      // 低有效复位信号
    // 3相 PWM 信号和使能信号
    output wire         O_pwm_en,   // 3相共用的使能信号，当 pwm_en=0 时，6个MOS管全部关断。
    output wire         O_pwm_a,    // A相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    output wire         O_pwm_b,    // B相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    output wire         O_pwm_c,    // C相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    // AD7928，用于相电流检测
    output wire         O_spi_ss,
    output wire         O_spi_sck,
    output wire         O_spi_mosi,
    input  wire         I_spi_miso,
    // AS5600 磁编码器
    output wire         O_i2c_scl,
    inout               IO_i2c_sda,
	// 霍尔编码器
    input  wire         I_hall_u,
    input  wire         I_hall_v,
    input  wire         I_hall_w,
    
    input  wire 		key1,
    input  wire 		key2,
    
    output wire 		O_uart_tx,
    output wire 		I_uart_Rx
);

wire S_rst;
assign S_rst = ~I_rstn;
wire S_clk_40m;
wire S_clk_100m;

pll u_pll(
    .refclk   ( I_clk_25m   ),
    .reset    ( S_rst       ),
    .clk0_out ( S_clk_100m 	),
    .clk1_out ( S_clk_40m 	)
);
    
//parameter [31:0] cnt_period = 32'd200000;
//reg [31:0] cnt;
//wire signed [15:0] id_aim;
//reg signed [15:0] iq_aim;
//assign id_aim = $signed(16'd0);          // 令 id_aim 恒等于 0

//always @ (posedge S_clk_40m or posedge S_rst)   
//    if(S_rst) begin
//        cnt <= 32'd0;
//        iq_aim <= 16'd0;
//    end else begin
//        if (cnt >= cnt_period) begin
//            cnt <= 32'd0;
//            if(key1 == 1'b0)
//            	iq_aim <= iq_aim + 1;
//            if(key2 == 1'b0)
//            	iq_aim <= iq_aim - 1;
//        end else 
//            cnt <= cnt + 32'd1;
//    end


// always @ (posedge S_clk_40m or posedge S_rst)   // 该 always 块令 iq_aim 交替地取 +200 和 -200 ，即电机的切向力矩一会顺时针一会逆时针
//     if(S_rst) begin
//         iq_aim <= $signed(16'd0);
//     end else begin
//         if(cnt[25])
//             iq_aim <=  $signed(16'd200); // 令 iq_aim = +200
//         else
//             iq_aim <= -$signed(16'd200); // 令 iq_aim = -200
//     end

//wire S_idq_update;
//wire signed [15:0] S_id;
//wire signed [15:0] S_iq;


//reg [31:0] swcnt;
//reg [31:0] period;

//foc_controller u_foc_controller(
//    // 时钟和复位信号 
//    .I_clk_40m          (S_clk_40m          ),      // PLL40MHZ输出
//    .I_rst              (S_rst              ),      // 高有效复位信号
//    // 3相 PWM 信号和使能信号
//    .O_pwm_en           (O_pwm_en           ),      // 3相共用的使能信号，当 pwm_en=0 时，6个MOS管全部关断。
//    .O_pwm_a            (O_pwm_a            ),      // A相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
//    .O_pwm_b            (O_pwm_b            ),      // B相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
//    .O_pwm_c            (O_pwm_c            ),      // C相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
//    // AD7928，用于相电流检测
//    .O_spi_ss           (O_spi_ss           ),
//    .O_spi_sck          (O_spi_sck          ),
//    .O_spi_mosi         (O_spi_mosi         ),
//    .I_spi_miso         (I_spi_miso         ),
//    // AS5600 磁编码器
//    .O_i2c_scl          (O_i2c_scl          ),
//    .IO_i2c_sda         (IO_i2c_sda         ),
//	// 霍尔编码器
//    .I_hall_u           (I_hall_u           ),
//    .I_hall_v           (I_hall_v           ),
//    .I_hall_w           (I_hall_w           ),
    
//    .I_motor_polePair   (8'd7               ),      // 电机极对数
//    .I_motor_dir        (1'd0               ),      // 电机方向，0选择uvw顺序驱动电机逆时针转动，1选择uvw顺序驱动电机逆时针转动
//    .I_encoder_dir      (1'd1               ),      // 编码器方向，0选择角度增长方向与电机正转同向，1选择角度增长方向与电机正转逆向
//    .I_encoder_sel      (1'd0               ),      // 选择编码器，0选择as5600磁编码器，1选择霍尔编码器
//    .I_id_aim           (id_aim    			),      // 转子 d 轴（直轴）的目标电流值
//    .I_iq_aim           (iq_aim  			),      // 转子 q 轴（交轴）的目标电流值
//    .S_id               (S_id                   ),      // 转子 d 轴（直轴）的实际电流值
//    .S_iq               (S_iq                   ),      // 转子 q 轴（交轴）的实际电流值
//    .S_idq_update       (S_idq_update                   ),      // 出现高电平脉冲时说明 id 和 iq 出现了新值，每个控制周期 en_idq 会产生一个高电平脉冲

//    .S_encoder_angle    (                   ),      // 编码器电角度输出，取值范围0~4095。0对应0°；1024对应90°；2048对应180°；3072对应270°
//    .S_hall_step        (                   )       // 霍尔编码器所在区间输出
    
    
//);

// UART 发送器(监视器)，格式为：115200,8,n,1
uart_monitor #(
    .CLK_DIV      ( 16'd347        )   // UART分频倍率，在本例中取320。因为时钟频率为 36.864MHz, 36.864MHz/320=115200
) u_uart_monitor (
    .rstn         ( I_rstn           ),
    .clk          ( S_clk_40m            ),
    .i_en         ( S_idq_update         ),  // input: 当 en_idq 上出现高电平脉冲时，启动 UART 发送
    .i_val0       ( S_id             ),  // input: 以十进制的形式发送变量 id
    .i_val1       ( id_aim         ),  // input: 以十进制的形式发送变量 id_aim
    .i_val2       ( S_iq             ),  // input: 以十进制的形式发送变量 iq
    .i_val3       ( iq_aim         ),  // input: 以十进制的形式发送变量 iq_aim
    .o_uart_tx    ( O_uart_tx        )   // output: UART 发送信号
);

//parameter init_cycle = 
//reg  [31:0]  init_cnt;
//reg  [11:0]  v_rho;
 reg  [11:0]  v_theta;

//always @ (posedge clk or posedge rst) begin
//	if(rst) begin
//    	v_rho <= 12'd0;
//    	v_theta <= 12'd0;
//    end else begin
//    	if(init_cnt < init_cycle)
//    		init_cnt <= init_cnt + 31'd1;
    	
//    end
//end


// parameter period = 32'd1525;

//always @ (posedge S_clk_40m or posedge S_rst)   
//    if(S_rst) begin
//        cnt <= 32'd0;
//        period <= 16'd0;
//    end else begin
//        if (cnt >= cnt_period) begin
//            cnt <= 32'd0;
//            if(key1 == 1'b0)
//            	period <= period + 1;
//            if(key2 == 1'b0)
//            	period <= period - 1;
//        end else 
//            cnt <= cnt + 32'd1;
//    end

//always @ (posedge S_clk_40m or posedge S_rst) begin
// 	if(S_rst) begin
//     	swcnt <= 0;
//        v_theta <= 0;
//     end else begin
// 		if(swcnt < period) begin
//         	swcnt <= swcnt + 'd1;
//        end else begin
//         	swcnt <= 0;
//             v_theta <= v_theta + 'd1;
//        end
// 	end
//end

//svpwm u_svpwm (
//    .rstn         ( I_rstn                     ),
//    .clk          ( S_clk_40m                      ),
//    .v_amp        ( 9'd100                  ),
//    .v_rho        ( 12'd4095                   ),  // input : Vsρ
//    .v_theta      ( v_theta                 ),  // input : Vsθ
//    .pwm_en       ( O_pwm_en                   ),  // output
//    .pwm_a        ( O_pwm_a                    ),  // output
//    .pwm_b        ( O_pwm_b                    ),  // output
//    .pwm_c        ( O_pwm_c                    )   // output
//);

endmodule
