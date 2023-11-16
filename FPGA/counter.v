module counter(
    input  wire 		clk,
    input  wire 		rst,
    input  wire			en,
    input  wire	[31:0]	period,
    output reg  		pluse
);

reg  [31:0]	cnt;

always @ (posedge clk or posedge rst) begin
	if(rst) begin
    	cnt <= 32'b0;
    end else begin
    	if(en) begin
    		cnt <= cnt + 1;
            if(cnt >= period) begin
            	cnt <= 32'b0;
            end
        end
    end
end

always @(*) begin
	if(cnt >= period) begin
    	pluse = 1'b1;
    end else begin
    	pluse = 1'b0;
    end
end

endmodule
