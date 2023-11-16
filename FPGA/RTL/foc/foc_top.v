module foc_top #(
    // ----------------------------------------------- 模块参数 ---------------------------------------------------------------------------------------------------------------------------------------------------
    parameter        INIT_CYCLES  = 16777216,       // 决定了初始化步骤占多少个时钟(clk)周期，取值范围为1~4294967294。该值不能太短，因为要留足够的时间让转子回归电角度=0。例如若时钟(clk)频率为 36.864MHz，INIT_CYCLES=16777216，则初始化时间为 16777216/36864000=0.45 秒
    parameter [ 8:0] MAX_AMP      = 9'd255,         // SVPWM 的最大振幅，取值范围为1~511，该值越小，电机能达到的最大力矩越小；但考虑到使用3相下桥臂电阻采样法来采样电流，该值也不能太大，以保证3个下桥臂有足够的持续导通时间来供ADC进行采样。
    parameter [ 8:0] SAMPLE_DELAY = 9'd150          // 采样延时，取值范围0~511，考虑到3相的驱动 MOS 管从开始导通到电流稳定需要一定的时间，所以从3个下桥臂都导通，到 ADC 采样时刻之间需要一定的延时。该参数决定了该延时是多少个时钟周期，当延时结束时，该模块在 sn_adc 信号上产生一个高电平脉冲，指示外部 ADC "可以采样了"
) (
    // ----------------------------------------------- 驱动时钟和复位 ---------------------------------------------------------------------------------------------------------------------------------------------
    input  wire               rstn,                 // 复位信号，应该先拉低来对模块进行复位，然后一直保持高电平来让模块正常工作。
    input  wire               clk,                  // 时钟信号，频率可取几十MHz。控制频率 = 时钟频率 / 2048。比如若时钟频率为 36.864MHz ，那么控制频率为 36.864MHz/2048=18kHz。（控制频率 = 3相电流采样的采样率 = PID算法的控制频率 = SVPWM占空比的更新频率）
    // ----------------------------------------------- PI 参数 ----------------------------------------------------------------------------------------------------------------------------------------------------
    
    input  wire          [5:0]  I_motor_polePair,    // 电机极对数
    input  wire                 I_motor_dir,                // 电机方向，0选择uvw顺序驱动电机逆时针转动，1选择uvw顺序驱动电机逆时针转动
    
    // 控制模式选择和目标量设置
    input  wire         [ 1:0]  I_control_mode,        // 闭环控制模式 0电流环 1速度环 2位置环 3开环
    input  wire signed  [15:0]  I_current_id_aim,      // 电流环转子d轴（直轴）的目标电流值
    input  wire signed  [15:0]  I_current_iq_aim,      // 电流环转子q轴（交轴）的目标电流值
    input  wire signed  [15:0]  I_velocity_aim,        // 速度环目标转速
    input  wire signed  [15:0]  I_position_aim,        // 位置环目标角度
    input  wire signed  [15:0]  I_voltage_vd,          // 开环vd电压
    input  wire signed  [15:0]  I_voltage_vq,          // 开环vq电压
    // PI和前馈参数
    input  wire signed  [15:0]  I_current_id_kp,       // 电流环id PI控制器 Kp
    input  wire signed  [15:0]  I_current_id_ki,       // 电流环id PI控制器 Ki
    input  wire signed  [15:0]  I_current_id_fg,       // 电流环id 前馈控制器 Gain
    input  wire signed  [15:0]  I_current_iq_kp,       // 电流环iq PI控制器 Kp
    input  wire signed  [15:0]  I_current_iq_ki,       // 电流环iq PI控制器 Ki
    input  wire signed  [15:0]  I_current_iq_fg,       // 电流环iq 前馈控制器 Gain
    input  wire signed  [15:0]  I_velocity_kp,         // 速度环 PI控制器 Kp
    input  wire signed  [15:0]  I_velocity_ki,         // 速度环 PI控制器 Ki
    input  wire signed  [15:0]  I_velocity_fg,         // 速度环 前馈控制器 Gain
    input  wire signed  [15:0]  I_position_kp,         // 位置环 PI控制器Kp
    input  wire signed  [15:0]  I_position_ki,         // 位置环 PI控制器 Ki
    input  wire signed  [15:0]  I_position_fg,         // 位置环 前馈控制器 Gain


    
    // ----------------------------------------------- 角度传感器输入信号 -----------------------------------------------------------------------------------------------------------------------------------------
    input  wire         [11:0]  I_angle_ele,                  // 电角度输入，取值范围0~4095。0对应0°；1024对应90°；2048对应180°；3072对应270°。
    // ----------------------------------------------- 3相电流 ADC 采样时刻控制信号 和采样结果输入信号 ------------------------------------------------------------------------------------------------------------
    output wire                 sn_adc,               // 3相电流 ADC 采样时刻控制信号，当需要进行一次采样时，sn_adc 信号上产生一个时钟周期的高电平脉冲，指示ADC应该进行采样了。
    input  wire                 en_adc,               // 3相电流 ADC 采样结果有效信号，sn_adc 产生高电平脉冲后，外部ADC开始采样3相电流，在转换结束后，应在 en_adc 信号上产生一个周期的高电平脉冲，同时把ADC转换结果产生在 adc_a, adc_b, adc_c 信号上
    input  wire         [11:0]  adc_a, adc_b, adc_c,  // 3相电流 ADC 采样结果（简记为ADCa, ADCb, ADCc），取值范围0 ~ 4095
    // ----------------------------------------------- 3相 PWM 信号，（包含使能信号） -----------------------------------------------------------------------------------------------------------------------------
    output wire                 O_pwm_en,               // 3相共用的使能信号，当 pwm_en=0 时，6个MOS管全部关断。
    output wire                 O_pwm_a,                // A相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    output wire                 O_pwm_b,                // B相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    output wire                 O_pwm_c,                // C相PWM信号。当 =0 时。下桥臂导通；当 =1 时，上桥臂导通
    // ----------------------------------------------- d/q轴（转子直角坐标系）的电流监测 --------------------------------------------------------------------------------------------------------------------------
    output wire                 en_idq,               // 出现高电平脉冲时说明 id 和 iq 出现了新值，每个控制周期 en_idq 会产生一个高电平脉冲
    output wire signed  [15:0]  O_current_id,                   // d 轴（直轴）的实际电流值（简记为 Id），可正可负
    output wire signed  [15:0]  O_current_iq,                   // q 轴（交轴）的实际电流值（简记为 Iq），可正可负（若正代表逆时针，则负代表顺时针，反之亦然）
    output reg  signed  [15:0]	O_current_ia,           // A相电流值
    output reg  signed  [15:0]	O_current_ib,           // B相电流值
    output reg  signed  [15:0]	O_current_ic,           // C相电流值
   // ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    output reg                  O_init_done,             // 初始化结束信号。在初始化结束前=0，在初始化结束后（进入FOC控制状态）=1
    
    output wire signed  [15:0]	O_velocity,             // 当前速度量
    output wire signed  [15:0]	O_position,             // 当前位置量
    output wire         [11:0]	O_voltage_vr_rho,       // 转子极坐标系上的电压矢量的幅值
    output wire         [11:0]	O_voltage_vr_theta,     // 转子极坐标系上的电压矢量的角度
    output reg          [11:0]	O_voltage_vs_rho,       // 定子极坐标系上的电压矢量的幅值
    output reg          [11:0]	O_voltage_vs_theta,      // 定子极坐标系上的电压矢量的角度
	output wire signed [15:0] S_current_id_aim,      // 电流环转子d轴（直轴）的目标电流值
	output wire signed [15:0] S_current_iq_aim,      // 电流环转子q轴（交轴）的目标电流值
	output wire signed [15:0] S_velocity_aim,        // 速度环目标转速
	output wire signed [15:0] S_position_aim,        // 位置环目标角度
	output wire signed [15:0] S_voltage_vd,          // 开环vd电压
	output wire signed [15:0] S_voltage_vq          // 开环vq电压

);










