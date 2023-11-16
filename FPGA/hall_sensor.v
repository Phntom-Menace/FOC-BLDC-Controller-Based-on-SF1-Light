module hall_encoder
(
    // 时钟和信号输入
    input  wire 		I_clk,		    // 40MHz 时钟输入
    input  wire 		I_rst,          // 复位输入，高有效

    // 运行参数输入
    input  wire         I_init_done,    // 初始化完成
    input  wire			I_insert_en,    // 使能霍尔编码器的插补平滑滤波算法
    input  wire  [5:0]  I_motor_polePair,       // 电机极对数
    input  wire			I_hall_dir,		// 霍尔编码器安装方向 0：霍尔uvw方向与电机uvw方向相同 1:霍尔uvw方向与电机uvw方向相反
    
    // 信号输入
    input  wire 		I_hall_u,       // U相霍尔编码器输入
    input  wire 		I_hall_v,       // V相霍尔编码器输入
    input  wire 		I_hall_w,       // W相霍尔编码器输入
    
    // 信号输出
    output reg  [11:0]	O_angle_ele,		// 电机转子的电角度
    output reg  [11:0]	O_angle_mec,		// 电机转子的机械角度
    output reg	        O_connect,		// 霍尔传感器正常连接 高有效
    
    // 中间信号输出
	output reg  [2:0]	S_hall_step		// 霍尔编码器所在区间
);

parameter FORWARD = 1'b0;               // 电机uvw方向
parameter BACKWARD = 1'b1;               // 电机wvu方向

reg   		S_dir_lock;		            // 当前转向成功锁定， 高有效
reg        	S_dir;				        // 当前电机旋转方向 0: 正向uvw  1: 逆向wvu
reg   [2:0] S_state;                    // 当前储存的霍尔状态
reg  [11:0] S_angle_unlock;             // 如果丢失转向，当前区间的中间角度
reg  [11:0] S_angle_base;               // 区间切换得到的基准角度
reg  [11:0] S_angle_bias;               // 在基准角度上的偏转角度
reg  [11:0] S_angle_ele_init;          // 初始角度

// 初始化完成后记录初始电角度
always @(posedge I_rst or posedge I_init_done) begin
    if(I_rst)
        S_angle_ele_init <= 'd0;
    else
        S_angle_ele_init <= O_angle_ele;
end

// 根据霍尔编码器输入确定转子所在区间
always @ (*) begin 
    if(I_hall_dir == FORWARD) begin
        // 霍尔编码器正向安装
        case({I_hall_w, I_hall_v, I_hall_u})
            3'b011:	S_hall_step = 3'd1;
            3'b001:	S_hall_step = 3'd2;
            3'b101:	S_hall_step = 3'd3;
            3'b100:	S_hall_step = 3'd4;
            3'b110:	S_hall_step = 3'd5;
            3'b010:	S_hall_step = 3'd6;
            default:	S_hall_step = 3'd0;
        endcase
    end else begin
        // 霍尔编码器逆向安装
        case({I_hall_w, I_hall_v, I_hall_u})
            3'b011:	S_hall_step = 3'd1;
            3'b001:	S_hall_step = 3'd6;
            3'b101:	S_hall_step = 3'd5;
            3'b100:	S_hall_step = 3'd4;
            3'b110:	S_hall_step = 3'd3;
            3'b010:	S_hall_step = 3'd2;
            default:	S_hall_step = 3'd0;
        endcase
    end
end

