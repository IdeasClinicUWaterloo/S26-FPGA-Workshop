module fourth_order_filter #(
    parameter int SAMPLE_WIDTH = 16,

    // =====================
    // STAGE 1
    // =====================
    parameter logic signed [19:0] STAGE1_B0 = 20'sd0,
    parameter logic signed [19:0] STAGE1_B1 = 20'sd0,
    parameter logic signed [19:0] STAGE1_B2 = 20'sd0,
    parameter logic signed [19:0] STAGE1_A1 = 20'sd0,
    parameter logic signed [19:0] STAGE1_A2 = 20'sd0,

    // =====================
    // STAGE 2
    // =====================
    parameter logic signed [19:0] STAGE2_B0 = 20'sd0,
    parameter logic signed [19:0] STAGE2_B1 = 20'sd0,
    parameter logic signed [19:0] STAGE2_B2 = 20'sd0,
    parameter logic signed [19:0] STAGE2_A1 = 20'sd0,
    parameter logic signed [19:0] STAGE2_A2 = 20'sd0
) (
    input logic clk,
    input logic reset,
    input logic signed [SAMPLE_WIDTH-1:0] x,
    input logic x_valid,
    output logic signed [SAMPLE_WIDTH-1:0] y,
    output logic y_valid
);

  logic y_stage1_valid;
  logic signed [SAMPLE_WIDTH-1:0] y_stage1, y_stage2;

  second_order_filter #(
      .WIDTH(SAMPLE_WIDTH),
      .B0(STAGE1_B0),
      .B1(STAGE1_B1),
      .B2(STAGE1_B2),
      .A1(STAGE1_A1),
      .A2(STAGE1_A2)
  ) stage1 (
      .clk(clk),
      .reset(reset),
      .x(x),
      .x_valid(x_valid),
      .y(y_stage1),
      .y_valid(y_stage1_valid)
  );

  second_order_filter #(
      .WIDTH(SAMPLE_WIDTH),
      .B0(STAGE2_B0),
      .B1(STAGE2_B1),
      .B2(STAGE2_B2),
      .A1(STAGE2_A1),
      .A2(STAGE2_A2)
  ) stage2 (
      .clk(clk),
      .reset(reset),
      .x(y_stage1),
      .x_valid(y_stage1_valid),
      .y(y_stage2),
      .y_valid(y_valid)
  );

  assign y = y_stage2;
endmodule
