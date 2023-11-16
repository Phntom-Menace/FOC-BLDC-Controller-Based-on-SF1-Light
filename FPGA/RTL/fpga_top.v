/*
By: Wang Hengxin
2023.11.8
*/

module foc_controller (
    // ʱ�Ӻ͸�λ�ź� 
    input  wire         I_clk_40m,  // PLL40MHZ���
    input  wire         I_rst,      // ����Ч��λ�ź�
    // 3�� PWM �źź�ʹ���ź�
    output wire         O_pwm_en,   // 3�๲�õ�ʹ���źţ��� pwm_en=0 ʱ��6��MOS��ȫ���ضϡ�
    output wire         O_pwm_a,    // A��PWM�źš��� =0 ʱ�����ű۵�ͨ���� =1 ʱ�����ű۵�ͨ
    output wire         O_pwm_b,    // B��PWM�źš��� =0 ʱ�����ű۵�ͨ���� =1 ʱ�����ű۵�ͨ
    output wire         O_pwm_c,    // C��PWM�źš��� =0 ʱ�����ű۵�ͨ���� =1 ʱ�����ű۵�ͨ
    // AD7928��������������
    output wire         O_spi_ss,
    output wire         O_spi_sck,
    output wire         O_spi_mosi,
    input  wire         I_spi_miso,
    // AS5600 �ű�����
    output wire         O_i2c_scl,
    inout               IO_i2c_sda,
	// ����������
    input  wire         I_hall_u,
    input  wire         I_hall_v,
    input  wire         I_hall_w,
    
    // ��������
    input  wire         I_en,                   // ���ʹ���ź�
    input  wire  [5:0]  I_motor_polePair,       // ���������
    input  wire         I_motor_dir,            // �������ѡ��uvw˳�����������ʱ��ת����ѡ��uvw˳�����������ʱ��ת��
    input  wire         I_encoder_sel,          // ѡ���������ѡ��as5600�ű�������1ѡ�����������
    input  wire         I_encoder_dir,          // ����������0ѡ��Ƕ���������������תͬ��ѡ��Ƕ���������������ת����

    // ����ģʽѡ���Ŀ��������
    input  wire         [ 1:0]  I_control_mode,        // �ջ�����ģʽ 0������ 1�ٶȻ� 2λ�û� 3����
    input  wire signed  [15:0]  I_current_id_aim,      // ������ת��d�ᣨֱ�ᣩ��Ŀ������
    input  wire signed  [15:0]  I_current_iq_aim,      // ������ת��q�ᣨ���ᣩ��Ŀ������
    input  wire signed  [15:0]  I_velocity_aim,        // �ٶȻ�Ŀ��ת��
    input  wire signed  [15:0]  I_position_aim,        // λ�û�Ŀ��Ƕ�
    input  wire signed  [15:0]  I_voltage_vd,          // ����vd��ѹ
    input  wire signed  [15:0]  I_voltage_vq,          // ����vq��ѹ
    // PI��ǰ������
    input  wire signed  [31:0]  I_current_id_kp,       // ������id PI������ Kp
    input  wire signed  [31:0]  I_current_id_ki,       // ������id PI������ Ki
    input  wire signed  [31:0]  I_current_id_fg,       // ������id ǰ�������� Gain
    input  wire signed  [31:0]  I_current_iq_kp,       // ������iq PI������ Kp
    input  wire signed  [31:0]  I_current_iq_ki,       // ������iq PI������ Ki
    input  wire signed  [31:0]  I_current_iq_fg,       // ������iq ǰ�������� Gain
    input  wire signed  [31:0]  I_velocity_kp,         // �ٶȻ� PI������ Kp
    input  wire signed  [31:0]  I_velocity_ki,         // �ٶȻ� PI������ Ki
    input  wire signed  [31:0]  I_velocity_fg,         // �ٶȻ� ǰ�������� Gain
    input  wire signed  [31:0]  I_position_kp,         // λ�û� PI������Kp
    input  wire signed  [31:0]  I_position_ki,         // λ�û� PI������ Ki
    input  wire signed  [31:0]  I_position_fg,         // λ�û� ǰ�������� Gain
    // ��Ҫ����ȡ������
    output wire              	O_init_done,            // ��ʼ������ź�
    output wire signed  [15:0]	O_current_id,           // ��ǰת��d�ᣨֱ�ᣩ��ʵ�ʵ���ֵ
    output wire signed  [15:0]	O_current_iq,           // ��ǰת��q�ᣨ���ᣩ��ʵ�ʵ���ֵ
    output wire signed  [31:0]	O_velocity,             // ��ǰ�ٶ���
    output wire signed  [31:0]	O_position,             // ��ǰλ����
    output wire         [11:0]	O_angle_ele,            // ת�ӵ�Ƕ�
    output wire         [11:0]	O_angle_mec,            // ת�ӻ�е�Ƕ�
    output wire         [ 2:0]	O_hall_step,            // ������������������
    output wire signed  [15:0]	O_current_ia,           // A������
    output wire signed  [15:0]	O_current_ib,           // B������
    output wire signed  [15:0]	O_current_ic,           // C������
    output wire         [11:0]	O_voltage_vr_rho,       // ת�Ӽ�����ϵ�ϵĵ�ѹʸ���ķ�ֵ
    output wire         [11:0]	O_voltage_vr_theta,     // ת�Ӽ�����ϵ�ϵĵ�ѹʸ���ĽǶ�
    output wire         [11:0]	O_voltage_vs_rho,       // ���Ӽ�����ϵ�ϵĵ�ѹʸ���ķ�ֵ
    output wire         [11:0]	O_voltage_vs_theta,     // ���Ӽ�����ϵ�ϵĵ�ѹʸ���ĽǶ�
	output wire signed [15:0] S_current_id_aim,      	// ������ת��d�ᣨֱ�ᣩ��Ŀ������
	output wire signed [15:0] S_current_iq_aim,      	// ������ת��q�ᣨ���ᣩ��Ŀ������
	output wire signed [15:0] S_velocity_aim,        	// �ٶȻ�Ŀ��ת��
	output wire signed [15:0] S_position_aim,        	// λ�û�Ŀ��Ƕ�
	output wire signed [15:0] S_voltage_vd,          	// ����vd��ѹ
	output wire signed [15:0] S_voltage_vq,          	// ����vq��ѹ
	output wire signed [31:0] O_angle_velocity,         // ��е�Ƕ�ת��
    output wire signed [31:0] O_angle_position
);


