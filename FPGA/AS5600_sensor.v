module as5600_encoder( 
    input  wire         I_clk,              // 40MHz 时钟信号输入
    input  wire         I_rst,              // 复位信号输入
    input  wire         I_init_done,        // 初始化完成信号输入

    input  wire  [5:0]  I_motor_polePair,   // 电机极对数
    input  wire			I_as5600_dir,		// AS5600编码器安装方向
                                            // 0：角度增加方向与电机uvw方向相同 1：角度增加方向与电机uvw方向相反

    output wire         O_i2c_scl,          // 连接至AS5600的SCL
    inout  wire         IO_i2c_sda,         // 连接至AS5600的SDA

    output reg  [11:0]  O_angle_ele,            // 电角度输出

    output wire [11:0]  O_angle_mec         // AS5600读取到的机械角度
);

parameter FORWARD = 1'b0;   // 电机uvw方向
parameter BACKWARD = 1'b1;  // 电机wvu方向

reg  [11:0]  O_angle_mec_init;    // 初始化完成时的初始机械角度


always @(posedge I_init_done) begin
    O_angle_mec_init <= O_angle_mec;
end

always @(*) begin
    if(I_as5600_dir == FORWARD) begin
        O_angle_ele = {4'h0, I_motor_polePair} * (O_angle_mec - O_angle_mec_init);
    end else begin
        O_angle_ele = {4'h0, I_motor_polePair} * (O_angle_mec_init - O_angle_mec);
    end
end

//// 简易 I2C 读取控制器，实现 AS5600 磁编码器读取，读出当前转子机械角度
wire [3:0] S_i2c_trash;    // 丢弃的高4位
i2c_register_read #(
   .CLK_DIV      ( 16'd10           ),  // i2c_scl 时钟信号分频系数，scl频率 = clk频率 / (4*CLK_DIV)
                                        //AS5600 芯片要求 SCL 频率不超过 1MHz
   .SLAVE_ADDR   ( 7'h36            ),  // AS5600 地址
   .REGISTER_ADDR( 8'h0E            )   // the register address to read
) u_as5600_read (
   .rstn         ( ~I_rst           ),
   .clk          ( I_clk            ),
   .scl          ( O_i2c_scl        ),  // I2C 接口： SCL
   .sda          ( IO_i2c_sda       ),  // I2C 接口： SDA
   .start        ( 1'b1             ),  // 持续进行 I2C 读操作
   .ready        (                  ),
   .done         (                  ),
   .regout       ( {S_i2c_trash, O_angle_mec} )
);
endmodule
