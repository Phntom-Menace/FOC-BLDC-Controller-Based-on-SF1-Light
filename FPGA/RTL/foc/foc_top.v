module foc_top #(
    // ----------------------------------------------- ģ����� ---------------------------------------------------------------------------------------------------------------------------------------------------
    parameter        INIT_CYCLES  = 16777216,       // �����˳�ʼ������ռ���ٸ�ʱ��(clk)���ڣ�ȡֵ��ΧΪ1~4294967294����ֵ����̫�̣���ΪҪ���㹻��ʱ����ת�ӻع��Ƕ�=0��������ʱ��(clk)Ƶ��Ϊ 36.864MHz��INIT_CYCLES=16777216�����ʼ��ʱ��Ϊ 16777216/36864000=0.45 ��
    parameter [ 8:0] MAX_AMP      = 9'd255,         // SVPWM ����������ȡֵ��ΧΪ1~511����ֵԽС������ܴﵽ���������ԽС�������ǵ�ʹ��3�����ű۵����������������������ֵҲ����̫���Ա�֤3�����ű����㹻�ĳ�����ͨʱ������ADC���в�����
    parameter [ 8:0] SAMPLE_DELAY = 9'd150          // ������ʱ��ȡֵ��Χ0~511�����ǵ�3������� MOS �ܴӿ�ʼ��ͨ�������ȶ���Ҫһ����ʱ�䣬���Դ�3�����ű۶���ͨ���� ADC ����ʱ��֮����Ҫһ������ʱ���ò��������˸���ʱ�Ƕ��ٸ�ʱ�����ڣ�����ʱ����ʱ����ģ���� sn_adc �ź��ϲ���һ���ߵ�ƽ���壬ָʾ�ⲿ ADC "���Բ�����"
) (
    // ----------------------------------------------- ����ʱ�Ӻ͸�λ ---------------------------------------------------------------------------------------------------------------------------------------------
    input  wire               rstn,                 // ��λ�źţ�Ӧ������������ģ����и�λ��Ȼ��һֱ���ָߵ�ƽ����ģ������������
    input  wire               clk,                  // ʱ���źţ�Ƶ�ʿ�ȡ��ʮMHz������Ƶ�� = ʱ��Ƶ�� / 2048��������ʱ��Ƶ��Ϊ 36.864MHz ����ô����Ƶ��Ϊ 36.864MHz/2048=18kHz��������Ƶ�� = 3����������Ĳ����� = PID�㷨�Ŀ���Ƶ�� = SVPWMռ�ձȵĸ���Ƶ�ʣ�
    // ----------------------------------------------- PI ���� ----------------------------------------------------------------------------------------------------------------------------------------------------
    
    input  wire          [5:0]  I_motor_polePair,    // ���������
    input  wire                 I_motor_dir,                // �������0ѡ��uvw˳�����������ʱ��ת����1ѡ��uvw˳�����������ʱ��ת��
    
    // ����ģʽѡ���Ŀ��������
    input  wire         [ 1:0]  I_control_mode,        // �ջ�����ģʽ 0������ 1�ٶȻ� 2λ�û� 3����
    input  wire signed  [15:0]  I_current_id_aim,      // ������ת��d�ᣨֱ�ᣩ��Ŀ�����ֵ
    input  wire signed  [15:0]  I_current_iq_aim,      // ������ת��q�ᣨ���ᣩ��Ŀ�����ֵ
    input  wire signed  [15:0]  I_velocity_aim,        // �ٶȻ�Ŀ��ת��
    input  wire signed  [15:0]  I_position_aim,        // λ�û�Ŀ��Ƕ�
    input  wire signed  [15:0]  I_voltage_vd,          // ����vd��ѹ
    input  wire signed  [15:0]  I_voltage_vq,          // ����vq��ѹ
    // PI��ǰ������
    input  wire signed  [15:0]  I_current_id_kp,       // ������id PI������ Kp
    input  wire signed  [15:0]  I_current_id_ki,       // ������id PI������ Ki
    input  wire signed  [15:0]  I_current_id_fg,       // ������id ǰ�������� Gain
    input  wire signed  [15:0]  I_current_iq_kp,       // ������iq PI������ Kp
    input  wire signed  [15:0]  I_current_iq_ki,       // ������iq PI������ Ki
    input  wire signed  [15:0]  I_current_iq_fg,       // ������iq ǰ�������� Gain
    input  wire signed  [15:0]  I_velocity_kp,         // �ٶȻ� PI������ Kp
    input  wire signed  [15:0]  I_velocity_ki,         // �ٶȻ� PI������ Ki
    input  wire signed  [15:0]  I_velocity_fg,         // �ٶȻ� ǰ�������� Gain
    input  wire signed  [15:0]  I_position_kp,         // λ�û� PI������Kp
    input  wire signed  [15:0]  I_position_ki,         // λ�û� PI������ Ki
    input  wire signed  [15:0]  I_position_fg,         // λ�û� ǰ�������� Gain


    
    // ----------------------------------------------- �Ƕȴ����������ź� -----------------------------------------------------------------------------------------------------------------------------------------
    input  wire         [11:0]  I_angle_ele,                  // ��Ƕ����룬ȡֵ��Χ0~4095��0��Ӧ0�㣻1024��Ӧ90�㣻2048��Ӧ180�㣻3072��Ӧ270�㡣
    // ----------------------------------------------- 3����� ADC ����ʱ�̿����ź� �Ͳ�����������ź� ------------------------------------------------------------------------------------------------------------
    output wire                 sn_adc,               // 3����� ADC ����ʱ�̿����źţ�����Ҫ����һ�β���ʱ��sn_adc �ź��ϲ���һ��ʱ�����ڵĸߵ�ƽ���壬ָʾADCӦ�ý��в����ˡ�
    input  wire                 en_adc,               // 3����� ADC ���������Ч�źţ�sn_adc �����ߵ�ƽ������ⲿADC��ʼ����3���������ת��������Ӧ�� en_adc �ź��ϲ���һ�����ڵĸߵ�ƽ���壬ͬʱ��ADCת����������� adc_a, adc_b, adc_c �ź���
    input  wire         [11:0]  adc_a, adc_b, adc_c,  // 3����� ADC ������������ΪADCa, ADCb, ADCc����ȡֵ��Χ0 ~ 4095
    // ----------------------------------------------- 3�� PWM �źţ�������ʹ���źţ� -----------------------------------------------------------------------------------------------------------------------------
    output wire                 O_pwm_en,               // 3�๲�õ�ʹ���źţ��� pwm_en=0 ʱ��6��MOS��ȫ���ضϡ�
    output wire                 O_pwm_a,                // A��PWM�źš��� =0 ʱ�����ű۵�ͨ���� =1 ʱ�����ű۵�ͨ
    output wire                 O_pwm_b,                // B��PWM�źš��� =0 ʱ�����ű۵�ͨ���� =1 ʱ�����ű۵�ͨ
    output wire                 O_pwm_c,                // C��PWM�źš��� =0 ʱ�����ű۵�ͨ���� =1 ʱ�����ű۵�ͨ
    // ----------------------------------------------- d/q�ᣨת��ֱ������ϵ���ĵ������ --------------------------------------------------------------------------------------------------------------------------
    output wire                 en_idq,               // ���ָߵ�ƽ����ʱ˵�� id �� iq ��������ֵ��ÿ���������� en_idq �����һ���ߵ�ƽ����
    output wire signed  [15:0]  O_current_id,                   // d �ᣨֱ�ᣩ��ʵ�ʵ���ֵ�����Ϊ Id���������ɸ�
    output wire signed  [15:0]  O_current_iq,                   // q �ᣨ���ᣩ��ʵ�ʵ���ֵ�����Ϊ Iq���������ɸ�������������ʱ�룬�򸺴���˳ʱ�룬��֮��Ȼ��
    output reg  signed  [15:0]	O_current_ia,           // A�����ֵ
    output reg  signed  [15:0]	O_current_ib,           // B�����ֵ
    output reg  signed  [15:0]	O_current_ic,           // C�����ֵ
   // ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    output reg                  O_init_done,             // ��ʼ�������źš��ڳ�ʼ������ǰ=0���ڳ�ʼ�������󣨽���FOC����״̬��=1
    
    output wire signed  [15:0]	O_velocity,             // ��ǰ�ٶ���
    output wire signed  [15:0]	O_position,             // ��ǰλ����
    output wire         [11:0]	O_voltage_vr_rho,       // ת�Ӽ�����ϵ�ϵĵ�ѹʸ���ķ�ֵ
    output wire         [11:0]	O_voltage_vr_theta,     // ת�Ӽ�����ϵ�ϵĵ�ѹʸ���ĽǶ�
    output reg          [11:0]	O_voltage_vs_rho,       // ���Ӽ�����ϵ�ϵĵ�ѹʸ���ķ�ֵ
    output reg          [11:0]	O_voltage_vs_theta,      // ���Ӽ�����ϵ�ϵĵ�ѹʸ���ĽǶ�
	output wire signed [15:0] S_current_id_aim,      // ������ת��d�ᣨֱ�ᣩ��Ŀ�����ֵ
	output wire signed [15:0] S_current_iq_aim,      // ������ת��q�ᣨ���ᣩ��Ŀ�����ֵ
	output wire signed [15:0] S_velocity_aim,        // �ٶȻ�Ŀ��ת��
	output wire signed [15:0] S_position_aim,        // λ�û�Ŀ��Ƕ�
	output wire signed [15:0] S_voltage_vd,          // ����vd��ѹ
	output wire signed [15:0] S_voltage_vq          // ����vq��ѹ

);










