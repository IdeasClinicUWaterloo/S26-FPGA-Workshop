module fourth_order_bpf #(
    parameter SAMPLE_WIDTH = 16
) (
    input logic clk,
    input logic reset,
    input logic signed [SAMPLE_WIDTH - 1:0] data_in,
	 input logic data_valid,
    output logic signed [SAMPLE_WIDTH - 1:0] data_out
);

  localparam signed [15:0] GAIN = 16'sd606;

  logic signed [SAMPLE_WIDTH-1:0] intermediate, y_stage2;
  logic signed [31:0] gain_mult;

  assign gain_mult = y_stage2 * GAIN;
  assign data_out  = gain_mult >>> 14;

  second_order_bpf #(
      .WIDTH(SAMPLE_WIDTH),
      .B0(16'sd16384),
      .B1(-16'sd32767),
      .B2(16'sd16384),
      .A1(-16'sd23105),
      .A2(16'sd9293)
  ) stage1 (
      .clk(clk),
      .reset(reset),
      .x(data_in),
		.data_valid(data_valid),
      .y(intermediate)
  );

  second_order_bpf #(
      .WIDTH(SAMPLE_WIDTH),
      .B0(16'sd16384),
      .B1(16'sd32767),
      .B2(16'sd16384),
      .A1(-16'sd31805),
      .A2(16'sd15453)
  ) stage2 (
      .clk(clk),
      .reset(reset),
	  .data_valid(data_valid),
      .x(intermediate),
      .y(y_stage2)
  );
endmodule
