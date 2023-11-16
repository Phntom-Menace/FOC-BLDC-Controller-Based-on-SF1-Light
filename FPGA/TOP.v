module fpga_top(
    // 时钟和复位接口
    input wire        I_clk_25m,
    input wire        I_rstn,

    // MCU调试接口
    input wire        I_jtag_tck,
    output wire       O_jtag_tdo,
    input wire        I_jtag_tms,
    input wire        I_jtag_tdi,

    // UART接口
    input wire        I_uart_rx,
    output wire       O_uart_tx,

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
	wire    S_sys_clk_100m;
	wire    S_sys_clk_40m;
	wire    S_rst;
	assign 	S_rst = ~I_rstn;
    
    pll u_pll(
        .refclk   ( I_clk_25m      ),
        .reset    ( S_rst          ),
        .clk0_out ( S_sys_clk_100m ),
        .clk1_out ( S_sys_clk_40m )
    );

	// AHB接口连线
    wire[1:0]  S_ahb_htrans_master;      
    wire       S_ahb_hwrite_master;      
    wire[31:0] S_ahb_haddr_master;       
    wire[2:0]  S_ahb_hsize_master;       
    wire[2:0]  S_ahb_hburst_master;      
    wire[3:0]  S_ahb_hprot_master;       
    wire       S_ahb_hmastlock_master;   
    wire[31:0] S_ahb_hwdata_master;      
    wire[31:0] S_ahb_hrdata_master;      
    wire[1:0]  S_ahb_hresp_master;       
    wire       S_ahb_hready_master;   

	MCU u_mcu(
    	.core_clk         ( S_sys_clk_100m ),
		.timer_clk        ( I_clk_25m ), 
        .core_reset       ( S_rst       ),

        .jtag_tck         ( I_jtag_tck  ),
        .jtag_tdo         ( O_jtag_tdo  ),
        .jtag_tms         ( I_jtag_tms  ),
        .jtag_tdi         ( I_jtag_tdi  ),

        .uart_tx          ( O_uart_tx  ),
        .uart_rx          ( I_uart_rx  ),
        
        .htrans           (S_ahb_htrans_master     ),
        .hwrite           (S_ahb_hwrite_master     ),
        .haddr            (S_ahb_haddr_master      ),
        .hsize            (S_ahb_hsize_master      ),
        .hburst           (S_ahb_hburst_master     ),
        .hprot            (S_ahb_hprot_master      ),
        .hmastlock        (S_ahb_hmastlock_master  ),
        .hwdata           (S_ahb_hwdata_master     ),
        .hclk             (S_sys_clk_100m 		   ),      //AHB时钟选择系统时钟100MHz
        .hrdata           (S_ahb_hrdata_master     ),
        .hresp            (S_ahb_hresp_master      ),
        .hready           (S_ahb_hready_master     ),

        .nmi              (  ),
        .clic_irq         (  ),
        .sysrstreq        (  ),
        .apb_clk_down     (  ),
        .apb_paddr_down   (  ),
        .apb_penable_down (  ),
        .apb_pprot_down   (  ),
        .apb_prdata_down  (  ),
        .apb_pready_down  (  ),
        .apb_pslverr_down (  ),
        .apb_pstrobe_down (  ),
        .apb_pwdata_down  (  ),
        .apb_pwrite_down  (  ),
        .apb_psel0_down   (  ),
        .apb_psel1_down   (  ),
        .apb_psel2_down   (  )
	);
    
	ahb_foc_controller u_ahb_foc_controller (
    // AHB时钟和复位信号
    .I_ahb_clk          (S_sys_clk_100m),
    .I_rst              (S_rst),
    // AHB总线
    .I_ahb_htrans       (S_ahb_htrans_master    ),
    .I_ahb_hwrite       (S_ahb_hwrite_master    ),
    .I_ahb_haddr        (S_ahb_haddr_master     ),       //synthesis keep
    .I_ahb_hsize        (S_ahb_hsize_master     ),
    .I_ahb_hburst       (S_ahb_hburst_master    ),
    .I_ahb_hprot        (S_ahb_hprot_master     ),
    .I_ahb_hmastlock    (S_ahb_hmastlock_master ),
    .I_ahb_hwdata       (S_ahb_hwdata_master    ),      //synthesis keep
    .O_ahb_hrdata       (S_ahb_hrdata_master    ),      //synthesis keep
    .O_ahb_hresp        (S_ahb_hresp_master     ),
    .O_ahb_hready       (S_ahb_hready_master     ),
    
    // PLL 40MHz时钟输入
    .I_clk_40m          (S_sys_clk_40m          ),
    // 3相 PWM 信号和使能信号
    .O_pwm_en           (O_pwm_en               ), 
    .O_pwm_a            (O_pwm_a                ),    
    .O_pwm_b            (O_pwm_b                ),    
    .O_pwm_c            (O_pwm_c                ),    
    // AD7928，用于相电流检测
    .O_spi_ss           (O_spi_ss               ),
    .O_spi_sck          (O_spi_sck              ),
    .O_spi_mosi         (O_spi_mosi             ),
    .I_spi_miso         (I_spi_miso             ),
    // AS5600 磁编码器
    .O_i2c_scl          (O_i2c_scl              ),
    .IO_i2c_sda         (IO_i2c_sda             ),
	// 霍尔编码器
    .I_hall_u           (I_hall_u               ),
    .I_hall_v           (I_hall_v               ),
    .I_hall_w           (I_hall_w               )
);

endmodule
