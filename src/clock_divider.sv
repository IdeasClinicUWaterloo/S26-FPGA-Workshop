module clock_divider(
	input wire clk_in,
	input wire [8:0] divisor,
	output reg clk_out
);
	reg[8:0] counter=9'd0;
	
	always @(posedge clk_in)
	begin
	 counter <= counter + 9'd1;
	 if(counter>=(divisor-1)) begin
		counter <= 9'd0;
	 end else begin
		clk_out <= (counter<divisor/2)?1'b1:1'b0;
	 end
	end
	
endmodule