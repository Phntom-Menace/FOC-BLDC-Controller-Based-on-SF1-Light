
//--------------------------------------------------------------------------------------------------------
// ģ�飺 hold_detect
// Type    : synthesizable
// Standard: Verilog 2001 (IEEE1364-2001)
// ���ܣ� ��� in �Ӹߵ�ƽ��Ϊ�͵�ƽ������ SAMPLE_DELAY ��ʱ�����ڣ��� sn_adc �ź��ϲ���һ��ʱ�����ڵĸߵ�ƽ��
//--------------------------------------------------------------------------------------------------------

module hold_detect #(
    parameter [15:0]  SAMPLE_DELAY = 16'd100
) (
    input  wire  rstn,
    input  wire  clk,
    input  wire  in,
    output reg   out
);

reg        latch1, latch2;
reg [15:0] cnt;

always @ (posedge clk or negedge rstn)
    if(~rstn)
        {latch1, latch2} <= 2'b11;
    else
        {latch1, latch2} <= {in, latch1};

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        out <= 1'b0;
        cnt <= 16'd0;
    end else begin
        out <= 1'b0;
        if(latch1) begin
            if(latch2) begin
                if( cnt != 16'd0 )
                    cnt <= cnt - 16'd1;
                out <= cnt == 16'd1;
            end else begin
                cnt <= SAMPLE_DELAY;
            end
        end else begin
            cnt <= 16'd0;
        end
    end

endmodule