reg         [31:0] init_cnt;
//reg         [11:0] init_phi;      // ��ʼ��е�Ƕȣ����Ϊ ����������Ƕ�=0ʱ��Ӧ�Ļ�е�Ƕȣ��ڳ�ʼ������ʱ��ȷ����������֮����л�е�Ƕȵ���Ƕȵ�ת����ȡֵ��Χ0~4095��0��Ӧ0�㣻1024��Ӧ90�㣻2048��Ӧ180�㣻3072��Ӧ270�㡣

//reg         [11:0] I_angle_ele;           // ��ǰ��Ƕȣ����Ϊ �ף���ȡֵ��Χ0~4095��0��Ӧ0�㣻1024��Ӧ90�㣻2048��Ӧ180�㣻3072��Ӧ270�㡣

reg                en_iabc;       // 3���ϵĵ�����Ч���ڲ����ߵ�ƽ����ʱ��˵�� Ia, Ib, Ic ��������

wire               en_ialphabeta; // ��/���ᣨ����ֱ������ϵ���ϵĵ���ʸ����Ч�źţ��ڲ����ߵ�ƽ����ʱ��˵�� I��, I�� ��������
wire signed [15:0] ialpha, ibeta; // ��/���ᣨ����ֱ������ϵ���ϵĵ���ʸ����ialpha �� �� ��ķ��������Ϊ I������ibeta �� �� ��ķ��������Ϊ I�£�


