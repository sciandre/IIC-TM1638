module i2c_CMD(
	input wire i2c_clk,  
	input wire rst, //rst
	input wire i2c_ready, //ready for start	
	output reg i2c_start, //start enable 
	output reg [6:0] slave_addr,       
    output reg cmd_byte,   
    output reg [15:0] i2c_cmd, //slaver cmd
	output reg [5:0] wait_time, //ms. wait for measuring data ,not wait for cmd
	output reg [2:0] data_byte, 
	output reg [1:0] num          //num for diffirent slaver
	);
//slaver_cmd                          //not clock strech high repeatability single measuring cmd
localparam SHT30_CMD  = 35'b1000100_1_00100100_00000000_010000_110_00; //slave_addr、cmd_byte、i2c_cmd��?   
localparam BH1750_CMD = 35'b0100011_0_00000000_00100011_011000_010_01; //wait_time、data_byte、num  
//state                               //one time L_Resolution mode                                   
localparam WAIT = 6'd1;                                             
localparam SHT30 = 6'd2;                                             
localparam BH1750 = 6'd4;                                                 
//reg
reg [34:0] cmd;
reg [5:0] state;
reg [18:0] wait_cnt;//wait for cmd
reg [1:0] start_cnt;

//cnt--------------------------------------------------------------------
//wait_cnt
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		wait_cnt <= 16'd0;
	else if(state == WAIT)    
			wait_cnt <= wait_cnt + 16'd1;
	else
		wait_cnt <= 16'd0;
end
//start_cnt
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		start_cnt <= 2'd0;
	else if(state == WAIT)    
		start_cnt <= 2'd0;
	else begin
		if(start_cnt == 2'd3)begin
			if(i2c_ready)
				start_cnt <= start_cnt + 2'b1;
			else 
				start_cnt <= start_cnt;
		end else
			start_cnt <= start_cnt + 2'b1;
	end	
end

//i2c_startstart--------------------------------------------------------
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		i2c_start <= 1'b0;
	else begin
		if(start_cnt == 2'd1)
			i2c_start <= 1'b1;
		else if(start_cnt == 2'd2)
			i2c_start <= 1'b0;
		else
			i2c_start <= i2c_start;
	end	
end

//FSM-------------------------------------------------------------------
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		state <= WAIT;
	else begin
		case(state)
			WAIT:begin
				if(wait_cnt == 19'd400000)//turly for 400,40 is for tb!!!
					state <= SHT30;
				else
					state <= state;
			end
			SHT30:begin
				if((i2c_ready)&&(start_cnt == 2'd3))
					state <= BH1750;
				else
					state <= state;
			end
			BH1750:begin
				if((i2c_ready)&&(start_cnt == 2'd3))
					state <= WAIT;
				else
					state <= state;
			end
			default:state <= WAIT;
		endcase
	end
end
//cmd out 
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)begin
		cmd  <= 35'd0;
	end else begin
		case(state)
			WAIT:begin
				cmd <= 35'd0;
			end
			SHT30:begin
				cmd <= SHT30_CMD;
			end
			BH1750:begin
				cmd <= BH1750_CMD;
			end
			default:cmd <= 35'd0;
		endcase
	end
end			
			
//cmd to port------------------------------------------------
always @(*)begin
	if(!rst)begin
		slave_addr = 7'd0;               
		cmd_byte = 1'b1;               
		i2c_cmd = 16'b0;               
		wait_time = 6'd0;               
		data_byte = 3'd0;  
		num = 2'd0;
	end else begin
		slave_addr = cmd[34:28] ;
		cmd_byte = cmd[27] ;
		i2c_cmd = cmd[26:11] ;
		wait_time = cmd[10:5];
		data_byte = cmd[4:2];
		num = cmd[1:0];
	end
end

endmodule
		