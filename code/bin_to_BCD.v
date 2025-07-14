module bin_to_BCD(
	input wire clk,
	input wire rst,
	input wire [15:0] bin,
	output reg [15:0] BCD
);

reg [31:0] shift_reg;
reg [4:0] shift_cnt;

always @(negedge clk or negedge rst)begin
	if(!rst)
		shift_cnt <= 4'd0;
	else
		shift_cnt <= shift_cnt + 4'd1;
end

always @(posedge clk or negedge rst)begin
	if(!rst)
		shift_reg <= 32'd0;
	else
	begin
		if(shift_cnt == 5'd0)
		begin
			shift_reg <= {12'd0,bin};
			BCD <= shift_reg[31:16] ;
		end
		else if((shift_cnt == 5'd2 )||(shift_cnt == 5'd4 )||(shift_cnt == 5'd6 )||(shift_cnt == 5'd8 )||(shift_cnt == 5'd10)||
				(shift_cnt == 5'd12)||(shift_cnt == 5'd14)||(shift_cnt == 5'd16)||(shift_cnt == 5'd18)||(shift_cnt == 5'd20)||
				(shift_cnt == 5'd22)||(shift_cnt == 5'd24)||(shift_cnt == 5'd26)||(shift_cnt == 5'd28)||(shift_cnt == 5'd30))
		begin
			if(shift_reg[19:16] > 4)
				shift_reg[19:16] <= shift_reg[19:16] + 4'd3;
			if(shift_reg[23:20] > 4)
				shift_reg[23:20] <= shift_reg[23:20] + 4'd3;
			if(shift_reg[27:24] > 4)
				shift_reg[27:24] <= shift_reg[27:24] + 4'd3;
		end
		else if((shift_cnt == 5'd1 )||(shift_cnt == 5'd3 )||(shift_cnt == 5'd5 )||(shift_cnt == 5'd7 )||(shift_cnt == 5'd9 )||
				(shift_cnt == 5'd11)||(shift_cnt == 5'd13)||(shift_cnt == 5'd15)||(shift_cnt == 5'd17)||(shift_cnt == 5'd19)||
				(shift_cnt == 5'd21)||(shift_cnt == 5'd23)||(shift_cnt == 5'd25)||(shift_cnt == 5'd27)||(shift_cnt == 5'd29)||
				(shift_cnt ==5'd31))
			shift_reg <= shift_reg << 1;
	end
end

endmodule

