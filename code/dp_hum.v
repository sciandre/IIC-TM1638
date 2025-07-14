module dp_hum(
    input  wire clk,              
    input  wire rst,            
    input  wire [15:0] memory1,  
    output wire [15:0] hum_bin 
);

reg [47:0] shift1;         
reg [47:0] shift2;         
reg [47:0] shift3;         

// RH = 100*(S/2^16)
always @(negedge clk or negedge rst) begin
    if (!rst) 
	begin     
        shift1 <= 48'd0;
        shift2 <= 48'd0;
        shift3 <= 32'd0;
    end 
	else
	begin
        shift1 <= {16'b0000_0000_0000_0000, memory1} << 16;  // expand
        shift2 <= shift1*32'd100;                            // *100
        shift3 <= (shift2 >> 16)  ;                          // /2^16                      
    end
end

assign hum_bin = shift3[31:16];  

endmodule