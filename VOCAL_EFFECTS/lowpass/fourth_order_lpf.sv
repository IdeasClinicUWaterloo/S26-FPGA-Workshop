module fourth_order_lpf #(
    parameter SAMPLE_WIDTH = 16
) (
    input logic clk,
    input logic reset,
    input logic signed [SAMPLE_WIDTH - 1:0] data_in,
    input logic data_valid,
    output logic signed [SAMPLE_WIDTH - 1:0] data_out
);

  localparam signed [19:0] GAIN = 20'sd800;

  logic signed [SAMPLE_WIDTH-1:0] intermediate, y_stage2;
  logic signed [35:0] gain_mult;

  assign gain_mult = y_stage2 * GAIN;
  assign data_out = gain_mult >>> 18;

  second_order_lpf #(
      .WIDTH(SAMPLE_WIDTH),
      .B0(20'sd262144),
      .B1(20'sd524367),
      .B2(20'sd262223),
      .A1(-20'sd471229),
      .A2(20'sd212179)
  ) stage1 (
      .clk(clk),
      .reset(reset),
      .data_valid(data_valid),
      .x(data_in),
      .y(intermediate)
  );

  second_order_lpf #(
      .WIDTH(SAMPLE_WIDTH),
      .B0(20'sd262144),
      .B1(20'sd524065),
      .B2(20'sd262065),
      .A1(-20'sd499097),
      .A2(20'sd240228)
  ) stage2 (
      .clk(clk),
      .reset(reset),
      .data_valid(data_valid),
      .x(intermediate),
      .y(y_stage2)
  );
endmodule
