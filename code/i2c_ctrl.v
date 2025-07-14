(* keep_hierarchy = "yes" *) 
module i2c_ctrl         
   (            
    input wire i2c_clk, //  
    input wire rst,     	
	input wire i2c_start, //start signal
	input wire [6:0] slave_addr , //i2c slave addr,not include rd_wr
    input wire cmd_byte, //cmd byte ctrl (2byte/1byte)
	input wire [15:0] i2c_cmd, //cmd 
	input wire [5:0] wait_time, //the time of wait state,wait for measuring
    input wire [2:0] data_byte, //r_data byte
	input wire [1:0] num, //Select different addr for data based on the num.
	output reg i2c_ready, //i2c ready signal,indicating finish one collection.
    output reg scl,   
    inout wire sda,   
	input wire [2:0] mod, //choose tem/hum/illum to display
	output reg [15:0] bin, //Output the binary data after calculation
	output reg [1:0] flag 
     );
//localparam
localparam IDLE = 12'd1; 	
localparam START_1 = 12'd2; 	
localparam ADDR_W = 12'd4; //i2c slaver addr + w/r
localparam CMD_H = 12'd8; 		
localparam CMD_L = 12'd16;	
localparam STOP_1 = 12'd32; 
localparam WAIT = 12'd64;  
localparam START_2 = 12'd128;  
localparam ADDR_R = 12'd256;  
localparam DATA_R = 12'd512;  
localparam STOP_2 = 12'd1024; 
//three gate 
reg sda_dir; 
reg sda_out; 
wire sda_in; 
//state reg
reg [11:0] state; 
reg [11:0] next_state; 
//TS reg						 
reg [6:0] slave_addr_reg;             
reg [15:0] i2c_cmd_reg;            
reg [2:0] data_byte_reg;                       
reg [7:0] wait_time_reg;                      
reg cmd_byte_reg;
reg [1:0] num_reg;     
reg [7:0] data_reg;      
//cnt reg                            
reg [1:0] i2c_cnt; //Count the i2c i2c_clk in order to generate the scl signal 
reg [4:0] bit_cnt; //count the sda bin bit 
reg [2:0] byte_cnt; //count the r_data's byte
reg [15:0] wait_cnt; //count the waiting time at WAIT
//memory
reg [7:0] all_memory [31:0];  //inculde CRC data
reg [15:0] memory [3:0];  //just measure data
//bin
wire [15:0] tem_bin ;
wire [15:0] hum_bin ;
wire [15:0] illum_bin;

//ILA
wire [15:0] memory_ila_0;
wire [15:0] memory_ila_1;
wire [15:0] memory_ila_2;

assign memory_ila_0 = memory[0];
assign memory_ila_1 = memory[1];
assign memory_ila_2 = memory[2];

//three gate-----------------------------------------------------------------
assign sda = sda_dir ? sda_out : 1'bz;  
assign sda_in = sda;  