// 有限状态机实现霍尔信号区间的切换
always @(posedge I_clk or posedge I_rst) begin
    if(I_rst) begin
        S_state <= 3'd0;
        S_dir_lock <= 1'b0;
        O_connect <= 1'b0;
    end else begin
        S_state <= S_hall_step;
        case(S_state) 

            3'd1: begin
                case(S_hall_step)
                    3'd6: begin // BACKWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= BACKWARD;
                    end
                    3'd1: begin end
                    3'd2: begin // FORWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= FORWARD;
                    end
                    default: begin // disconnect
                        S_dir_lock <= 1'b0;
                        O_connect <= 1'b0;
                    end
                endcase
            end
        
            3'd2: begin
                case(S_hall_step)
                    3'd1: begin // BACKWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= BACKWARD;
                    end
                    3'd2: begin end
                    3'd3: begin // FORWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= FORWARD;
                    end
                    default: begin // disconnect
                        S_dir_lock <= 1'b0;
                        O_connect <= 1'b0;
                    end
                endcase
            end
        
            3'd3: begin
                case(S_hall_step)
                    3'd2: begin // BACKWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= BACKWARD;
                    end
                    3'd3: begin end
                    3'd4: begin // FORWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= FORWARD;
                    end
                    default: begin // disconnect
                        S_dir_lock <= 1'b0;
                        O_connect <= 1'b0;
                    end
                endcase
            end
        
            3'd4: begin
                case(S_hall_step)
                    3'd3: begin // BACKWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= BACKWARD;
                    end
                    3'd4: begin end
                    3'd5: begin // FORWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= FORWARD;
                    end
                    default: begin // disconnect
                        S_dir_lock <= 1'b0;
                        O_connect <= 1'b0;
                    end
                endcase
            end
        
            3'd5: begin
                case(S_hall_step)
                    3'd4: begin // BACKWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= BACKWARD;
                    end
                    3'd5: begin end
                    3'd6: begin // FORWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= FORWARD;
                    end
                    default: begin // disconnect
                        S_dir_lock <= 1'b0;
                        O_connect <= 1'b0;
                    end
                endcase
            end
        
            3'd6: begin
                case(S_hall_step)
                    3'd5: begin // BACKWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= BACKWARD;
                    end
                    3'd6: begin end
                    3'd1: begin // FORWARD
                        S_dir_lock <= 1'b1;
                        S_dir <= FORWARD;
                    end
                    default: begin // disconnect
                        S_dir_lock <= 1'b0;
                        O_connect <= 1'b0;
                    end
                endcase
            end

            default: begin
                case(S_hall_step)
                    3'd1: O_connect <= 1'b1;
                    3'd2: O_connect <= 1'b1;
                    3'd3: O_connect <= 1'b1;
                    3'd4: O_connect <= 1'b1;
                    3'd5: O_connect <= 1'b1;
                    3'd6: O_connect <= 1'b1;
                endcase
            end

        endcase
    end
end


// 在未能锁定转向时输出区间中间角度
always @(*) begin
    case(S_state)
        3'd1:   S_angle_unlock = 12'd0;
        3'd2:   S_angle_unlock = 12'd683;
        3'd3:   S_angle_unlock = 12'd1365;
        3'd4:   S_angle_unlock = 12'd2048;
        3'd5:   S_angle_unlock = 12'd2731;
        3'd6:   S_angle_unlock = 12'd3413;
        default:S_angle_unlock = 12'd0;
    endcase
end

// 在锁定转向后计算基准角度
always @(*) begin
    if(S_dir == FORWARD) begin
        case(S_state)
            3'd1:   S_angle_base = 12'd3754;
            3'd2:   S_angle_base = 12'd341;
            3'd3:   S_angle_base = 12'd1024;
            3'd4:   S_angle_base = 12'd1707;
            3'd5:   S_angle_base = 12'd2389;
            3'd6:   S_angle_base = 12'd3072;
            default:S_angle_base = 12'd0;
        endcase
    end else begin
        case(S_state)
            3'd1:   S_angle_base = 12'd341;
            3'd2:   S_angle_base = 12'd1024;
            3'd3:   S_angle_base = 12'd1707;
            3'd4:   S_angle_base = 12'd2389;
            3'd5:   S_angle_base = 12'd3072;
            3'd6:   S_angle_base = 12'd3754;
            default:S_angle_base = 12'd0;
        endcase
    end
end

// 根据是否丢失转向决定输出插补角度还是丢失角度
always @(posedge I_clk or posedge I_rst) 
    if(I_rst) begin
        O_angle_ele <= 'd0;
    end else begin
        if(S_dir_lock && I_insert_en) begin
            if(S_dir == FORWARD) begin
                O_angle_ele <= S_angle_base + S_angle_bias - S_angle_ele_init;
            end else begin
                O_angle_ele <= S_angle_base - S_angle_bias - S_angle_ele_init;
            end
        end else begin
            O_angle_ele <= S_angle_unlock - S_angle_ele_init;
        end
    end

