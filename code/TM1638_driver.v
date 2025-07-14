module TM1638_driver(
	input wire clk_400KHz,
	input wire clk,
	input wire rst,
	input wire [15:0] bin,
	input wire [1:0] flag,
	inout wire DIO,
	output reg  STB,
	output wire [2:0] mod
);
//wire & reg
wire [15:0] BCD;
wire [31:0] LED;
reg [31:0] LED_reg;
wire [7:0] flag_LED_wire;
reg [7:0] flag_LED_reg;
reg [8:0] state;
reg [5:0] cnt_bit;
reg [31:0] key_data;
reg dio_dir;
wire dio_in;
reg dio_out;
//state
parameter IDLE = 9'b000000001;
parameter CMD_KEY = 9'b000000010;      //read key data
parameter CMD_TUBE = 9'b000000100;      //fixed address mode
parameter C0H_DATA = 9'b000001000; 
parameter C8H_DATA = 9'b000010000;
parameter CAH_DATA = 9'b000100000;
parameter CCH_DATA = 9'b001000000;
parameter CEH_DATA = 9'b010000000;
parameter CMD_SHOW = 9'b100000000;      //display on mode
//cmd & addr
parameter READ_KEY_MODE  = 8'b0100_0010;    //read key data
parameter FIXED_ADD_MODE = 8'b0100_0100;    //fixed address mode
parameter DISPLAY_MODE = 8'b1000_1000;    //display on mode
parameter C0H_ADDR = 8'b1100_0000;
parameter C8H_ADDR = 8'b1100_1000;
parameter CAH_ADDR = 8'b1100_1010;
parameter CCH_ADDR = 8'b1100_1100;
parameter CEH_ADDR = 8'b1100_1110;