wire    S_rstn;             // ����Ч��λ�ź�
assign  S_rstn = ~I_rst;

wire [11:0] S_hall_angle_ele;
wire [11:0] S_as5600_angle_ele;
assign O_angle_ele = I_encoder_sel ? S_hall_angle_ele : S_as5600_angle_ele; // ��Ƕ�ѡ��ʹ�û�������������AS5600�ű�����

wire [11:0] S_hall_angle_mec;
wire [11:0] S_as5600_angle_mec;
assign O_angle_mec = I_encoder_sel ? S_hall_angle_mec : S_as5600_angle_mec; // ��е�Ƕ�ѡ��ʹ�û�������������AS5600�ű�����

wire        S_adc_en;       // 3�����ADC ����ʱ�̿����źţ�����Ҫ����һ�β���ʱ��sn_adc �ź��ϲ���һ��ʱ�����ڵĸߵ�ƽ���壬ָʾADCӦ�ý��в����ˡ�
wire        S_adc_done;     // 3�����ADC ���������Ч�źţ�sn_adc �����ߵ�ƽ�����adc_ad7928 ģ�鿪ʼ����3���������ת����������en_adc �ź��ϲ���һ�����ڵĸߵ�ƽ���壬ͬʱ�� ADC ת�����������adc_value_a, adc_value_b, adc_value_c �ź��ϡ�
wire [11:0] S_adc_value_a;  // A �������� ADC ԭʼֵ
wire [11:0] S_adc_value_b;  // B �������� ADC ԭʼֵ
wire [11:0] S_adc_value_c;  // C �������� ADC ԭʼֵ

