module ahb_foc_controller(
    // AHB时钟和复位信号
    input               I_ahb_clk,
    input               I_rst,
    // AHB总线
    input   [1:0]       I_ahb_htrans,
    input               I_ahb_hwrite,
    input   [31:0]      I_ahb_haddr,       //synthesis keep
    input   [2:0]       I_ahb_hsize,
    input   [2:0]       I_ahb_hburst,
    input   [3:0]       I_ahb_hprot,
    input               I_ahb_hmastlock,
    input   [31:0]      I_ahb_hwdata,      //synthesis keep
    output  reg [31:0]  O_ahb_hrdata,      //synthesis keep
    output  wire[1:0]   O_ahb_hresp,
    output  reg         O_ahb_hready,
    
    // PLL 40MHz时钟输入
    input  wire         I_clk_40m,
    // 3相 PWM 信号和使能信号
    output wire         O_pwm_en, 
    output wire         O_pwm_a,    
    output wire         O_pwm_b,    
    output wire         O_pwm_c,    
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
    input  wire         I_hall_w
);
    parameter   [31:0]  P_foc_addr_base = 32'h40100000;    // 此模块在AHB总线的基地址

    // AHB总线
    reg                 S_ahb_wr_trig;
    reg                 S_ahb_wr_trig_1d;
    reg         [31:0]  S_ahb_wr_addr;
    reg         [31:0]  S_ahb_wr_data;

    reg                 S_ahb_rd_trig;
    reg                 S_ahb_rd_trig_1d;
    reg         [31:0]  S_ahb_rd_addr;
    reg         [31:0]  S_ahb_rd_data; 

    // -------- Registers -------- 
    // 基础配置
    reg         [31:0]	R_en;                 // 0x0000 RW 模块使能 高有效
    reg         [31:0]	R_motor_polePair;     // 0x0004 RW 电机极对数
    reg         [31:0]	R_motor_dir;          // 0x0008 RW 电机方向，0选择uvw顺序驱动电机逆时针转动，1选择uvw顺序驱动电机逆时针转动
    reg         [31:0]	R_encoder_sel;        // 0x000C RW 选择编码器，0选择as5600磁编码器，1选择霍尔编码器
    reg         [31:0]	R_encoder_dir;        // 0x0010 RW 编码器方向，0选择角度增长方向与电机正转同向，1选择角度增长方向与电机正转逆向
    // 控制模式选择和目标量设置
    reg         [31:0]	R_control_mode;       // 0x0100 RW 闭环控制模式 0电流环 1速度环 2位置环 3开环
    reg signed  [31:0]  R_current_id_aim;     // 0x0104 RW 电流环id目标电流
    reg signed  [31:0]  R_current_iq_aim;     // 0x0108 RW 电流环iq目标电流
    reg signed  [31:0]  R_velocity_aim;       // 0x010C RW 速度环目标转速
    reg signed  [31:0]  R_position_aim;       // 0x0110 RW 位置环目标角度
    reg signed  [31:0]	R_voltage_vd;         // 0x0114 RW 开环vd电压
    reg signed  [31:0]	R_voltage_vq;         // 0x0118 RW 开环vq电压
    // PI和前馈参数
    reg signed  [31:0]  R_current_id_kp;      // 0x0200 RW 电流环id PI控制器 Kp
    reg signed  [31:0]  R_current_id_ki;      // 0x0204 RW 电流环id PI控制器 Ki
    reg signed  [31:0]  R_current_id_fg;      // 0x0208 RW 电流环id 前馈控制器 Gain
    reg signed  [31:0]  R_current_iq_kp;      // 0x020C RW 电流环iq PI控制器 Kp
    reg signed  [31:0]  R_current_iq_ki;      // 0x0210 RW 电流环iq PI控制器 Ki
    reg signed  [31:0]  R_current_iq_fg;      // 0x0214 RW 电流环iq 前馈控制器 Gain
    reg signed  [31:0]  R_velocity_kp;        // 0x0218 RW 速度环 PI控制器 Kp
    reg signed  [31:0]  R_velocity_ki;        // 0x021C RW 速度环 PI控制器 Ki
    reg signed  [31:0]  R_velocity_fg;        // 0x0220 RW 速度环 前馈控制器 Gain
    reg signed  [31:0]  R_position_kp;        // 0x0224 RW 位置环 PI控制器Kp
    reg signed  [31:0]  R_position_ki;        // 0x0228 RW 位置环 PI控制器 Ki
    reg signed  [31:0]  R_position_fg;        // 0x022C RW 位置环 前馈控制器 Gain
    // 需要被读取的数据
    reg         [31:0]	R_init_done;          // 0x0300 RO 初始化完成信号
    reg signed  [31:0]	R_current_id;         // 0x0304 RO 当前id电流量
    reg signed  [31:0]	R_current_iq;         // 0x0308 RO 当前iq电流量
    reg signed  [31:0]	R_velocity;           // 0x030C RO 当前速度量
    reg signed  [31:0]	R_position;           // 0x0310 RO 当前位置量
    reg         [31:0]	R_angle_ele;          // 0x0314 RO 转子电角度
    reg         [31:0]	R_angle_mec;          // 0x0318 RO 转子机械角度
    reg         [31:0]	R_hall_step;          // 0x031C RO 霍尔编码器所在区间
    reg signed  [31:0]	R_current_ia;         // 0x0320 RO A相电流值
    reg signed  [31:0]	R_current_ib;         // 0x0324 RO B相电流值
    reg signed  [31:0]	R_current_ic;         // 0x0328 RO C相电流值
    reg         [31:0]	R_voltage_vr_rho;     // 0x032C RO 转子极坐标系上的电压矢量的幅值
    reg         [31:0]	R_voltage_vr_theta;   // 0x0330 RO 转子极坐标系上的电压矢量的角度
    reg         [31:0]	R_voltage_vs_rho;     // 0x0334 RO 定子极坐标系上的电压矢量的幅值
    reg         [31:0]	R_voltage_vs_theta;   // 0x0338 RO 定子极坐标系上的电压矢量的角度
	reg  signed [15:0]  R_mid_current_id_aim; // 0x033C RO 电流环转子d轴（直轴）的目标电流值
	reg  signed [15:0]  R_mid_current_iq_aim; // 0x0340 RO 电流环转子q轴（交轴）的目标电流值
	reg  signed [15:0]  R_mid_velocity_aim;   // 0x0344 RO 速度环目标转速
	reg  signed [15:0]  R_mid_position_aim;   // 0x0348 RO 位置环目标角度
	reg  signed [15:0]  R_mid_voltage_vd;     // 0x034C RO 开环vd电压
	reg  signed [15:0]  R_mid_voltage_vq;     // 0x0350 RO 开环vq电压
	reg  signed [31:0]  R_angle_velocity;     // 0x0354 RO 机械角度转速
    reg  signed [31:0]  R_angle_position;	  // 0x0358 RO 累计机械角度

    // -------- Wires -------- 
    // 模块与只读寄存器连接线
    wire                S_init_done;          
    wire signed [15:0]  S_current_id;         
    wire signed [15:0]  S_current_iq;         
    wire signed [31:0]  S_velocity;           
    wire signed [31:0]  S_position;           
    wire        [11:0]  S_angle_ele;          
    wire        [11:0]  S_angle_mec;          
    wire        [ 2:0]  S_hall_step;          
    wire signed [15:0]  S_current_ia;         
    wire signed [15:0]  S_current_ib;         
    wire signed [15:0]  S_current_ic;         
    wire        [11:0]  S_voltage_vr_rho;     
    wire        [11:0]  S_voltage_vr_theta;   
    wire        [11:0]  S_voltage_vs_rho;     
    wire        [11:0]  S_voltage_vs_theta;
	wire signed [15:0]  S_mid_current_id_aim;      // 电流环转子d轴（直轴）的目标电流值
	wire signed [15:0]  S_mid_current_iq_aim;      // 电流环转子q轴（交轴）的目标电流值
	wire signed [15:0]  S_mid_velocity_aim;        // 速度环目标转速
	wire signed [15:0]  S_mid_position_aim;        // 位置环目标角度
	wire signed [15:0]  S_mid_voltage_vd;          // 开环vd电压
	wire signed [15:0]  S_mid_voltage_vq;          // 开环vq电压
	wire signed [31:0]  S_angle_velocity;          // 机械角度转速
    wire signed [31:0]  S_angle_position;

    // AHB 总线逻辑
    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            O_ahb_hready <= 1'b1;
        else
            if(I_ahb_htrans == 2'b10)
                O_ahb_hready <= 1'b0;
            else if(S_ahb_wr_trig_1d || S_ahb_rd_trig_1d)
                O_ahb_hready <= 1'b1;
            else
                O_ahb_hready <= O_ahb_hready;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_wr_trig <= 1'b0;
        else
            if(I_ahb_htrans == 2'b10 && I_ahb_hwrite)
                S_ahb_wr_trig <= 1'b1;
            else
                S_ahb_wr_trig <= 1'b0;
    end

    always @(posedge I_ahb_clk) begin
        S_ahb_wr_trig_1d <= S_ahb_wr_trig;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_wr_addr <= 'd0;
        else
            if(S_ahb_wr_trig)
                S_ahb_wr_addr <= I_ahb_haddr;
            else
                S_ahb_wr_addr <= S_ahb_wr_addr;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_wr_data <= 'd0;
        else
            if(S_ahb_wr_trig)
                S_ahb_wr_data <= I_ahb_hwdata;
            else
                S_ahb_wr_data <= S_ahb_wr_data;
    end
    //总线写寄存器
    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst) begin
            R_en                    <= 'd0;
            R_motor_polePair        <= 'd0;
            R_motor_dir             <= 'd0;
            R_encoder_sel           <= 'd0;
            R_encoder_dir           <= 'd0;
            R_control_mode          <= 'd0;
            R_current_id_aim        <= 'd0;
            R_current_iq_aim        <= 'd0;
            R_velocity_aim          <= 'd0;
            R_position_aim          <= 'd0;
            R_voltage_vd            <= 'd0;
            R_voltage_vq            <= 'd0;
            R_current_id_kp         <= 'd0;
            R_current_id_ki         <= 'd0;
            R_current_id_fg         <= 'd0;
            R_current_iq_kp         <= 'd0;
            R_current_iq_ki         <= 'd0;
            R_current_iq_fg         <= 'd0;
            R_velocity_kp           <= 'd0;
            R_velocity_ki           <= 'd0;
            R_velocity_fg           <= 'd0;
            R_position_kp           <= 'd0;
            R_position_ki           <= 'd0;
            R_position_fg           <= 'd0; 
        end else begin
            if(S_ahb_wr_trig_1d) begin
                case(S_ahb_wr_addr[31:0])
                    P_foc_addr_base + 16'h0000: R_en                    <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0004: R_motor_polePair        <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0008: R_motor_dir             <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h000C: R_encoder_sel           <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0010: R_encoder_dir           <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0100: R_control_mode          <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0104: R_current_id_aim        <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0108: R_current_iq_aim        <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h010C: R_velocity_aim          <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0110: R_position_aim          <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0114: R_voltage_vd            <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0118: R_voltage_vq            <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0200: R_current_id_kp         <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0204: R_current_id_ki         <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0208: R_current_id_fg         <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h020C: R_current_iq_kp         <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0210: R_current_iq_ki         <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0214: R_current_iq_fg         <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0218: R_velocity_kp           <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h021C: R_velocity_ki           <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0220: R_velocity_fg           <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0224: R_position_kp           <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h0228: R_position_ki           <= S_ahb_wr_data; 
                    P_foc_addr_base + 16'h022C: R_position_fg           <= S_ahb_wr_data; 
                endcase
            end else begin
                R_en                    <= R_en                    ;
                R_motor_polePair        <= R_motor_polePair        ;
                R_motor_dir             <= R_motor_dir             ;
                R_encoder_sel           <= R_encoder_sel           ;
                R_encoder_dir           <= R_encoder_dir           ;
                R_control_mode          <= R_control_mode          ;
                R_current_id_aim        <= R_current_id_aim        ;
                R_current_iq_aim        <= R_current_iq_aim        ;
                R_velocity_aim          <= R_velocity_aim          ;
                R_position_aim          <= R_position_aim          ;
                R_voltage_vd            <= R_voltage_vd            ;
                R_voltage_vq            <= R_voltage_vq            ;
                R_current_id_kp         <= R_current_id_kp         ;
                R_current_id_ki         <= R_current_id_ki         ;
                R_current_id_fg         <= R_current_id_fg         ;
                R_current_iq_kp         <= R_current_iq_kp         ;
                R_current_iq_ki         <= R_current_iq_ki         ;
                R_current_iq_fg         <= R_current_iq_fg         ;
                R_velocity_kp           <= R_velocity_kp           ;
                R_velocity_ki           <= R_velocity_ki           ;
                R_velocity_fg           <= R_velocity_fg           ;
                R_position_kp           <= R_position_kp           ;
                R_position_ki           <= R_position_ki           ;
                R_position_fg           <= R_position_fg           ;
            end
        end
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_rd_trig <= 1'b0;
        else
            if(I_ahb_htrans == 2'b10 && (!I_ahb_hwrite))
                S_ahb_rd_trig <= 1'b1;
            else
                S_ahb_rd_trig <= 1'b0;
    end

    always @(posedge I_ahb_clk) begin
        S_ahb_rd_trig_1d <= S_ahb_rd_trig;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_rd_addr <= 'd0;
        else
            if(S_ahb_rd_trig)
                S_ahb_rd_addr <= I_ahb_haddr;
            else
                S_ahb_rd_addr <= S_ahb_rd_addr;
    end
    //总线读寄存器
    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst) begin
            R_init_done             <= 'd0;
            R_current_id            <= 'd0;
            R_current_iq            <= 'd0;
            R_velocity              <= 'd0;
            R_position              <= 'd0;
            R_angle_ele             <= 'd0;
            R_angle_mec             <= 'd0;
            R_hall_step             <= 'd0;
            R_current_ia            <= 'd0;
            R_current_ib            <= 'd0;
            R_current_ic            <= 'd0;
            R_voltage_vr_rho        <= 'd0;
            R_voltage_vr_theta      <= 'd0;
            R_voltage_vs_rho        <= 'd0;
            R_voltage_vs_theta      <= 'd0;
            R_mid_current_id_aim    <= 'd0;
            R_mid_current_iq_aim    <= 'd0;
            R_mid_velocity_aim      <= 'd0; 
            R_mid_position_aim      <= 'd0; 
            R_mid_voltage_vd        <= 'd0;   
            R_mid_voltage_vq        <= 'd0;  
            R_angle_velocity        <= 'd0;  
            R_angle_position        <= 'd0; 
        end else begin
            R_init_done             <= S_init_done             ;
            R_current_id            <= S_current_id            ;
            R_current_iq            <= S_current_iq            ;
            R_velocity              <= S_velocity              ;
            R_position              <= S_position              ;
            R_angle_ele             <= S_angle_ele             ;
            R_angle_mec             <= S_angle_mec             ;
            R_hall_step             <= S_hall_step             ;
            R_current_ia            <= S_current_ia            ;
            R_current_ib            <= S_current_ib            ;
            R_current_ic            <= S_current_ic            ;
            R_voltage_vr_rho        <= S_voltage_vr_rho        ;
            R_voltage_vr_theta      <= S_voltage_vr_theta      ;
            R_voltage_vs_rho        <= S_voltage_vs_rho        ;
            R_voltage_vs_theta      <= S_voltage_vs_theta      ;
            R_mid_current_id_aim    <= S_mid_current_id_aim    ;
            R_mid_current_iq_aim    <= S_mid_current_iq_aim    ;
            R_mid_velocity_aim      <= S_mid_velocity_aim      ; 
            R_mid_position_aim      <= S_mid_position_aim      ; 
            R_mid_voltage_vd        <= S_mid_voltage_vd        ;   
            R_mid_voltage_vq        <= S_mid_voltage_vq        ;  
            R_angle_velocity        <= S_angle_velocity        ;  
            R_angle_position        <= S_angle_position    ;  
            if(S_ahb_rd_trig_1d)
                begin
                    case(S_ahb_rd_addr[31:0])
                        P_foc_addr_base + 16'h0000: O_ahb_hrdata  <= R_en                    ;
                        P_foc_addr_base + 16'h0004: O_ahb_hrdata  <= R_motor_polePair        ;
                        P_foc_addr_base + 16'h0008: O_ahb_hrdata  <= R_motor_dir             ;
                        P_foc_addr_base + 16'h000C: O_ahb_hrdata  <= R_encoder_sel           ;
                        P_foc_addr_base + 16'h0010: O_ahb_hrdata  <= R_encoder_dir           ;
                        P_foc_addr_base + 16'h0100: O_ahb_hrdata  <= R_control_mode          ;
                        P_foc_addr_base + 16'h0104: O_ahb_hrdata  <= R_current_id_aim        ;
                        P_foc_addr_base + 16'h0108: O_ahb_hrdata  <= R_current_iq_aim        ;
                        P_foc_addr_base + 16'h010C: O_ahb_hrdata  <= R_velocity_aim          ;
                        P_foc_addr_base + 16'h0110: O_ahb_hrdata  <= R_position_aim          ;
                        P_foc_addr_base + 16'h0114: O_ahb_hrdata  <= R_voltage_vd            ;
                        P_foc_addr_base + 16'h0118: O_ahb_hrdata  <= R_voltage_vq            ;
                        P_foc_addr_base + 16'h0200: O_ahb_hrdata  <= R_current_id_kp         ;
                        P_foc_addr_base + 16'h0204: O_ahb_hrdata  <= R_current_id_ki         ;
                        P_foc_addr_base + 16'h0208: O_ahb_hrdata  <= R_current_id_fg         ;
                        P_foc_addr_base + 16'h020C: O_ahb_hrdata  <= R_current_iq_kp         ;
                        P_foc_addr_base + 16'h0210: O_ahb_hrdata  <= R_current_iq_ki         ;
                        P_foc_addr_base + 16'h0214: O_ahb_hrdata  <= R_current_iq_fg         ;
                        P_foc_addr_base + 16'h0218: O_ahb_hrdata  <= R_velocity_kp           ;
                        P_foc_addr_base + 16'h021C: O_ahb_hrdata  <= R_velocity_ki           ;
                        P_foc_addr_base + 16'h0220: O_ahb_hrdata  <= R_velocity_fg           ;
                        P_foc_addr_base + 16'h0224: O_ahb_hrdata  <= R_position_kp           ;
                        P_foc_addr_base + 16'h0228: O_ahb_hrdata  <= R_position_ki           ;
                        P_foc_addr_base + 16'h022C: O_ahb_hrdata  <= R_position_fg           ;
                        P_foc_addr_base + 16'h0300: O_ahb_hrdata  <= R_init_done             ;
                        P_foc_addr_base + 16'h0304: O_ahb_hrdata  <= R_current_id            ;
                        P_foc_addr_base + 16'h0308: O_ahb_hrdata  <= R_current_iq            ;
                        P_foc_addr_base + 16'h030C: O_ahb_hrdata  <= R_velocity              ;
                        P_foc_addr_base + 16'h0310: O_ahb_hrdata  <= R_position              ;
                        P_foc_addr_base + 16'h0314: O_ahb_hrdata  <= R_angle_ele             ;
                        P_foc_addr_base + 16'h0318: O_ahb_hrdata  <= R_angle_mec             ;
                        P_foc_addr_base + 16'h031C: O_ahb_hrdata  <= R_hall_step             ;
                        P_foc_addr_base + 16'h0320: O_ahb_hrdata  <= R_current_ia            ;
                        P_foc_addr_base + 16'h0324: O_ahb_hrdata  <= R_current_ib            ;
                        P_foc_addr_base + 16'h0328: O_ahb_hrdata  <= R_current_ic            ;
                        P_foc_addr_base + 16'h032C: O_ahb_hrdata  <= R_voltage_vr_rho        ;
                        P_foc_addr_base + 16'h0330: O_ahb_hrdata  <= R_voltage_vr_theta      ;
                        P_foc_addr_base + 16'h0334: O_ahb_hrdata  <= R_voltage_vs_rho        ;
                        P_foc_addr_base + 16'h0338: O_ahb_hrdata  <= R_voltage_vs_theta      ;
                        P_foc_addr_base + 16'h033C: O_ahb_hrdata  <= R_mid_current_id_aim    ;
                        P_foc_addr_base + 16'h0340: O_ahb_hrdata  <= R_mid_current_iq_aim    ;
                        P_foc_addr_base + 16'h0344: O_ahb_hrdata  <= R_mid_velocity_aim      ;
                        P_foc_addr_base + 16'h0348: O_ahb_hrdata  <= R_mid_position_aim      ;
                        P_foc_addr_base + 16'h034C: O_ahb_hrdata  <= R_mid_voltage_vd        ;
                        P_foc_addr_base + 16'h0350: O_ahb_hrdata  <= R_mid_voltage_vq        ;
                        P_foc_addr_base + 16'h0354: O_ahb_hrdata  <= R_angle_velocity        ;
                        P_foc_addr_base + 16'h035C: O_ahb_hrdata  <= R_angle_position        ;
                    endcase
                end
            else
                O_ahb_hrdata <= O_ahb_hrdata;
        end
    end

foc_controller u_foc_controller (
    // 时钟和复位信号 
    .I_clk_40m          (I_clk_40m          ),      // PLL40MHZ输出
    .I_rst              (I_rst              ),      // 高有效复位信号
    // 3相 PWM 信号和使能信号
    .O_pwm_en           (O_pwm_en           ),      // 3相共用的使能信号，当 pwm_en=0 时，6个MOS管全部关断。
    .O_pwm_a            (O_pwm_a            ),      // A相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    .O_pwm_b            (O_pwm_b            ),      // B相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    .O_pwm_c            (O_pwm_c            ),      // C相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    // AD7928，用于相电流检测
    .O_spi_ss           (O_spi_ss           ),
    .O_spi_sck          (O_spi_sck          ),
    .O_spi_mosi         (O_spi_mosi         ),
    .I_spi_miso         (I_spi_miso         ),
    // AS5600 磁编码器
    .O_i2c_scl          (O_i2c_scl          ),
    .IO_i2c_sda         (IO_i2c_sda         ),
	// 霍尔编码器
    .I_hall_u           (I_hall_u           ),
    .I_hall_v           (I_hall_v           ),
    .I_hall_w           (I_hall_w           ),
    
    // 基础配置
    .I_en               (R_en                ),     // 输出使能信号
    .I_motor_polePair   (R_motor_polePair    ),     // 电机极对数
    .I_motor_dir        (R_motor_dir         ),     // 电机方向，0选择uvw顺序驱动电机逆时针转动，1选择uvw顺序驱动电机逆时针转动
    .I_encoder_sel      (R_encoder_sel       ),     // 选择编码器，0选择as5600磁编码器，1选择霍尔编码器
    .I_encoder_dir      (R_encoder_dir       ),     // 编码器方向，0选择角度增长方向与电机正转同向，1选择角度增长方向与电机正转逆向

    // 控制模式选择和目标量设置
    .I_control_mode      (R_control_mode     ),     // 闭环控制模式 0电流环 1速度环 2位置环 3开环
    .I_current_id_aim    (R_current_id_aim   ),     // 电流环转子d轴（直轴）的目标电流值
    .I_current_iq_aim    (R_current_iq_aim   ),     // 电流环转子q轴（交轴）的目标电流值
    .I_velocity_aim      (R_velocity_aim     ),     // 速度环目标转速
    .I_position_aim      (R_position_aim     ),     // 位置环目标角度
    .I_voltage_vd        (R_voltage_vd       ),     // 开环vd电压
    .I_voltage_vq        (R_voltage_vq       ),     // 开环vq电压
    // PI和前馈参数
    .I_current_id_kp     (R_current_id_kp    ),     // 电流环id PI控制器 Kp
    .I_current_id_ki     (R_current_id_ki    ),     // 电流环id PI控制器 Ki
    .I_current_id_fg     (R_current_id_fg    ),     // 电流环id 前馈控制器 Gain
    .I_current_iq_kp     (R_current_iq_kp    ),     // 电流环iq PI控制器 Kp
    .I_current_iq_ki     (R_current_iq_ki    ),     // 电流环iq PI控制器 Ki
    .I_current_iq_fg     (R_current_iq_fg    ),     // 电流环iq 前馈控制器 Gain
    .I_velocity_kp       (R_velocity_kp      ),     // 速度环 PI控制器 Kp
    .I_velocity_ki       (R_velocity_ki      ),     // 速度环 PI控制器 Ki
    .I_velocity_fg       (R_velocity_fg      ),     // 速度环 前馈控制器 Gain
    .I_position_kp       (R_position_kp      ),     // 位置环 PI控制器Kp
    .I_position_ki       (R_position_ki      ),     // 位置环 PI控制器 Ki
    .I_position_fg       (R_position_fg      ),     // 位置环 前馈控制器 Gain
    // 需要被读取的数据
    .O_init_done         (S_init_done        ),     // 初始化完成信号
    .O_current_id        (S_current_id       ),     // 当前转子d轴（直轴）的实际电流值
    .O_current_iq        (S_current_iq       ),     // 当前转子q轴（交轴）的实际电流值
    .O_velocity          (S_velocity         ),     // 当前速度量
    .O_position          (S_position         ),     // 当前位置量
    .O_angle_ele         (S_angle_ele        ),     // 转子电角度
    .O_angle_mec         (S_angle_mec        ),     // 转子机械角度
    .O_hall_step         (S_hall_step        ),     // 霍尔编码器所在区间
    .O_current_ia        (S_current_ia       ),     // A相电流值
    .O_current_ib        (S_current_ib       ),     // B相电流值
    .O_current_ic        (S_current_ic       ),     // C相电流值
    .O_voltage_vr_rho    (S_voltage_vr_rho   ),     // 转子极坐标系上的电压矢量的幅值
    .O_voltage_vr_theta  (S_voltage_vr_theta ),     // 转子极坐标系上的电压矢量的角度
    .O_voltage_vs_rho    (S_voltage_vs_rho   ),     // 定子极坐标系上的电压矢量的幅值
    .O_voltage_vs_theta  (S_voltage_vs_theta ),     // 定子极坐标系上的电压矢量的角度
	.S_current_id_aim	(S_mid_current_id_aim),      // 电流环转子d轴（直轴）的目标电流值
	.S_current_iq_aim	(S_mid_current_iq_aim),      // 电流环转子q轴（交轴）的目标电流值
	.S_velocity_aim		(S_mid_velocity_aim),        // 速度环目标转速
	.S_position_aim		(S_mid_position_aim),        // 位置环目标角度
	.S_voltage_vd		(S_mid_voltage_vd),          // 开环vd电压
	.S_voltage_vq		(S_mid_voltage_vq),          // 开环vq电压
	.O_angle_velocity   (S_angle_velocity),          // 机械角度转速
    .O_angle_position	(S_angle_position)
);


endmodule