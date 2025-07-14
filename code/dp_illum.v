module dp_illum(
    input  wire clk,            
    input  wire rst,            
    input  wire [15:0] memory2, 
    output wire [15:0] illum_bin 
);

reg [47:0] shift1;         
reg [47:0] shift2;         
reg [47:0] shift3;         

// RH = S/1.2 = 425*S/512    425/512 ��? 1.2047
always @(negedge clk or negedge rst) begin
    if (!rst) 
	begin     
        shift1 <= 48'd0;
        shift2 <= 48'd0;
        shift3 <= 32'd0;
    end 
	else
	begin
		shift1 <= {16'b0000_0000_0000_0000, memory2} << 16;  // expand
		shift2 <= 425*shift1;
		shift3 <= (shift2 >> 9);
	end
end
	
assign illum_bin = shift3[31:16]; 

endmodule