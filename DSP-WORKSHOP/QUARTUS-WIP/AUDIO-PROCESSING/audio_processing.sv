module audio_processing (
    input logic clk_50,
    input logic reset,
    input logic [9:0] sw,
    input logic signed [11:0] in_audio,
    input logic in_valid,
    output logic signed [15:0] out_audio16,
    output logic out_ready
);
  logic signed [15:0]
      formatted_audio16, filtered_audio16, modulated_audio16, test_audio16, echo_audio16;
  logic filtered_valid;

  test_signal u_test_signal (
    .clk(clk),
    .reset(reset),
    .out_signal16(test_audio16)
  );

  echo u_echo (
      .clk(clk_50),
      .reset(reset),
      .data_in(test_audio16),
      .data_valid(in_valid),
      .data_out(echo_audio16)
  );

  robotic u_ring_modulation (
      .clk(clk_50),
      .reset(reset),
      .data_in(in_audio),
      .data_valid(in_valid),
      .data_out(modulated_audio16)
  );

  // BPF
  fourth_order_filter #(
      // Section 1: Gain g folded, scaled by 2^15
      .STAGE1_B0(20'sd1142),
      .STAGE1_B1(20'sd1225),    // Note: This is positive in this run
      .STAGE1_B2(20'sd1142),
      .STAGE1_A1(-20'sd51094),
      .STAGE1_A2(20'sd22351),

      // Section 2: Unity b0, scaled by 2^15
      .STAGE2_B0(20'sd32768),
      .STAGE2_B1(-20'sd65536),  // Note: This is negative in this run
      .STAGE2_B2(20'sd32768),
      .STAGE2_A1(-20'sd65285),  // Extreme proximity to -65536 limit
      .STAGE2_A2(20'sd32519)
  ) u_filter (
      .clk  (clk_50),
      .reset(reset),

      .x(in_audio),
      .x_valid(in_valid),

      .y(filtered_audio16),
      .y_valid(filtered_valid)
  );

  always @(posedge clk_50) begin
    out_ready <= in_valid;
    out_audio16 <= in_audio;

    if (sw[0]) begin
      out_ready <= in_valid;
      out_audio16 <= echo_audio16;
    end

    if (sw[1]) begin
      out_ready <= in_valid;
      out_audio16 <= modulated_audio16;
    end

    if (sw[2]) begin
      out_ready <= filtered_audio16;
      out_audio16 <= filtered_audio16;
    end

    if (sw[3]) begin
      out_ready <= in_valid;
      out_audio16 <= test_audio16;
    end
  end

endmodule