//i2c_clk-----------------------------------------------------------------------
//scl
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		scl <= 1'b1;
	else if( (state == IDLE  ) ||
			 (state == WAIT  ) )
		scl <= 1'b1;
	else if(state == STOP_1 || state ==STOP_2)
	begin
		if(i2c_cnt==2'd2)
			scl <= 1'b1;
	end 
	else if(state == START_1)
			scl <= 1'b0;
	else 
	begin	
		if(i2c_cnt == 2'd2)
			scl <= 1'b1;
		else if(i2c_cnt == 2'd0)
			scl <= 1'b0;
	end
end
		
//cnt--------------------------------------------------------------------
//i2c_cnt
always @(posedge i2c_clk or negedge rst) begin
    if(!rst)
        i2c_cnt <= 2'd0;
    else if(state==IDLE)
        i2c_cnt <= 2'd0;
	else
		i2c_cnt <= i2c_cnt + 2'd1;
end
//bit_cnt
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		bit_cnt <= 4'd0;
	else if((state==ADDR_W) ||
			(state==CMD_H)  || 
			(state==CMD_L)  ||
			(state==ADDR_R) ||
			(state==DATA_R ) )begin
		if( (bit_cnt < 4'd8) && (i2c_cnt == 2'd0) )
			bit_cnt <= bit_cnt + 4'd1;
		if( (bit_cnt == 4'd8) && (i2c_cnt == 2'd0) )
			bit_cnt <= 4'd0;
	end else
		bit_cnt <= 4'd0;
end	
//byte_cnt
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		byte_cnt <= 3'd0;
	else if(state == DATA_R)begin
		if( (bit_cnt == 4'd7) && (i2c_cnt == 2'd0) )
			byte_cnt <= byte_cnt + 3'd1;
	end else 
		byte_cnt <= 3'd0;
end
//wait_cnt
always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		wait_cnt <= 16'd0;
	else if(state == WAIT)begin
		if( i2c_cnt == 2'd3 )begin
			if(wait_cnt < 16'd100*wait_time_reg) //wait_time_reg(ms)
				wait_cnt <= wait_cnt + 16'd1;
			else
				wait_cnt <= 16'd0;
		end
	end 
	else
		wait_cnt <= 16'd0;
end
	
//fsm------------------------------------------------------------------------
//next state 
always @(posedge i2c_clk or negedge rst) begin
    if(!rst)
        state <= IDLE;
    else
        state <= next_state;
end
//state change
always @(*) begin
	if(!rst)
		next_state = IDLE;
    else case(state)
        IDLE: begin                          
           if(i2c_start) begin
               next_state = START_1;
           end else
               next_state = IDLE;
        end
		START_1:                               
               next_state = ADDR_W;
        ADDR_W: begin
            if( (sda_in==1'd0)&&(sda_dir==1'd0)&& (i2c_cnt==2'd0) ) begin
				if(cmd_byte_reg)
					next_state = CMD_H;
				else
					next_state = CMD_L;
            end else
                next_state = ADDR_W;
        end
        CMD_H: begin                        
            if( (sda_in==1'd0)&&(sda_dir==1'd0)&& (i2c_cnt==2'd0) )
                next_state = CMD_L;
            else begin
                next_state = CMD_H;
            end
        end
        CMD_L: begin                         
            if( (sda_in==1'd0)&&(sda_dir==1'd0)&& (i2c_cnt==2'd0) )
				next_state = STOP_1;		
            else 
                next_state = CMD_L;
        end
        STOP_1: begin                       
			if(i2c_cnt==2'd0)
				next_state = WAIT;
			else
				next_state = STOP_1;
		end
        WAIT: begin                       
            if((wait_cnt == 16'd100*wait_time_reg) && (i2c_cnt == 2'd3)) //turly 16'd100,16'd1 is for tb!!!
                next_state = START_2;
            else
                next_state = WAIT;
        end
        START_2:                      
                next_state = ADDR_R;
        ADDR_R: begin                          
            if( (sda_in==1'd0)&&(sda_dir==1'd0)&& (i2c_cnt==2'd0) )
                next_state = DATA_R;
			else if( (sda_in==1'd1)&&(sda_dir==1'd0)&& (i2c_cnt==2'd0) )
				next_state = STOP_1;
            else
                next_state = ADDR_R ;
        end
		DATA_R: begin                          
            if((i2c_cnt==2'd0) && (byte_cnt==data_byte_reg))
                next_state = STOP_2;
            else
                next_state = DATA_R ;
        end
		STOP_2: begin                          
            if(i2c_cnt == 2'd0)
                next_state = IDLE;
            else
                next_state = STOP_2 ;
        end
        default: begin
			next_state = IDLE;
		end
    endcase 
end
//out
always @(posedge i2c_clk or negedge rst) begin
    if(!rst) begin
        sda_out <= 1'b1;
        sda_dir <= 1'b1;       
        i2c_ready <= 1'b1;	
		data_reg <= 8'd0;		
		
		slave_addr_reg <= 7'd0;
		cmd_byte_reg <= 1'b1;                                                                                                                              
        i2c_cmd_reg <= 16'd0;                          
        wait_time_reg <= 6'b0; 
		data_byte_reg <= 3'd0;
		num_reg <= 2'd0;
    end                                              
    else begin                                                              
        case(state)                              
             IDLE: begin                                                                            
                if(i2c_start) begin                   
					data_byte_reg  <= data_byte;
                    i2c_cmd_reg <= i2c_cmd;       
					slave_addr_reg <= slave_addr;
					cmd_byte_reg <= cmd_byte;
                    wait_time_reg <= wait_time;   
					num_reg <= num;
					i2c_ready <= 1'd0;
					sda_out <= 1'b0;
				end else begin
					sda_out <= 1'b1;
					sda_dir <= 1'b1;
					i2c_ready <= 1'b1;
					data_reg <= 8'd0;	
					slave_addr_reg <= 7'd0;
					cmd_byte_reg <= 1'b1;
					i2c_cmd_reg <= 16'd0;
					wait_time_reg <= 6'b0;
					data_byte_reg <= 3'd0;
					num_reg <= 2'd0;
                end                                  
            end 

			START_1:;
			
            ADDR_W: begin
				if( (i2c_cnt == 2'd1) && (bit_cnt < 7) )
					sda_out <= slave_addr_reg[6 - bit_cnt];
                else if( (i2c_cnt == 2'd1) && (bit_cnt == 4'd7) )
					sda_out <= 1'd0;
				else if( (i2c_cnt == 2'd1) && (bit_cnt == 4'd8) )
					sda_dir <= 1'd0; 
				else if( (sda_dir==1'd0)&& (i2c_cnt==2'd0) ) 
					sda_dir <= 1'd1;				
            end 
            CMD_H: begin                         
				if( (i2c_cnt == 2'd1) && (bit_cnt < 8) )   
					sda_out <= i2c_cmd_reg[15 - bit_cnt];
				else if( (i2c_cnt == 2'd1) && (bit_cnt == 4'd8) )
					sda_dir <= 1'd0;
				else if( (sda_dir==1'd0)&& (i2c_cnt==2'd0) ) 
					sda_dir <= 1'd1;
            end                                      
            CMD_L: begin                          
                if( (i2c_cnt == 2'd1) && (bit_cnt < 8) )   
					sda_out <= i2c_cmd_reg[7 - bit_cnt];
				else if( (i2c_cnt == 2'd1) && (bit_cnt == 4'd8) )begin
					sda_dir <= 1'd0;
					sda_out <= 1'b0;
				end
				else if( (sda_dir==1'd0)&& (i2c_cnt==2'd0) ) 
					sda_dir <= 1'd1;                           
            end                                      
            STOP_1: begin  
				sda_dir <= 1'd1;
				if( i2c_cnt==2'd3 )
					sda_out <= 1'd1;                              
            end                                     
            WAIT:begin
				if((wait_cnt == 16'd100*wait_time_reg) && (i2c_cnt == 2'd3)) //turly 16'd100,16'd1 is for tb!!!
					sda_out <= 1'd0;
			end
            START_2: ;
			
            ADDR_R: begin
				if( (i2c_cnt == 2'd1) && (bit_cnt < 7) )
					sda_out <= slave_addr_reg[6 - bit_cnt];
                else if( (i2c_cnt == 2'd1) && (bit_cnt == 4'd7) )
					sda_out <= 1'd1;
				else if( (i2c_cnt == 2'd1) && (bit_cnt == 4'd8) )
				begin
					sda_dir <= 1'd0; 	
					if(sda_in)
						sda_out <= 1'b0;
				end
            end
			DATA_R: begin
				if( byte_cnt<data_byte_reg )begin
					if((i2c_cnt == 2'd3)&&(bit_cnt<4'd8))
						data_reg[7 - bit_cnt] <= sda_in;	
					else if((i2c_cnt == 2'd1)&&(bit_cnt == 4'd8))begin
						sda_dir <= 1'd1;
						sda_out <= 1'd0;
					end else if((i2c_cnt == 2'd1)&&(bit_cnt == 4'd0))
						sda_dir <= 1'd0;
				end else begin
					sda_dir <= 1'd1;
					sda_out <= 1'd1;
				end
            end
			STOP_2: begin 
				if(i2c_cnt == 2'd1)
					sda_out <= 1'd0;
				else if(i2c_cnt==2'd3)
					sda_out <= 1'd1;
				else if(i2c_cnt == 2'd0)
					i2c_ready <= 1'd1;
            end
        endcase
    end
end

//memory-------------------------------------------------------------------------
always @(posedge i2c_clk or negedge rst)begin:all_memory_initial
    integer i;
    integer j;
	if(!rst)begin
	    for( i = 0; i <= 31; i = i + 1 )
        begin
            all_memory[i] <= 8'd0;
        end
	end
	else if((state == DATA_R)&&(sda_dir == 1'd1)&&(i2c_cnt == 2'd2))begin
		case(num_reg)
			2'b00:begin
				all_memory[byte_cnt - 1] <= data_reg;
			end
			2'b01:begin
				all_memory[6 + byte_cnt - 1] <= data_reg;
			end
			default:begin
			     for( j = 0; j <= 31; j = j + 1 )
                begin
                    all_memory[j] <= 8'd0;
                end
			end
		endcase
	end
end

always @(posedge i2c_clk or negedge rst)begin:memory_initial
    integer i;
	if(!rst)begin
	    for( i = 0; i <= 2; i = i + 1 )
        begin
            memory[i] <= 16'd0;
        end
    end
	else begin
		memory[0] <= {all_memory[0],all_memory[1]};
		memory[1] <= {all_memory[3],all_memory[4]};
		memory[2] <= {all_memory[6],all_memory[7]};
	end
end
//outdata------------------------------------------------------------------------


always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		flag <= 2'b01;
	else if(mod == 3'b001)
		flag <= 2'b01;
	else if(mod == 3'b010)
		flag <= 2'b10;
	else if(mod == 3'b100)
		flag <= 2'b11;
	else
		flag <= flag;	
end

always @(posedge i2c_clk or negedge rst)begin
	if(!rst)
		bin <= 16'd0;
	else if(flag == 2'b01)
		bin <= tem_bin;
	else if(flag == 2'b10)
		bin <= hum_bin;
	else if(flag == 2'b11)
		bin <= illum_bin;
	else
		bin <= 16'd0;	
end

endmodule
