module i2c_top(  
	input wire clk,
	input wire rst,
    output scl, 
    inout sda, 
	//TM1638
	inout wire DIO,
	output wire STB,
	output reg clk_400KHz
	);
wire i2c_start;
wire [6:0] slave_addr;
wire cmd_byte;
wire [15:0] i2c_cmd;
wire [5:0] wait_time;
wire [2:0] data_byte;
wire [1:0] num;
wire i2c_ready ;
wire [15:0] bin; 
reg  [7:0] cnt_clk;
wire [1:0] flag;
wire [2:0] mod;

always @(posedge clk or negedge rst)begin
	if(!rst)
		cnt_clk <= 8'd0;
	else if(cnt_clk > 8'd123)
		cnt_clk <= 8'd0;
	else
		cnt_clk <= cnt_clk + 8'd1;
end

always @(posedge clk or negedge rst)begin
	if(!rst)
		clk_400KHz <= 1'b0;
	else if(cnt_clk == 8'd123)
		clk_400KHz <= ~clk_400KHz;
	else
		clk_400KHz <= clk_400KHz;
end


endmodule