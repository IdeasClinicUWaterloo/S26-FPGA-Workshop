module second_order_filter #(
    parameter int WIDTH = 16,

    // coefficients scaled by 2^15
    parameter logic signed [19:0] B0 = 20'sd0,
    parameter logic signed [19:0] B1 = 20'sd0,
    parameter logic signed [19:0] B2 = 20'sd0,
    parameter logic signed [19:0] A1 = 20'sd0,
    parameter logic signed [19:0] A2 = 20'sd0
) (
    input logic clk,
    input logic reset,
    input logic x_valid,
    input logic signed [WIDTH-1:0] x,
    output logic signed [WIDTH-1:0] y,
    output logic y_valid
);

  // ------------------------------------------------------------------
  // Internal signals and registers
  // ------------------------------------------------------------------

  localparam int COEF_W = 20;
  localparam int PROD_W = WIDTH + COEF_W;
  localparam int ACC_W = PROD_W + 3;

  // previous samples
  logic signed [WIDTH-1:0] x1, x2;
  logic signed [WIDTH-1:0] y1, y2;

  // multiply terms
  logic signed [PROD_W-1:0] b0_mult, b1_mult, b2_mult;
  logic signed [PROD_W-1:0] a1_mult, a2_mult;

  logic signed [ACC_W-1:0] y_raw;
  logic signed [WIDTH-1:0] y_next;

  // ------------------------------------------------------------------
  // Sequential logic
  // ------------------------------------------------------------------

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin

    end else if (x_valid) begin

    end else begin

    end
  end

endmodule
