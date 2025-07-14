module dp_tem(
    input  wire clk,            
    input  wire rst,            
    input  wire [15:0] memory0, 
    output wire [15:0] tem_bin 
);

reg [47:0] shift1;        
reg [47:0] shift2;        
reg [47:0] shift3;        

//  T = -45 + 175*(S/2^16)
always @(negedge clk or negedge rst) begin
    if (!rst) 
	begin       
        shift1 <= 48'd0;
        shift2 <= 48'd0;
        shift3 <= 48'd0;
    end 
	else 
	begin
		shift1 <= {16'b0000_0000_0000_0000, memory0} << 16;  // expand
		shift2 <= (shift1 << 7) +    					     // *175
				(shift1 << 5) +    
				(shift1 << 3) +    
				(shift1 << 2) +    
				(shift1 << 1) +    
				shift1;      
		if(shift2 == 48'd0)
			shift3 <= 48'd0;														
		else															// /(2^16) - 45
			shift3 <= (shift2 >> 16)-{48'b0000_0000_0000_0000_0000_0000_0010_1101_0000_0000_0000_0000};  
    end                                                    
end

assign tem_bin = shift3[31:16]; 
 
endmodule