
//--------------------------------------------------------------------------------------------------------
// ģ��: adc_ad7928
// Type    : synthesizable
// Standard: Verilog 2001 (IEEE1364-2001)
// ���ܣ�ͨ�� SPI �ӿڴ� ADC7928 (ADCоƬ) �ж��� ADC ֵ��
// ����������·�ע�ͣ���ģ�����ʹ�ò�����ȫ���ɵ����õ���ת��Ҫ�ö��ٸ�ͨ���Լ�����Щͨ��
// �������������·�ע��
//--------------------------------------------------------------------------------------------------------

module adc_ad7928 #(
    parameter [2:0] CH_CNT = 3'd7,  // ���� ADC ת��ʹ�õ�ͨ����Ϊ CH_CNT+1�������� CH_CNT=0����ֻʹ�� CH0 ���� CH_CNT=2����ʹ�� CH0,CH1,CH2�� �� CH_CNT=7����ʹ�� CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7���õ�ͨ��Խ�࣬ADCת��ʱ��Խ�������� sn_adc �� en_adc ֮���ʱ���Խ����
    parameter [2:0] CH0 = 3'd0,     // ָʾ�� CH0 ��Ӧ AD7928 ���ĸ�ͨ��
    parameter [2:0] CH1 = 3'd1,     // ָʾ�� CH1 ��Ӧ AD7928 ���ĸ�ͨ��
    parameter [2:0] CH2 = 3'd2,     // ָʾ�� CH2 ��Ӧ AD7928 ���ĸ�ͨ��
    parameter [2:0] CH3 = 3'd3,     // ָʾ�� CH3 ��Ӧ AD7928 ���ĸ�ͨ��
    parameter [2:0] CH4 = 3'd4,     // ָʾ�� CH4 ��Ӧ AD7928 ���ĸ�ͨ��
    parameter [2:0] CH5 = 3'd5,     // ָʾ�� CH5 ��Ӧ AD7928 ���ĸ�ͨ��
    parameter [2:0] CH6 = 3'd6,     // ָʾ�� CH6 ��Ӧ AD7928 ���ĸ�ͨ��
    parameter [2:0] CH7 = 3'd7      // ָʾ�� CH7 ��Ӧ AD7928 ���ĸ�ͨ��
) (
    input  wire        rstn,
    input  wire        clk,
    // -------------------- SPI �ӿڣ�Ӧ�ýӵ� AD7928 оƬ��   ---------------------------------------------------------------
    output reg         spi_ss,      // SPI �ӿڣ�SS
    output reg         spi_sck,     // SPI �ӿڣ�SCK
    output reg         spi_mosi,    // SPI �ӿڣ�MOSI
    input  wire        spi_miso,    // SPI �ӿڣ�MISO
    // -------------------- �û��߼��ӿ�  ------------------------------------------------------------------------------------
    input  wire        i_sn_adc,    // ADC ת����ʼ�źţ��� i_sn_adc �ϳ��ָߵ�ƽ����ʱ��ADCת����ʼ
    output reg         o_en_adc,    // ADC ת������źţ���ת�����ʱ��o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����
    output wire [11:0] o_adc_value0,// �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH0 �� ADC ת����������ڸ��ź���
    output wire [11:0] o_adc_value1,// �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH1 �� ADC ת����������ڸ��ź���
    output wire [11:0] o_adc_value2,// �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH2 �� ADC ת����������ڸ��ź���
    output wire [11:0] o_adc_value3,// �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH3 �� ADC ת����������ڸ��ź���
    output wire [11:0] o_adc_value4,// �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH4 �� ADC ת����������ڸ��ź���
    output wire [11:0] o_adc_value5,// �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH5 �� ADC ת����������ڸ��ź���
    output wire [11:0] o_adc_value6,// �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH6 �� ADC ת����������ڸ��ź���
    output wire [11:0] o_adc_value7 // �� o_en_adc ����һ��ʱ�����ڵĸߵ�ƽ����ʱ��CH7 �� ADC ת����������ڸ��ź���
);

