module shift_filter
#(
	parameter AVE_DATA_NUM = 5'd8,
	parameter AVE_DATA_BIT = 5'd3
)
(
	input i_rst,
	input i_clk,
	input [31:0]din,
	output [31:0]dout
);

reg [31:0] data_reg [AVE_DATA_NUM-1:0];

reg [7:0]temp_i;

always @ (posedge i_clk or posedge i_rst)
if(i_rst)
	for (temp_i=0; temp_i<AVE_DATA_NUM; temp_i=temp_i+1)
		data_reg[temp_i] <= 'h00000000;
else
begin
	data_reg[0] <= din;
	for (temp_i=0; temp_i<AVE_DATA_NUM-1; temp_i=temp_i+1)
		data_reg[temp_i+1] <= data_reg[temp_i];
end

reg [31:0] sum;

always @ (posedge i_clk or posedge i_rst)
if (i_rst)
	sum <= 'h00000000;
else
	sum <= sum + din - data_reg[AVE_DATA_NUM-1]; //将最老的数据换为最新的输入数据

assign dout = sum >> AVE_DATA_BIT; //右移3 等效为÷8

endmodule 