reg         [31:0] init_cnt;
//reg         [11:0] init_phi;      // 初始机械角度（简记为 Φ）。即电角度=0时对应的机械角度，在初始化结束时被确定，用来在之后进行机械角度到电角度的转换。取值范围0~4095。0对应0°；1024对应90°；2048对应180°；3072对应270°。

//reg         [11:0] I_angle_ele;           // 当前电角度（简记为 ψ）。取值范围0~4095。0对应0°；1024对应90°；2048对应180°；3072对应270°。

reg                en_iabc;       // 3相上的电流有效，在产生高电平脉冲时，说明 Ia, Ib, Ic 发生更新

wire               en_ialphabeta; // α/β轴（定子直角坐标系）上的电流矢量有效信号，在产生高电平脉冲时，说明 Iα, Iβ 发生更新
wire signed [15:0] ialpha, ibeta; // α/β轴（定子直角坐标系）上的电流矢量。ialpha 是 α 轴的分量（简记为 Iα），ibeta 是 β 轴的分量（简记为 Iβ）


// 简介    ：该 always 块根据基尔霍夫电流定律(KCL)在 ADC 原始值 (ADCa, ADCb, ADCc) 上减去偏移值，计算出 3 相电流值 Ia, Ib, Ic
// 输入    ：ADC 原始值 ADCa, ADCb, ADCc
// 输出    ：相电流 Ia, Ib, Ic
// 计算公式：Ia = ADCb + ADCc - 2*ADCa
//           Ib = ADCa + ADCc - 2*ADCb
//           Ic = ADCa + ADCb - 2*ADCc
// 输出更新：ADC 每采样完成一次（即en_adc每产生一次高电平脉冲）后更新一次，即更新频率 = 控制周期，更新后 en_iabc 产生一个时钟周期的高电平脉冲
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



