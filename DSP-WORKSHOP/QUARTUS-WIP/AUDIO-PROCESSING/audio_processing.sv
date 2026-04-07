module audio_processing (
    input logic clk_50,
    input logic reset,
    input logic [9:0] sw,
    input logic signed [15:0] in_audio,
    input logic in_valid,
    output logic signed [15:0] out_audio,
    output logic out_ready
);
  logic signed [15:0]
      formatted_audio16, filtered_audio16, modulated_audio16, test_audio16, echo_audio16, echo_audio162;
  logic filtered_valid;

  test_signal u_test_signal (
    .clk(clk_50),
    .reset(reset),
    .sample_valid(in_valid),
    .out_signal(test_audio16)
  );

  echo u_echo (
      .clk(clk_50),
      .reset(reset),
      .data_in(test_audio16),
      .data_valid(in_valid),
      .data_out(echo_audio16)
  );

  echo u_echo2 (
      .clk(clk_50),
      .reset(reset),
      .data_in(in_audio),
      .data_valid(in_valid),
      .data_out(echo_audio162)
  );


  robotic u_robotic (
      .clk(clk_50),
      .reset(reset),
      .data_in(in_audio),
      .data_valid(in_valid),
      .data_out(modulated_audio16)
  );

  // BPF
  fourth_order_filter #(
      .STAGE1_B0(20'sd308),
      .STAGE1_B1(20'sd499),
      .STAGE1_B2(20'sd308),
      .STAGE1_A1(-20'sd58506),
      .STAGE1_A2(20'sd27672),

      // Section 2: Unity b0
      .STAGE2_B0(20'sd32768),
      .STAGE2_B1(-20'sd65536), 
      .STAGE2_B2(20'sd32768),
      .STAGE2_A1(-20'sd63943),
      .STAGE2_A2(20'sd31320)
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
    out_audio <= in_audio;

    if (sw[0]) begin
      out_ready <= in_valid;
      out_audio <= echo_audio16;
    end

    if (sw[1]) begin
      out_ready <= in_valid;
      out_audio <= modulated_audio16;
    end

    if (sw[2]) begin
      out_ready <= filtered_valid;
      out_audio <= filtered_audio16;
    end

    if (sw[3]) begin
      out_ready <= in_valid;
      out_audio <= test_audio16;
    end

    if (sw[4]) begin
      out_ready <= in_valid;
      out_audio <= echo_audio162 >>> 1;
    end

    if (sw[5]) begin
      out_ready <= in_valid;
      out_audio <= in_audio >>> 2;
    end
  end

endmodule