wire        S_pwm_en;   // 3�๲�õ�ʹ���ź��м�����


as5600_encoder u_as5600_encoder(
    .I_clk          (I_clk_40m          ),  // 40MHz ʱ���ź�����
    .I_rst          (I_rst              ),  // ��λ�ź�����
    .I_init_done    (O_init_done        ),  // ��ʼ������ź�����
    .I_motor_polePair(I_motor_polePair  ),  // ���������
    .I_as5600_dir   (I_encoder_dir      ),  // AS5600��������װ����
    .O_i2c_scl      (O_i2c_scl          ),  // ������AS5600��SCL
    .IO_i2c_sda     (IO_i2c_sda         ),  // ������AS5600��SDA
    .O_angle_ele    (S_as5600_angle_ele ),  // ��Ƕ����
    .O_angle_mec    (S_as5600_angle_mec )   // AS5600��ȡ���Ļ�е�Ƕ�
);

//hall_encoder u_hall_encoder(
//    // ʱ�Ӻ��ź�����
//    .I_clk          (I_clk_40m      ),	    // 40MHz ʱ������
//    .I_rst          (I_rst          ),      // ��λ���룬����Ч

//    // ���в�������
//    .I_init_done    (O_init_done    ),
//    .I_insert_en    (    ),      // ʹ�ܻ����������Ĳ岹ƽ���˲��㷨
//    .I_motor_polePair(I_motor_polePair),
//    .I_hall_dir     (I_encoder_dir  ),	    // ������������װ���� 0������uvw��������uvw������ͬ 1:����uvw��������uvw�����෴
    
//    // �ź�����
//    .I_hall_u       (I_hall_u       ),      // U���������������
//    .I_hall_v       (I_hall_v       ),      // V���������������
//    .I_hall_w       (I_hall_w       ),      // W���������������
    
//    // �ź����
//    .O_angle_ele    (S_hall_angle_ele),		// ���ת�ӵĵ�Ƕ�
//    .O_angle_mec    (S_hall_angle_mec),		// ���ת�ӵĻ�е�Ƕ�
//    .O_connect      (               ),		// ������������������ ����Ч
    
//    // �м��ź����
//	.S_hall_step    (O_hall_step    )		// ������������������
//);