// 简介    ：该模块用于进行 clark 变换，根据 3 相电流计算 α/β 轴（定子直角坐标系）的电流矢量
// 输入    ：相电流 Ia, Ib, Ic
// 输出    ：α/β 轴的电流矢量 Iα, Iβ
// 计算公式：Iα = 2 * Ia - Ib - Ic
//           Iβ = √3 * (Ib - Ic)
// 输出更新：en_iabc 每产生一个高电平脉冲后的若干周期后 Iα, Iβ 更新，同时 en_ialphabeta 产生一个时钟周期的高电平脉冲，即更新频率 = 控制周期
clark_tr u_clark_tr (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .i_en         ( en_iabc                  ),
    .i_ia         ( O_current_ia                       ),  // input : Ia
    .i_ib         ( O_current_ib                       ),  // input : Ib
    .i_ic         ( O_current_ic                       ),  // input : Ic
    .o_en         ( en_ialphabeta            ),
    .o_ialpha     ( ialpha                   ),  // output: Iα
    .o_ibeta      ( ibeta                    )   // output: Iβ
);



// 简介    ：该模块用于进行 park 变换，根据 α/β 轴（定子直角坐标系）的电流矢量 计算 d/q 轴（转子直角坐标系）的电流矢量
// 输入    ：电角度 ψ
//           α/β 轴的电流矢量 Iα, Iβ
// 输出    ：d/q 轴的电流矢量 Id, Iq
// 计算公式：Id = Iα * cosψ + Iβ * sinψ;
//           Iq = Iβ * cosψ - Iα * sinψ;
// 输出更新：en_ialphabeta 每产生一个高电平脉冲后的若干周期后 Id, Iq 更新，同时 en_idq 产生一个时钟周期的高电平脉冲，即更新频率 = 控制周期
park_tr u_park_tr (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .psi          ( I_angle_ele                      ),  // input : ψ
    .i_en         ( en_ialphabeta            ),
    .i_ialpha     ( ialpha                   ),  // input : Iα
    .i_ibeta      ( ibeta                    ),  // input : Iβ
    .o_en         ( en_idq                   ),
    .o_id         ( O_current_id             ),  // output: Id
    .o_iq         ( O_current_iq             )   // output: Iq
);



// 简介    ：该模块用于进行 Id (电流矢量在d轴的分量) 的 PID 控制，根据 Id 的目标值（id_aim）和 Id 的实际值（id），算出执行变量 Vd（电压矢量在d轴上的分量）
// 输入    ：电流矢量在d轴的分量的实际值（id）
//           电流矢量在d轴的分量的目标值（id_aim）
// 输出    ：电压矢量在d轴上的分量（vd）
// 原理    ：PID 控制（实际上没有D，只有P和I）
// 输出更新：en_idq 每产生一个高电平脉冲后的若干周期后 Vd 更新，即更新频率 = 控制周期
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


// 简介    ：该模块用于进行 Iq (电流矢量在q轴的分量) 的 PID 控制，根据 Iq 的目标值（iq_aim）和 Iq 的实际值（iq），算出执行变量 Vq（电压矢量在d轴上的分量）
// 输入    ：电流矢量在q轴的分量的实际值（iq）
//           电流矢量在q轴的分量的目标值（iq_aim）
// 输出    ：电压矢量在q轴上的分量（vq）
// 原理    ：PID 控制（实际上没有D，只有P和I）
// 输出更新：en_idq 每产生一个高电平脉冲后的若干周期后 Vq 更新，即更新频率 = 控制周期
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