assign DIO = dio_dir? dio_out : 1'bz;
assign dio_in = DIO; 
//cnt_bit
always @(posedge clk_400KHz or negedge rst)begin
	if(!rst)
		cnt_bit <= 6'd0;
	else  if(state == IDLE)
		cnt_bit <= 6'd0;
	else if(state == CMD_KEY)
	begin
		if(cnt_bit == 6'd40)
			cnt_bit <= 6'd0;
		else
			cnt_bit <= cnt_bit + 6'd1;
	end
	else if((state == CMD_TUBE)||(state == CMD_SHOW))
	begin
		if(cnt_bit == 6'd8)
			cnt_bit <= 6'd0;
		else
			cnt_bit <= cnt_bit + 6'd1;
	end
	else if( (state == C0H_DATA)||(state == C8H_DATA)||(state == CAH_DATA)||
			 (state == CCH_DATA)||(state == CEH_DATA) )
	begin
		if(cnt_bit == 6'd16)
			cnt_bit <= 6'd0;
		else
			cnt_bit <= cnt_bit + 6'd1;
	end
	else
		cnt_bit <= 6'd0;
end

//FSM---------------------------------------
//state change
always @(posedge clk_400KHz or negedge rst)begin
	if(!rst)
		state <= IDLE;
	else
	case(state)
		IDLE:begin
			state <= CMD_KEY;
		end
		CMD_KEY:begin
			if(cnt_bit == 6'd40)
				state <= CMD_TUBE;
			else
				state <= state;
		end
		CMD_TUBE:begin 
			if(cnt_bit == 6'd8)
				state <= C0H_DATA;
			else
				state <= state;		
		end
		C0H_DATA:begin 
			if(cnt_bit == 6'd16)
				state <= CEH_DATA;
			else
				state <= state;	
		end
		CEH_DATA:begin 
			if(cnt_bit == 6'd16)
				state <= CCH_DATA;
			else
				state <= state;
		end
        CCH_DATA:begin 
			if(cnt_bit == 6'd16)
				state <= CAH_DATA;
			else
				state <= state;
		end
        CAH_DATA:begin 
			if(cnt_bit == 6'd16)
				state <= C8H_DATA;
			else
				state <= state;
	end
		C8H_DATA:begin 
			if(cnt_bit == 6'd16)
				state <= CMD_SHOW;
			else
				state <= state;
		end
        CMD_SHOW:begin 
			if(cnt_bit == 6'd8)
				state <= IDLE;
			else
				state <= state;		
		end
		default: state <= IDLE;
	endcase
end
//out
always @(negedge clk_400KHz or negedge rst)begin
	if(!rst)
	begin
		STB <= 1'b1;
		dio_dir <= 1'b1;
		dio_out <= 1'b1;
		LED_reg <= 32'b00111111_00111111_00111111_00111111;
		key_data <= 32'd0;
	end
	else
	case(state)
		IDLE:begin
			STB <= 1'b1;
			dio_out <= 1'b1;
			LED_reg <= LED;
			flag_LED_reg <= flag_LED_wire;
		end
		CMD_KEY:begin 
			if(cnt_bit == 6'd40)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else
			begin
				STB <= 1'b0;
				if(cnt_bit < 6'd8)
					dio_out <= READ_KEY_MODE[cnt_bit];
				else
				begin
					dio_dir <= 1'b0;
					key_data[cnt_bit - 6'd9] <= dio_in;
				end
			end
		end
		CMD_TUBE:begin 
			if(cnt_bit == 6'd8)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else
			begin
				dio_dir <= 1'b1;
				STB <= 1'b0;
			    dio_out <= FIXED_ADD_MODE[cnt_bit];
			end
		end
		C0H_DATA:begin 
			if(cnt_bit == 6'd16)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else 
			begin
				STB <= 1'b0;
				if(cnt_bit < 6'd8)
					dio_out <= C0H_ADDR[cnt_bit];
				else
					dio_out <= flag_LED_reg[cnt_bit - 6'd8];  //flag_LED_reg 0~7
			end	
		end
		CEH_DATA:begin 
			if(cnt_bit == 6'd16)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else 
			begin
				STB <= 1'b0;
				if(cnt_bit < 6'd8)
					dio_out <= CEH_ADDR[cnt_bit];
				else
					dio_out <= LED_reg[cnt_bit - 6'd8];  //LED_reg 0~7
			end	
		end
		CCH_DATA:begin 
			if(cnt_bit == 6'd16)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else 
			begin
				STB <= 1'b0;
				if(cnt_bit < 6'd8)
					dio_out <= CCH_ADDR[cnt_bit];
				else
					dio_out <= LED_reg[cnt_bit];  //LED_reg 8~15
			end	
		end
        CAH_DATA:begin 
			if(cnt_bit == 6'd16)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else 
			begin
				STB <= 1'b0;
				if(cnt_bit < 6'd8)
					dio_out <= CAH_ADDR[cnt_bit];
				else
					dio_out <= LED_reg[cnt_bit + 6'd8];  //LED_reg 16~23
			end
		end
        C8H_DATA:begin 
			if(cnt_bit == 6'd16)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else 
			begin
				STB <= 1'b0;
				if(cnt_bit < 6'd8)
					dio_out <= C8H_ADDR[cnt_bit];
				else
					dio_out <= LED_reg[cnt_bit + 6'd16];  //LED_reg 24~31
			end
		end
        CMD_SHOW:begin 
			if(cnt_bit == 6'd8)
			begin
				STB <= 1'b1;
				dio_out <= 1'b1;
			end
			else
			begin
				STB <= 1'b0;
			    dio_out <= DISPLAY_MODE[cnt_bit];
			end	
		end
		default: 
			begin
				STB     <= 1'b1;
				dio_out     <= 1'b1;
			end
		endcase
end

assign mod[0] = (key_data[7:0])? 1'b1: 1'b0;
assign mod[1] = (key_data[15:8])? 1'b1: 1'b0;
assign mod[2] = (key_data[23:16])? 1'b1: 1'b0;

endmodule