// ���    ���� always ����ݻ��������������(KCL)�� ADC ԭʼֵ (ADCa, ADCb, ADCc) �ϼ�ȥƫ��ֵ������� 3 �����ֵ Ia, Ib, Ic
// ����    ��ADC ԭʼֵ ADCa, ADCb, ADCc
// ���    ������� Ia, Ib, Ic
// ���㹫ʽ��Ia = ADCb + ADCc - 2*ADCa
//           Ib = ADCa + ADCc - 2*ADCb
//           Ic = ADCa + ADCb - 2*ADCc
// ������£�ADC ÿ�������һ�Σ���en_adcÿ����һ�θߵ�ƽ���壩�����һ�Σ�������Ƶ�� = �������ڣ����º� en_iabc ����һ��ʱ�����ڵĸߵ�ƽ����
always @ (posedge clk or negedge O_init_done)
    if(~O_init_done) begin
        {en_iabc, O_current_ia, O_current_ib, O_current_ic} <= 0;
    end else begin
        en_iabc <= en_adc;
        if(en_adc) begin
            O_current_ia <= $signed( {4'b0, adc_b} + {4'b0, adc_c} - {3'b0, adc_a, 1'b0} );   // Ia = ADCb + ADCc - 2*ADCa
            O_current_ib <= $signed( {4'b0, adc_a} + {4'b0, adc_c} - {3'b0, adc_b, 1'b0} );   // Ib = ADCa + ADCc - 2*ADCb
            O_current_ic <= $signed( {4'b0, adc_a} + {4'b0, adc_b} - {3'b0, adc_c, 1'b0} );   // Ic = ADCa + ADCb - 2*ADCc
        end
    end



