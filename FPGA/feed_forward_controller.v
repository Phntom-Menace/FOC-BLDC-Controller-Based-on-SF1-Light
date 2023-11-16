module feed_forward_controller(
    input  wire               rstn,
    input  wire               clk,
    input  wire               i_en,
    input  wire        [15:0] i_Kg,
    input  wire signed [15:0] i_aim,
    output reg                o_en,
    output wire signed [15:0] o_value
    );
    
reg signed [31:0] value;

//function  signed [31:0] protect_mul;
//    input signed [31:0] a, b;
//    reg   signed [56:0] y;
////function automatic logic signed [31:0] protect_mul(input logic signed [31:0] a, input logic signed [24:0] b);
////    automatic logic signed [56:0] y;
//begin
//    y = a * b;
//    if(     y >  $signed(57'h7fffffff) )
//        protect_mul =  $signed(32'h7fffffff);
//    else if(y < -$signed(57'h7fffffff) )
//        protect_mul = -$signed(32'h7fffffff);
//    else
//        protect_mul =  $signed(y[31:0]);
//end
//endfunction

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        value <= 0;
    end else begin
        if(i_en) begin	
            value <= i_aim * $signed({1'h0, i_Kg});   // value = i_aim - i_real
        end
    end
assign o_value = value[23:0] >> 8; // o_value = value >> 8(/256);

endmodule