// 电角度累积量计算
reg  [11:0] S_angle_ele_1d;
wire [17:0] S_angle_ele_sum;
reg  [ 5:0] S_angle_ele_cnt;

assign S_angle_ele_sum = S_angle_ele_cnt * 18'd4096 + O_angle_ele;

always @(posedge I_clk or posedge I_rst) begin
    if(I_rst) begin
        S_angle_ele_1d  <= 0;
        S_angle_ele_cnt <= 0;
    end else begin
        S_angle_ele_1d <= O_angle_ele;
        if (S_angle_ele_1d > 'd3071 && O_angle_ele < 'd1023) begin // Forward overflow
            if(S_angle_ele_cnt >= I_motor_polePair - 1)
                S_angle_ele_cnt <= 0;
            else
                S_angle_ele_cnt <= S_angle_ele_cnt + 1;
        end else if (S_angle_ele_1d < 'd1023 && O_angle_ele > 'd3071) begin // Backward overflow
            if(S_angle_ele_cnt == 0)
                S_angle_ele_cnt <= I_motor_polePair - 1;
            else
                S_angle_ele_cnt <= S_angle_ele_cnt - 1;
        end
    end 
end

reg  S_div_state;
reg  S_div_start;
wire S_div_done;
wire [17:0] S_div_quotient;

Divider u_divider
(
.clk          (I_clk),
.denominator  (I_motor_polePair),
.numerator    (S_angle_ele_sum),
.rst          (I_rst),
.start        (S_div_start),
.done         (S_div_done),
.quotient     (S_div_quotient),
.remainder    ()
);

always @(posedge I_clk or posedge I_rst) begin
    if (I_rst || I_init_done) begin
        O_angle_mec <= 0;
    end else begin
        if (S_div_done) begin
        O_angle_mec <= S_div_quotient[11:0];
        S_div_state <= 0;
        end
        if(~S_div_state) begin
            S_div_start <= 1;
            S_div_state <= 1;
        end else begin
            S_div_start <= 0;
        end
    end
end

reg  [31:0] S_cnt_step;
reg  [31:0] S_cnt_bias;
wire  [31:0] S_bias_period; // angle_bias每增加1需要的cnt周期数

wire  [31:0] S_filter_out;
reg  [31:0] S_filter_data [7:0];
reg  [7:0]  S_temp_i;
reg  [31:0] S_filter_sum;

assign S_filter_out = S_filter_sum >> 'd3; //右移3 等效为÷8
assign S_bias_period = (S_filter_out * 6) >> 12; //filter_ave÷682(60°)
// 计算插补角度
always @(posedge I_clk or posedge I_rst) begin
    if(I_rst) begin
        S_angle_bias <= 12'd0;
        S_filter_sum <= 'h00000000;
		for (S_temp_i=0; S_temp_i<8; S_temp_i=S_temp_i+1)
			S_filter_data[S_temp_i] <= 'h00000000;
    end else begin
        if(S_state != S_hall_step) begin // 霍尔区间发生了切换
            // 更新平滑滤波器
            S_filter_data[0] <= S_cnt_step;
            for (S_temp_i=0; S_temp_i<7; S_temp_i=S_temp_i+1)
				S_filter_data[S_temp_i+1] <= S_filter_data[S_temp_i];
            S_filter_sum <= S_filter_sum + S_cnt_step - S_filter_data[7]; //将最老的数据换为最新的输入数据
            // 归零
            S_angle_bias <= 0;
            S_cnt_step <= 0;
            S_cnt_bias <= 0;
        end else begin
            // cnt自加 更新angle_bias
            S_cnt_step <= S_cnt_step + 32'd1;
            if (S_cnt_bias >= S_bias_period) begin
                S_cnt_bias <= S_cnt_bias + 32'd1 - S_bias_period;
                if(S_angle_bias >= 12'd683) begin
                	S_angle_bias <= S_angle_bias;
                end else begin
                	S_angle_bias <= S_angle_bias + 12'd1;
                end
            end else begin
                S_cnt_bias <= S_cnt_bias + 32'd1;
            end
        end
    end
end


endmodule