// ���    ����ģ�����ڽ��� clark �任������ 3 ��������� ��/�� �ᣨ����ֱ������ϵ���ĵ���ʸ��
// ����    ������� Ia, Ib, Ic
// ���    ����/�� ��ĵ���ʸ�� I��, I��
// ���㹫ʽ��I�� = 2 * Ia - Ib - Ic
//           I�� = ��3 * (Ib - Ic)
// ������£�en_iabc ÿ����һ���ߵ�ƽ�������������ں� I��, I�� ���£�ͬʱ en_ialphabeta ����һ��ʱ�����ڵĸߵ�ƽ���壬������Ƶ�� = ��������
clark_tr u_clark_tr (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .i_en         ( en_iabc                  ),
    .i_ia         ( O_current_ia                       ),  // input : Ia
    .i_ib         ( O_current_ib                       ),  // input : Ib
    .i_ic         ( O_current_ic                       ),  // input : Ic
    .o_en         ( en_ialphabeta            ),
    .o_ialpha     ( ialpha                   ),  // output: I��
    .o_ibeta      ( ibeta                    )   // output: I��
);



// ���    ����ģ�����ڽ��� park �任������ ��/�� �ᣨ����ֱ������ϵ���ĵ���ʸ�� ���� d/q �ᣨת��ֱ������ϵ���ĵ���ʸ��
// ����    ����Ƕ� ��
//           ��/�� ��ĵ���ʸ�� I��, I��
// ���    ��d/q ��ĵ���ʸ�� Id, Iq
// ���㹫ʽ��Id = I�� * cos�� + I�� * sin��;
//           Iq = I�� * cos�� - I�� * sin��;
// ������£�en_ialphabeta ÿ����һ���ߵ�ƽ�������������ں� Id, Iq ���£�ͬʱ en_idq ����һ��ʱ�����ڵĸߵ�ƽ���壬������Ƶ�� = ��������
park_tr u_park_tr (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .psi          ( I_angle_ele                      ),  // input : ��
    .i_en         ( en_ialphabeta            ),
    .i_ialpha     ( ialpha                   ),  // input : I��
    .i_ibeta      ( ibeta                    ),  // input : I��
    .o_en         ( en_idq                   ),
    .o_id         ( O_current_id             ),  // output: Id
    .o_iq         ( O_current_iq             )   // output: Iq
);



// ���    ����ģ�����ڽ��� Id (����ʸ����d��ķ���) �� PID ���ƣ����� Id ��Ŀ��ֵ��id_aim���� Id ��ʵ��ֵ��id�������ִ�б��� Vd����ѹʸ����d���ϵķ�����
// ����    ������ʸ����d��ķ�����ʵ��ֵ��id��
//           ����ʸ����d��ķ�����Ŀ��ֵ��id_aim��
// ���    ����ѹʸ����d���ϵķ�����vd��
// ԭ��    ��PID ���ƣ�ʵ����û��D��ֻ��P��I��
// ������£�en_idq ÿ����һ���ߵ�ƽ�������������ں� Vd ���£�������Ƶ�� = ��������
//wire signed [15:0] S_id_pi_vd, S_id_ff_vd;
pi_controller u_id_pi (
    .rstn         ( O_init_done                	),
    .clk          ( clk                      	),
    .i_en         ( en_idq                   	),
//    .i_Kp         ( I_control_mode == 2'd0 ? I_current_id_kp : S_current_id_kp  ),
//    .i_Ki         ( I_control_mode == 2'd0 ? I_current_id_ki : S_current_id_ki  ),
//    .i_aim        ( I_control_mode == 2'd0 ? I_current_id_aim : S_current_id_aim),  // input : Idaim
    .i_Kp         (I_current_id_kp				),
    .i_Ki         (I_current_id_ki				),
    .i_aim        (I_current_id_aim		 		),  // input : Idaim
    .i_real       ( O_current_id             	),  // input : Id
    .o_en         (                          	),
//    .o_value      ( S_id_pi_vd          		)   // output: Vd
    .o_value      ( S_voltage_vd          		)   // output: Vd
);
//feed_forward_controller u_id_feed_forward(
//    .rstn         ( O_init_done                	),
//    .clk          ( clk                      	),
//    .i_en         ( en_idq                   	),
//    .i_Kg         ( I_control_mode == 2'd0 ? I_current_id_fg : S_current_id_fg  ),
//    .i_aim        ( I_control_mode == 2'd0 ? I_current_id_aim : S_current_id_aim),  // input : Idaim
//    .o_en         (                          	),
//    .o_value      ( S_id_ff_vd             		)   // output: Vd
//);
//assign S_voltage_vd =  S_id_pi_vd + S_id_ff_vd;