localparam WAIT_CNT = 8'd6;

wire [2:0] channels [0:7];
assign channels[0] = CH0;
assign channels[1] = CH1;
assign channels[2] = CH2;
assign channels[3] = CH3;
assign channels[4] = CH4;
assign channels[5] = CH5;
assign channels[6] = CH6;
assign channels[7] = CH7;

reg  [ 7:0] cnt;
reg  [ 2:0] idx;
reg  [ 2:0] addr;
reg  [11:0] wshift;
reg         nfirst;
reg  [11:0] data_in_latch;
reg         sck_pre;
reg  [11:0] ch_value [0:7];

assign o_adc_value0 = ch_value[0];
assign o_adc_value1 = ch_value[1];
assign o_adc_value2 = ch_value[2];
assign o_adc_value3 = ch_value[3];
assign o_adc_value4 = ch_value[4];
assign o_adc_value5 = ch_value[5];
assign o_adc_value6 = ch_value[6];
assign o_adc_value7 = ch_value[7];

always @ (posedge clk or negedge rstn)
    if(~rstn)
        spi_sck <= 1'b1;
    else
        spi_sck <= sck_pre;

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        cnt <= 0;
        idx <= 3'd7;
        addr <= 3'd0;
        wshift <= 12'hFFF;
        {spi_ss, sck_pre, spi_mosi} <= 3'b111;
    end else begin
        if(cnt==8'd0) begin
            {spi_ss, sck_pre, spi_mosi} <= 3'b111;
            if(idx != 3'd0) begin
                cnt <= 8'd1;
                idx <= idx - 3'd1;
            end else if(i_sn_adc) begin
                cnt <= 8'd1;
                idx <= CH_CNT;
            end
        end else if(cnt==8'd1) begin
            {spi_ss, sck_pre, spi_mosi} <= 3'b111;
            addr <= (idx == 3'd0) ? CH_CNT : idx - 3'd1;
            cnt <= cnt + 8'd1;
        end else if(cnt==8'd2) begin
            {spi_ss, sck_pre, spi_mosi} <= 3'b111;
            wshift <= {1'b1, 1'b0, 1'b0, channels[addr], 2'b11, 1'b0, 1'b0, 2'b11};
            cnt <= cnt + 8'd1;
        end else if(cnt<WAIT_CNT) begin
            {spi_ss, sck_pre, spi_mosi} <= 3'b111;
            cnt <= cnt + 8'd1;
        end else if(cnt<WAIT_CNT+8'd32) begin
            spi_ss <= 1'b0;
            sck_pre <= ~sck_pre;
            if(sck_pre)
                {spi_mosi,wshift} <= {wshift,1'b1};
            cnt <= cnt + 8'd1;
        end else begin
            spi_ss <= 1'b0;
            {sck_pre, spi_mosi} <= 2'b11;
            cnt <= 8'd0;
        end
    end


always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        o_en_adc <= 1'b0;
        nfirst <= 1'b0;
        data_in_latch <= 12'd0;
        ch_value[0] <= 12'd0;
        ch_value[1] <= 12'd0;
        ch_value[2] <= 12'd0;
        ch_value[3] <= 12'd0;
        ch_value[4] <= 12'd0;
        ch_value[5] <= 12'd0;
        ch_value[6] <= 12'd0;
        ch_value[7] <= 12'd0;
    end else begin
        o_en_adc <= 1'b0;
        if(cnt>=WAIT_CNT+8'd2 && cnt<WAIT_CNT+8'd32) begin
            if(spi_sck)
                data_in_latch <= {data_in_latch[10:0], spi_miso};
        end else if(cnt==WAIT_CNT+8'd32) begin
            if(idx == 3'd0) begin
                nfirst <= 1'b1;
                o_en_adc <= nfirst;
            end
            ch_value[idx] <= data_in_latch;
        end
    end

endmodule
