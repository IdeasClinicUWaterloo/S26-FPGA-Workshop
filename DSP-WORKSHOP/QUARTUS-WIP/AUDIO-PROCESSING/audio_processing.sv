module audio_processing (
    input logic clk_50,
    input logic bclk,
    input logic reset,
    input logic sw0,
    input logic signed [11:0] raw_audio,
    input logic raw_valid,
    output logic signed [15:0] out_audio16,
    output logic signed [23:0] out_audio24,
    output logic audio_ready
);
  logic signed [15:0] formatted_audio16, filtered_audio16, modulated_audio16, echo_audio16;
  logic filtered_valid;

  assign formatted_audio16 = ($signed({4'b0000, raw_audio}) - 16'sd1650) <<< 5;

  // Highpass filter to get rid of low frequencies
  fourth_order_filter #(
      .STAGE1_B0(20'sd13702),
      .STAGE1_B1(-20'sd27405),
      .STAGE1_B2(20'sd13702),
      .STAGE1_A1(-20'sd33333),
      .STAGE1_A2(20'sd9204),

      .STAGE2_B0(20'sd32768),
      .STAGE2_B1(-20'sd65536),
      .STAGE2_B2(20'sd32768),
      .STAGE2_A1(-20'sd42227),
      .STAGE2_A2(20'sd20403),
      ) hpf (
      .clk  (clk_50),
      .reset(reset),

      .x(formatted_audio16),
      .x_valid(raw_valid),

      .y(filtered_audio16),
      .y_valid(filtered_valid)
  );

  always @(posedge clk_50) begin
    if (sw0) begin
      audio_ready <= filtered_valid;
      out_audio16 <= filtered_audio16;
      out_audio24 <= ({{8{filtered_audio16[15]}}, filtered_audio16}) <<< 8;
    end else begin
      audio_ready <= raw_valid;
      out_audio16 <= formatted_audio16;
      out_audio24 <= ({{8{formatted_audio16[15]}}, formatted_audio16}) <<< 8;
    end
  end

endmodule