// ���    ����ģ�����ڽ��� Iq (����ʸ����q��ķ���) �� PID ���ƣ����� Iq ��Ŀ��ֵ��iq_aim���� Iq ��ʵ��ֵ��iq�������ִ�б��� Vq����ѹʸ����d���ϵķ�����
// ����    ������ʸ����q��ķ�����ʵ��ֵ��iq��
//           ����ʸ����q��ķ�����Ŀ��ֵ��iq_aim��
// ���    ����ѹʸ����q���ϵķ�����vq��
// ԭ��    ��PID ���ƣ�ʵ����û��D��ֻ��P��I��
// ������£�en_idq ÿ����һ���ߵ�ƽ�������������ں� Vq ���£�������Ƶ�� = ��������
//wire signed [15:0] S_iq_pi_vq, S_iq_ff_vq;
pi_controller u_iq_pi (
    .rstn         ( O_init_done                	),
    .clk          ( clk                      	),
    .i_en         ( en_idq                   	),
//    .i_Kp         ( I_control_mode == 2'd0 ? I_current_iq_kp : S_current_iq_kp  ),
//    .i_Ki         ( I_control_mode == 2'd0 ? I_current_iq_ki : S_current_iq_ki  ),
//    .i_aim        ( I_control_mode == 2'd0 ? I_current_iq_aim : S_current_iq_aim),  // input : Iqaim
    .i_Kp         ( I_current_iq_kp				),
    .i_Ki         ( I_current_iq_ki				),
    .i_aim        ( I_current_iq_aim			),  // input : Iqaim
    .i_real       ( O_current_iq             	),  // input : Iq
    .o_en         (                          	),
//    .o_value      ( S_iq_pi_vq             		)   // output: Vq
    .o_value      ( S_voltage_vq             		)   // output: Vq
);
//feed_forward_controller u_iq_feed_forward(
//    .rstn         ( O_init_done                	),
//    .clk          ( clk                      	),
//    .i_en         ( en_idq                   	),
//    .i_Kg         ( I_control_mode == 2'd0 ? I_current_iq_fg : S_current_iq_fg  ),
//    .i_aim        ( I_control_mode == 2'd0 ? I_current_iq_aim : S_current_iq_aim),  // input : Idaim
//    .o_en         (                          	),
//    .o_value      ( S_iq_ff_vq             		)   // output: Vd
//);
//assign S_voltage_vq = S_iq_pi_vq + S_iq_ff_vq;



