module ahb2hall_sensor(
    input              I_ahb_clk,
    input              I_rst,

    input   [1:0]      I_ahb_htrans,
    input              I_ahb_hwrite,
    input   [31:0]     I_ahb_haddr,       //synthesis keep
    input   [2:0]      I_ahb_hsize,
    input   [2:0]      I_ahb_hburst,
    input   [3:0]      I_ahb_hprot,
    input              I_ahb_hmastlock,
    input   [31:0]     I_ahb_hwdata,      //synthesis keep
    output  reg [31:0] O_ahb_hrdata,      //synthesis keep
    output  wire[1:0]  O_ahb_hresp,
    output  reg        O_ahb_hready,
    
    input              I_hall_clk,
    // IO pins
    input  wire 		hall_u,
    input  wire 		hall_v,
    input  wire 		hall_w
	
);

    reg        S_ahb_wr_trig;
    reg        S_ahb_wr_trig_1d;
    reg[31:0]  S_ahb_wr_addr;
    reg[31:0]  S_ahb_wr_data;

    reg        S_ahb_rd_trig;
    reg        S_ahb_rd_trig_1d;
    reg[31:0]  S_ahb_rd_addr;
    reg[31:0]  S_ahb_rd_data; 
    
// Registers
reg  [31:0]	en;
reg  [31:0]	angle_e_o;
reg  [31:0]	error;
reg  [31:0]	lost;
reg  [31:0] step;

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            O_ahb_hready <= 1'b1;
        else
            if(I_ahb_htrans == 2'b10)
                O_ahb_hready <= 1'b0;
            else if(S_ahb_wr_trig_1d || S_ahb_rd_trig_1d)
                O_ahb_hready <= 1'b1;
            else
                O_ahb_hready <= O_ahb_hready;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_wr_trig <= 1'b0;
        else
            if(I_ahb_htrans == 2'b10 && I_ahb_hwrite)
                S_ahb_wr_trig <= 1'b1;
            else
                S_ahb_wr_trig <= 1'b0;
    end

    always @(posedge I_ahb_clk) begin
        S_ahb_wr_trig_1d <= S_ahb_wr_trig;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_wr_addr <= 'd0;
        else
            if(S_ahb_wr_trig)
                S_ahb_wr_addr <= I_ahb_haddr;
            else
                S_ahb_wr_addr <= S_ahb_wr_addr;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_wr_data <= 'd0;
        else
            if(S_ahb_wr_trig)
                S_ahb_wr_data <= I_ahb_hwdata;
            else
                S_ahb_wr_data <= S_ahb_wr_data;
    end
//总线写寄存器
    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            begin
                en  		<= 'd0;
            end
        else
            begin
                if(S_ahb_wr_trig_1d)
                    begin
                        case(S_ahb_wr_addr[7:0])
                            8'h00:  en  	       <= S_ahb_wr_data; 
                        endcase
                    end
                else
                    begin
                        en  	 <= en  	;
                    end
            end
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_rd_trig <= 1'b0;
        else
            if(I_ahb_htrans == 2'b10 && (!I_ahb_hwrite))
                S_ahb_rd_trig <= 1'b1;
            else
                S_ahb_rd_trig <= 1'b0;
    end

    always @(posedge I_ahb_clk) begin
        S_ahb_rd_trig_1d <= S_ahb_rd_trig;
    end

    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            S_ahb_rd_addr <= 'd0;
        else
            if(S_ahb_rd_trig)
                S_ahb_rd_addr <= I_ahb_haddr;
            else
                S_ahb_rd_addr <= S_ahb_rd_addr;
    end
//总线读寄存器
    always @(posedge I_ahb_clk or posedge I_rst) begin
        if(I_rst)
            O_ahb_hrdata <= 'd0;
        else
            begin
                if(S_ahb_rd_trig_1d)
                    begin
                        case(S_ahb_rd_addr[7:0])
                            8'h00: O_ahb_hrdata  <=en  	    ;
                            8'h04: O_ahb_hrdata  <=angle_e_o   ;
                            8'h08: O_ahb_hrdata  <=error  ;
                            8'h0C: O_ahb_hrdata  <=lost  ;
                            8'h10: O_ahb_hrdata  <=step  ;
                        endcase
                    end
                else
                    O_ahb_hrdata <= O_ahb_hrdata;
            end
    end
    
    wire [11:0] hall_angle;
    wire [2:0]  hall_step;
    wire hall_error;
    wire hall_lost;
    
    always @(posedge I_hall_clk) begin
    	angle_e_o[11:0] <= hall_angle;
    	error[0] <= hall_error;
    	lost[0] <= hall_lost;
        step[2:0] <= hall_step;
    end

/* Hall sensor */
hall_sensor hall_sendor_u1(
    .clk(I_hall_clk),
    .rst(~en[0]),
    
    .angle_e_o(hall_angle),
    .hall_step(hall_step),
    
    .error(hall_error),
    .lost(hall_lost),
    
    
    .hall_u(hall_u),
    .hall_v(hall_v),
    .hall_w(hall_w)
);
endmodule