// AD7928 ADC ��ȡ�������ڶ�ȡ3���������ֵ����������δ���κδ�����ADCԭʼֵ��
adc_ad7928 #(
    .CH_CNT       ( 3'd2           ), // �ò���ȡ2��ָʾ����ֻ��Ҫ CH0, CH1, CH2 ������ͨ���� ADC ֵ
    .CH0          ( 3'd1           ), // ָʾ CH0 ��Ӧ AD7928 �� ͨ��1����Ӳ���� A ��������ӵ�AD7928 �� ͨ��1��
    .CH1          ( 3'd2           ), // ָʾ CH1 ��Ӧ AD7928 �� ͨ��2����Ӳ���� B ��������ӵ�AD7928 �� ͨ��2��
    .CH2          ( 3'd3           )  // ָʾ CH2 ��Ӧ AD7928 �� ͨ��3����Ӳ���� C ��������ӵ�AD7928 �� ͨ��3��
) u_adc_ad7928 (
    .rstn         ( S_rstn         ),
    .clk          ( I_clk_40m      ),
    .spi_ss       ( O_spi_ss       ), // SPI �ӿڣ�SS
    .spi_sck      ( O_spi_sck      ), // SPI �ӿڣ�SCK
    .spi_mosi     ( O_spi_mosi     ), // SPI �ӿڣ�MOSI
    .spi_miso     ( I_spi_miso     ), // SPI �ӿڣ�MISO
    .i_sn_adc     ( S_adc_en       ), // input : �� sn_adc ���ָߵ�ƽ����ʱ����ģ�鿪ʼ����һ�Σ�3·�ģ�ADC ת��
    .o_en_adc     ( S_adc_done     ), // output: ��ת��������en_adc ����һ�����ڵĸߵ�ƽ����
    .o_adc_value0 ( S_adc_value_a  ), // �� en_adc ����һ�����ڵĸߵ�ƽ�����ͬʱ��adc_value_a �ϳ��� A �������ADC ԭʼֵ
    .o_adc_value1 ( S_adc_value_b  ), // �� en_adc ����һ�����ڵĸߵ�ƽ�����ͬʱ��adc_value_b �ϳ��� B �������ADC ԭʼֵ
    .o_adc_value2 ( S_adc_value_c  ), // �� en_adc ����һ�����ڵĸߵ�ƽ�����ͬʱ��adc_value_c �ϳ��� C �������ADC ԭʼֵ
    .o_adc_value3 (                ), // �������� 5 · ADC ת�����
    .o_adc_value4 (                ), // �������� 5 · ADC ת�����
    .o_adc_value5 (                ), // �������� 5 · ADC ת�����
    .o_adc_value6 (                ), // �������� 5 · ADC ת�����
    .o_adc_value7 (                )  // �������� 5 · ADC ת�����
);



// FOC + SVPWM ģ�� ��ʹ�÷�����ԭ�����foc_top.sv��
foc_top #(
    .INIT_CYCLES  ( 20000000       ), // CLKΪ40MHz�����ʼ��ʱ���20/40=0.5s
    .MAX_AMP      ( 9'd384         ), // 384 / 512 = 0.75��˵�� SVPWM �������� ռ ���������޵� 75%
    .SAMPLE_DELAY ( 9'd120         )  // ������ʱ��ȡֵ��Χ0~511�����ǵ�3�������MOS �ܴӿ�ʼ��ͨ�������ȶ���Ҫһ����ʱ�䣬���Դ�3�����ű۶���ͨ���� ADC ����ʱ��֮����Ҫһ������ʱ���ò��������˸���ʱ�Ƕ��ٸ�ʱ�����ڣ�����ʱ����ʱ����ģ���� sn_adc �ź��ϲ���һ���ߵ�ƽ���壬ָʾ�ⲿ ADC "���Բ�����"
) u_foc_top (
    .rstn         ( S_rstn         ),
    .clk          ( I_clk_40m      ),
    .I_motor_polePair(I_motor_polePair),   
    .I_motor_dir(I_motor_dir),  
    .I_control_mode(I_control_mode),     
    .I_current_id_aim(I_current_id_aim),   
    .I_current_iq_aim(I_current_iq_aim),   
    .I_velocity_aim(I_velocity_aim),     
    .I_position_aim(I_position_aim),     
    .I_voltage_vd(I_voltage_vd),       
    .I_voltage_vq(I_voltage_vq),       
    .I_current_id_kp(I_current_id_kp),    
    .I_current_id_ki(I_current_id_ki),    
    .I_current_id_fg(I_current_id_fg),    
    .I_current_iq_kp(I_current_iq_kp),    
    .I_current_iq_ki(I_current_iq_ki),    
    .I_current_iq_fg(I_current_iq_fg),    
    .I_velocity_kp(I_velocity_kp),      
    .I_velocity_ki(I_velocity_ki),      
    .I_velocity_fg(I_velocity_fg),      
    .I_position_kp(I_position_kp),      
    .I_position_ki(I_position_ki),      
    .I_position_fg(I_position_fg),      
    .I_angle_ele          ( O_angle_ele), // input : �Ƕȴ��������루��е�Ƕȣ����Ϊ�գ���ȡֵ���~4095��0��Ӧ0�㣻1024��Ӧ90�㣻2048��Ӧ180�㣻3072��Ӧ270�㡣
    .sn_adc       ( S_adc_en       ), // output: 3�����ADC ����ʱ�̿����źţ�����Ҫ����һ�β���ʱ��sn_adc �ź��ϲ���һ��ʱ�����ڵĸߵ�ƽ���壬ָʾADCӦ�ý��в����ˡ�
    .en_adc       ( S_adc_done     ), // input : 3�����ADC ���������Ч�źţ�sn_adc �����ߵ�ƽ������ⲿADC��ʼ����3���������ת��������Ӧ��en_adc �ź��ϲ���һ�����ڵĸߵ�ƽ���壬ͬʱ��ADCת�����������adc_a, adc_b, adc_c �ź���
    .adc_a        ( S_adc_value_a  ), // input : A �� ADC �������
    .adc_b        ( S_adc_value_b  ), // input : B �� ADC �������
    .adc_c        ( S_adc_value_c  ), // input : C �� ADC �������
    .O_pwm_en       ( S_pwm_en       ),
    .O_pwm_a        ( O_pwm_a        ),
    .O_pwm_b        ( O_pwm_b        ),
    .O_pwm_c        ( O_pwm_c        ),
    .en_idq       (    ), // output: ���ָߵ�ƽ����ʱ˵�� id �� iq ��������ֵ��ÿ���������� en_idq �����һ���ߵ�ƽ����
    .O_current_id           ( O_current_id           ), // output: d �ᣨֱ�ᣩ��ʵ�ʵ���ֵ�������ɸ�
    .O_current_iq           ( O_current_iq           ), // output: q �ᣨ���ᣩ��ʵ�ʵ���ֵ�������ɸ�������������ʱ�룬�򸺴���˳ʱ�룬��֮��Ȼ��       
    .O_current_ia(O_current_ia),       
    .O_current_ib(O_current_ib),       
    .O_current_ic(O_current_ic),
    .O_init_done(O_init_done),
    .O_velocity(O_velocity),         
    .O_position(O_position),         
    .O_voltage_vr_rho(O_voltage_vr_rho),   
    .O_voltage_vr_theta(O_voltage_vr_theta) ,
    .O_voltage_vs_rho(O_voltage_vs_rho),   
    .O_voltage_vs_theta (O_voltage_vs_theta), 
	.S_current_id_aim(S_current_id_aim),      // ������ת��d�ᣨֱ�ᣩ��Ŀ������
	.S_current_iq_aim(S_current_iq_aim),      // ������ת��q�ᣨ���ᣩ��Ŀ������
	.S_velocity_aim(S_velocity_aim),        // �ٶȻ�Ŀ��ת��
	.S_position_aim(S_position_aim),        // λ�û�Ŀ��Ƕ�
	.S_voltage_vd(S_voltage_vd),          // ����vd��ѹ
	.S_voltage_vq(S_voltage_vq)          // ����vq��ѹ
);

assign O_pwm_en = I_en ? S_pwm_en : 0;

// 400 ��Ƶ I_clk_40m 100k
parameter [15:0] S_angle_position_clkdiv = 'd199;
reg  [15:0] S_angle_position_clkcnt;
reg         S_angle_position_clk;
always @(posedge I_clk_40m or posedge I_rst) begin
    if(I_rst) begin
        S_angle_position_clkcnt <= 'd0;
        S_angle_position_clk <= 'd0;
    end else begin
        if (S_angle_position_clkcnt < S_angle_position_clkdiv) begin
            S_angle_position_clkcnt <= S_angle_position_clkcnt + 1;
        end else begin
            S_angle_position_clkcnt <= 0;
            S_angle_position_clk <= ~S_angle_position_clk;
        end
    end
end


// λ�ü���
reg signed [11:0] S_angle_mec_cnt;
reg  signed [11:0] S_angle_mec_1d;

always @(posedge S_angle_position_clk or posedge I_rst) begin
    if(I_rst) begin
        S_angle_mec_1d <= 0;
		S_angle_mec_cnt <= 0;
    end else begin
//    	if(O_angle_mec != S_angle_mec_1d) begin
        	if(O_angle_mec < 'd1024 && S_angle_mec_1d > 'd3072 ) begin
//        	    S_angle_velocity_din <= $signed({4'h0, O_angle_mec}) - $signed({4'h0, S_angle_mec_1d}) + 16'd4096;
        	    S_angle_mec_cnt <= S_angle_mec_cnt + 1;
        	end else if(O_angle_mec > 'd3072 && S_angle_mec_1d < 'd1024 ) begin
//        	    S_angle_velocity_din <= $signed({4'h0, O_angle_mec}) - $signed({4'h0, S_angle_mec_1d}) - 16'd4096;
        	    S_angle_mec_cnt <= S_angle_mec_cnt - 1;
        	end else begin
//        		S_angle_velocity_din <= $signed({4'h0, O_angle_mec}) - $signed({4'h0, S_angle_mec_1d});
        	    S_angle_mec_cnt <= S_angle_mec_cnt;
        	end
        	S_angle_mec_1d <= O_angle_mec;
//		end
    end
end

assign O_angle_position = $signed({S_angle_mec_cnt, 12'h0} + O_angle_mec);


// 100 ��Ƶ I_clk_40m 1k
parameter [15:0] S_angle_velocity_clkdiv = 'd19999;
reg  [15:0] S_angle_velocity_clkcnt;
reg         S_angle_velocity_clk;
always @(posedge I_clk_40m or posedge I_rst) begin
    if(I_rst) begin
        S_angle_velocity_clkcnt <= 'd0;
        S_angle_velocity_clk <= 'd0;
    end else begin
        if (S_angle_velocity_clkcnt < S_angle_velocity_clkdiv) begin
            S_angle_velocity_clkcnt <= S_angle_velocity_clkcnt + 1;
        end else begin
            S_angle_velocity_clkcnt <= 0;
            S_angle_velocity_clk <= ~S_angle_velocity_clk;
        end
    end
end

// �ٶȼ���

localparam  filter_num = 4;
reg  signed [31:0] S_angle_velocity_filter [filter_num-1:0];
//reg  signed [15:0] S_angle_velocity_din;
reg   [7:0]  S_temp_i;
reg  signed [31:0] S_angle_velocity_sum;

reg signed [31:0] S_angle_position_1d;

always @(posedge S_angle_velocity_clk or posedge I_rst) begin
    if(I_rst) begin
        S_angle_position_1d <= 0;
//        S_angle_velocity_din <= 0;
		for (S_temp_i=0; S_temp_i<filter_num-1; S_temp_i=S_temp_i+1)
			S_angle_velocity_filter[S_temp_i] <= 'h0;
    end else begin
        // O_angle_velocity <= O_angle_position - S_angle_position_1d;
        S_angle_position_1d <= O_angle_position;
       	S_angle_velocity_filter[0] <= O_angle_position - S_angle_position_1d;
       	for (S_temp_i=0; S_temp_i<filter_num-1; S_temp_i=S_temp_i+1)
       	    S_angle_velocity_filter[S_temp_i+1] <= S_angle_velocity_filter[S_temp_i];
       	S_angle_velocity_sum <= S_angle_velocity_sum + O_angle_position - S_angle_position_1d - S_angle_velocity_filter[filter_num-1]; //�����ϵ����ݻ�Ϊ���µ���������
    end
end

assign O_angle_velocity = {S_angle_velocity_sum[31], S_angle_velocity_sum[31], S_angle_velocity_sum[31:2]};
//assign O_angle_velocity = O_angle_position - S_angle_position_1d;
// assign O_angle_velocity = S_angle_velocity_din;
//assign O_angle_position = O_angle_mec;

endmodule