// ���    ����ģ�����ڰѵ�ѹʸ����ת��ֱ������ϵ (Vd, Vq) �任��ת�Ӽ�����ϵ (Vr��, Vr��)
// ����    ����ѹʸ����ת��ֱ������ϵ�� d ���ϵķ�����Vd��
//           ��ѹʸ����ת��ֱ������ϵ�� q ���ϵķ�����Vq��
// ���    ����ѹʸ����ת�Ӽ�����ϵ�ϵķ�ֵ��Vr�ѣ�
// ԭ��    ����ѹʸ����ת�Ӽ�����ϵ�ϵĽǶȣ�Vr�ȣ�
// ������£�Vd, Vq ÿ�����仯���������ں� Vr�� �� Vr�� ���£�����Ƶ�� = ��������
cartesian2polar u_cartesian2polar (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .i_en         ( 1'b1                     ),
    // SF1��Դ����������Э
    .i_x          ( I_control_mode == 2'd3 ? I_voltage_vd : S_voltage_vd),  // input : Vd
    .i_y          ( I_control_mode == 2'd3 ? I_voltage_vq : S_voltage_vq),  // input : Vq
//    .i_x          ( I_voltage_vd),  // input : Vd
//    .i_y          ( I_voltage_vq),  // input : Vq
    .o_en         (                          ),
    .o_rho        ( O_voltage_vr_rho                   ),  // output: Vr��
    .o_theta      ( O_voltage_vr_theta                 )   // output: Vr��
);



// ���    ���� always �����ڽ��г�ʼ�� �� ��park�任
//           һ����ʼ���� ���г�ʼ��е�Ƕȱ궨�������� Vs�� ȡ���Vs��=0����ת����Ȼ��ת����Ƕ� ��=0 �ĵط���Ȼ���¼�´�ʱ�Ļ�е�Ƕ� �� ��Ϊ��ʼ��е�Ƕ� �� ����֮��Ϳ����ù�ʽ �� = N * (�� - ��) �����Ƕȡ�
//           ������park�任�� ��ʼ����ɺ󣬳����ذѵ�ѹʸ����ת�Ӽ�����ϵ (Vr��, Vr��) �任�� ���Ӽ�����ϵ (Vs��, Vs��)
// ����    ���գ�Vr��, Vr��
// ���    ������Vs��, Vs�ȣ�init_done
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        {O_voltage_vs_rho, O_voltage_vs_theta} <= 0;
        init_cnt <= 0;
//        init_phi <= 0;
        O_init_done <= 1'b0;
    end else begin
        if(init_cnt<=INIT_CYCLES) begin      // �� init_cnt �������� <= INIT_CYCLES �����ʼ��δ���
            O_voltage_vs_rho <= 12'd4095;              //    ��ʼ���׶��� Vs�� ȡ���
            O_voltage_vs_theta <= 12'd0;               //    ��ʼ���׶��� Vs�� = 0
            init_cnt <= init_cnt + 1;
            if(init_cnt==INIT_CYCLES) begin  // �� init_cnt �������� == INIT_CYCLES , ˵����ʼ���������
//                init_phi <= phi;             //    ��¼��ǰ��е�ǶȦ� ��Ϊ��ʼ��е�Ƕ� ��
                O_init_done <= 1'b1;           //    �� init_done = 1 ��ָʾ��ʼ������
            end
        end else begin                       // �� init_cnt �������� > INIT_CYCLES �����ʼ�����
            O_voltage_vs_rho <= O_voltage_vr_rho;                //    ��park�任�����ڷ�ֵ����ת�����ԣ�Vs�� = Vr��
            O_voltage_vs_theta <= O_voltage_vr_theta + I_angle_ele;      //    ��park�任������ת�Ӽ�����ϵ�Ƕ��Ӽ�����ϵ��ת �� ���������� Vs�� = Vr�� + ��
        end
    end



// ���    ����ģ����7��ʽ SVPWM ���������������� 3 ���ϵ� PWM �źš�
// ����    �����Ӽ�����ϵ�µĵ�ѹʸ�� Vs��, Vs��
// ���    ��PWMʹ���ź� pwm_en
//           3��PWM�ź� pwm_a, pwm_b, pwm_c
// ˵��    ����ģ������� PWM ��Ƶ���� clk Ƶ�� / 2048������ clk Ϊ 36.864MHz ���� PWM ��Ƶ��Ϊ 36.864MHz / 2048 = 18kHz
svpwm u_svpwm (
    .rstn         ( rstn                     ),
    .clk          ( clk                      ),
    .v_amp        ( MAX_AMP                  ),
    .v_rho        ( O_voltage_vs_rho                   ),  // input : Vs��
    .v_theta      ( O_voltage_vs_theta                 ),  // input : Vs��
    .pwm_en       ( O_pwm_en                   ),  // output
    .pwm_a        ( O_pwm_a                    ),  // output
    .pwm_b        ( O_pwm_b                    ),  // output
    .pwm_c        ( O_pwm_c                    )   // output
);



// ���    ����ģ�����ڿ����������� ADC �Ĳ���ʱ��
// ����    ��3��PWM�ź� pwm_a, pwm_b, pwm_c
// ���    ��3����� ADC ����ʱ�̿����ź� sn_adc
// ԭ��    ����ģ���� pwm_a, pwm_b, pwm_c ��Ϊ�͵�ƽ��ʱ�̣����ӳ� SAMPLE_DELAY ��ʱ�����ڣ��� sn_adc �ź��ϲ���һ��ʱ�����ڵĸߵ�ƽ��
hold_detect #(
    .SAMPLE_DELAY ( SAMPLE_DELAY             )
) u_adc_sn_ctrl (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .in           ( ~O_pwm_a & ~O_pwm_b & ~O_pwm_c ),  // input : �� pwm_a, pwm_b, pwm_c ��Ϊ�͵�ƽʱ=1������=0
    .out          ( sn_adc                   )   // output: �������ź�=1������ SAMPLE_DELAY �����ڣ��� sn_adc �ϲ���1�����ڵĸߵ�ƽ����
);


endmodule