// 简介    ：该模块用于把电压矢量从转子直角坐标系 (Vd, Vq) 变换到转子极坐标系 (Vrρ, Vrθ)
// 输入    ：电压矢量在转子直角坐标系的 d 轴上的分量（Vd）
//           电压矢量在转子直角坐标系的 q 轴上的分量（Vq）
// 输出    ：电压矢量在转子极坐标系上的幅值（Vrρ）
// 原理    ：电压矢量在转子极坐标系上的角度（Vrθ）
// 输出更新：Vd, Vq 每产生变化的若干周期后 Vrρ 和 Vrθ 更新，更新频率 = 控制周期
cartesian2polar u_cartesian2polar (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .i_en         ( 1'b1                     ),
    // SF1资源不足做出妥协
    .i_x          ( I_control_mode == 2'd3 ? I_voltage_vd : S_voltage_vd),  // input : Vd
    .i_y          ( I_control_mode == 2'd3 ? I_voltage_vq : S_voltage_vq),  // input : Vq
//    .i_x          ( I_voltage_vd),  // input : Vd
//    .i_y          ( I_voltage_vq),  // input : Vq
    .o_en         (                          ),
    .o_rho        ( O_voltage_vr_rho                   ),  // output: Vrρ
    .o_theta      ( O_voltage_vr_theta                 )   // output: Vrθ
);



// 简介    ：该 always 块用于进行初始化 和 反park变换
//           一、初始化： 进行初始机械角度标定。首先令 Vsρ 取最大，Vsθ=0，则转子自然会转到电角度 ψ=0 的地方。然后记录下此时的机械角度 φ 作为初始机械角度 Φ 。则之后就可以用公式 ψ = N * (φ - Φ) 计算电角度。
//           二、反park变换： 初始化完成后，持续地把电压矢量从转子极坐标系 (Vrρ, Vrθ) 变换到 定子极坐标系 (Vsρ, Vsθ)
// 输入    ：φ，Vrρ, Vrθ
// 输出    ：Φ，Vsρ, Vsθ，init_done
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        {O_voltage_vs_rho, O_voltage_vs_theta} <= 0;
        init_cnt <= 0;
//        init_phi <= 0;
        O_init_done <= 1'b0;
    end else begin
        if(init_cnt<=INIT_CYCLES) begin      // 若 init_cnt 计数变量 <= INIT_CYCLES ，则初始化未完成
            O_voltage_vs_rho <= 12'd4095;              //    初始化阶段令 Vsρ 取最大
            O_voltage_vs_theta <= 12'd0;               //    初始化阶段令 Vsθ = 0
            init_cnt <= init_cnt + 1;
            if(init_cnt==INIT_CYCLES) begin  // 若 init_cnt 计数变量 == INIT_CYCLES , 说明初始化即将完成
//                init_phi <= phi;             //    记录当前机械角度φ 作为初始机械角度 Φ
                O_init_done <= 1'b1;           //    令 init_done = 1 ，指示初始化结束
            end
        end else begin                       // 若 init_cnt 计数变量 > INIT_CYCLES ，则初始化完成
            O_voltage_vs_rho <= O_voltage_vr_rho;                //    反park变换。由于幅值的旋转不变性，Vsρ = Vrρ
            O_voltage_vs_theta <= O_voltage_vr_theta + I_angle_ele;      //    反park变换。由于转子极坐标系是定子极坐标系旋转 ψ 得来，所以 Vsθ = Vrθ + ψ
        end
    end



// 简介    ：该模块是7段式 SVPWM 发生器，用于生成 3 相上的 PWM 信号。
// 输入    ：定子极坐标系下的电压矢量 Vsρ, Vsθ
// 输出    ：PWM使能信号 pwm_en
//           3相PWM信号 pwm_a, pwm_b, pwm_c
// 说明    ：该模块产生的 PWM 的频率是 clk 频率 / 2048。例如 clk 为 36.864MHz ，则 PWM 的频率为 36.864MHz / 2048 = 18kHz
svpwm u_svpwm (
    .rstn         ( rstn                     ),
    .clk          ( clk                      ),
    .v_amp        ( MAX_AMP                  ),
    .v_rho        ( O_voltage_vs_rho                   ),  // input : Vsρ
    .v_theta      ( O_voltage_vs_theta                 ),  // input : Vsθ
    .pwm_en       ( O_pwm_en                   ),  // output
    .pwm_a        ( O_pwm_a                    ),  // output
    .pwm_b        ( O_pwm_b                    ),  // output
    .pwm_c        ( O_pwm_c                    )   // output
);



// 简介    ：该模块用于控制相电流检测 ADC 的采样时机
// 输入    ：3相PWM信号 pwm_a, pwm_b, pwm_c
// 输出    ：3相电流 ADC 采样时刻控制信号 sn_adc
// 原理    ：该模块检测 pwm_a, pwm_b, pwm_c 均为低电平的时刻，并延迟 SAMPLE_DELAY 的时钟周期，在 sn_adc 信号上产生一个时钟周期的高电平。
hold_detect #(
    .SAMPLE_DELAY ( SAMPLE_DELAY             )
) u_adc_sn_ctrl (
    .rstn         ( O_init_done                ),
    .clk          ( clk                      ),
    .in           ( ~O_pwm_a & ~O_pwm_b & ~O_pwm_c ),  // input : 当 pwm_a, pwm_b, pwm_c 均为低电平时=1，否则=0
    .out          ( sn_adc                   )   // output: 若输入信号=1并保持 SAMPLE_DELAY 个周期，则 sn_adc 上产生1个周期的高电平脉冲
);


endmodule

