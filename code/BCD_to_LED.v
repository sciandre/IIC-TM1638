module BCD_to_LED (
	input wire clk,
	input wire rst,
	input wire [3:0] BCD,
	output reg [7:0] LED
);

//common cathode
always @(posedge clk or negedge rst)begin
	if(!rst)
		LED <= 8'b00111111;
	else
	case(BCD)
		4'd0: LED <= 8'b00111111;
		4'd1: LED <= 8'b00000110;
		4'd2: LED <= 8'b01011011;
		4'd3: LED <= 8'b01001111;
		4'd4: LED <= 8'b01100110;
		4'd5: LED <= 8'b01101101;
		4'd6: LED <= 8'b01111101;
		4'd7: LED <= 8'b00000111;
		4'd8: LED <= 8'b01111111;
		4'd9: LED <= 8'b01101111;
		default: LED <= 8'b00111111;
	endcase
end
endmodule