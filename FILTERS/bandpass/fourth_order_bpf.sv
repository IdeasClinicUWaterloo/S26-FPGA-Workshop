module fourth_order_bpf #(
    parameter SAMPLE_WIDTH = 16
)(
    input logic clk,
    input logic reset,
    input logic signed [SAMPLE_WIDTH - 1:0] data_in,
    output logic signed [SAMPLE_WIDTH - 1:0] data_out
);

  logic signed [SAMPLE_WIDTH-1:0] intermediate;

  // Section 1
  second_order_bpf stage1 (
      .clk(clk),
      .reset(reset),
      .x(data_in),
      .y(intermediate)
  );

  // Section 2
  second_order_bpf stage2 (
      .clk(clk),
      .reset(reset),
      .x(intermediate),
      .y(data_out)
  );
endmodule
