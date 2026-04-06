module second_order_filter #(
    parameter int WIDTH = 16,

    // coefficients scaled by 2^18
    parameter logic signed [19:0] B0 = 20'sd0,
    parameter logic signed [19:0] B1 = 20'sd0,
    parameter logic signed [19:0] B2 = 20'sd0,
    parameter logic signed [19:0] A1 = 20'sd0,
    parameter logic signed [19:0] A2 = 20'sd0
) (
    input logic clk,
    input  logic reset,
    input  logic x_valid,
    input  logic signed [WIDTH-1:0] x,
    output logic signed [WIDTH-1:0] y,
	 output logic y_valid
);

  localparam int COEF_W = 20;
  localparam int PROD_W = WIDTH + COEF_W;
  localparam int ACC_W = PROD_W + 3;

  // previous samples
  logic signed [WIDTH-1:0] x1, x2;
  logic signed [WIDTH-1:0] y1, y2;

  // multiply terms
  logic signed [PROD_W-1:0] b0_mult, b1_mult, b2_mult;
  logic signed [PROD_W-1:0] a1_mult, a2_mult;

  // accumulator and next output
  logic signed [ACC_W-1:0] y_raw;
  logic signed [WIDTH-1:0] y_next;

  assign b0_mult = x * B0;
  assign b1_mult = x1 * B1;
  assign b2_mult = x2 * B2;
  assign a1_mult = y1 * A1;
  assign a2_mult = y2 * A2;

  assign y_raw   = b0_mult + b1_mult + b2_mult - a1_mult - a2_mult;
  assign y_next  = y_raw[18 +: WIDTH];

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
		y_valid <= '0;
      x1 <= '0;
      x2 <= '0;
      y1 <= '0;
      y2 <= '0;
      y  <= '0;
    end else if(x_valid) begin
      y  <= y_next;
      x2 <= x1;
      x1 <= x;
      y2 <= y1;
      y1 <= y_next;
		
		y_valid <= 1'b1;
    end else begin
		y_valid <= 1'b0;
	 end
  end

endmodule
