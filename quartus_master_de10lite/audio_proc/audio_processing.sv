module audio_processing (
    input  logic              clk_50,
    input  logic              reset,
    input  logic [9:0]        sw,
    input  logic signed [15:0] in_audio,
    input  logic              in_valid,
    output logic signed [15:0] out_audio,
    output logic              out_ready
);

  // ------------------------------------------------------------------
  // Internal signals and registers
  // ------------------------------------------------------------------

  logic signed [15:0] lower_vol_audio, modulated_audio, echo_audio;
  logic signed [15:0] lpf_audio, bsf_audio, modulated_raw_audio;
  logic signed [15:0] stage0_audio, stage1_audio, stage2_audio, stage3_audio, stage4_audio;

  logic stage0_valid, stage1_valid, stage2_valid, stage3_valid, stage4_valid;
  logic lpf_valid, bsf_valid;

  // ------------------------------------------------------------------
  // Modules: Cascaded voice effects
  // ------------------------------------------------------------------

  // Stage 0: Lower Volume
  lower_volume u_vol (
    .clk(clk_50),
    .reset(reset),
    .data_in(in_audio),
    .data_valid(in_valid),
    .data_out(lower_vol_audio)
  );

  assign stage0_audio = sw[0] ? lower_vol_audio : in_audio;
  assign stage0_valid = in_valid;

  // Stage 1: Robotic Voice Effect (Ring Modulation) with BSF
  robotic u_modulated (
    .clk(clk_50),
    .reset(reset),
    .data_in(stage0_audio),
    .data_valid(stage0_valid),
    .data_out(modulated_audio)
  );

  // Dampen constant tone from voice effect BSF (185 - 195 Hz)
  fourth_order_filter #(
    .STAGE1_B0(20'sd29176), .STAGE1_B1(-20'sd58334), .STAGE1_B2(20'sd29176),
    .STAGE1_A1(-20'sd65481), .STAGE1_A2(20'sd32735),

    .STAGE2_B0(20'sd32768), .STAGE2_B1(-20'sd65515), .STAGE2_B2(20'sd32768),
    .STAGE2_A1(-20'sd65486), .STAGE2_A2(20'sd32737)
  ) u_bsf (
    .clk(clk_50),
    .reset(reset),
    .x(modulated_audio),
    .x_valid(stage0_valid),
    .y(bsf_audio),
    .y_valid(bsf_valid)
  );

  assign stage1_audio = sw[1] ? bsf_audio : stage0_audio;
  assign stage1_valid = sw[1] ? bsf_valid : stage0_valid;

  // Stage 2: Echoes
  echo u_echoes (
    .clk(clk_50),
    .reset(reset),
    .data_in(stage1_audio),
    .data_valid(stage1_valid),
    .data_out(echo_audio)
  );

  assign stage2_audio = sw[2] ? echo_audio : stage1_audio;
  assign stage2_valid = stage1_valid;

  // Stage 3: Low-pass (muffled voice)
  fourth_order_filter #(
    .STAGE1_B0(20'sd84),     .STAGE1_B1(20'sd34),      .STAGE1_B2(20'sd84),
    .STAGE1_A1(-20'sd56338), .STAGE1_A2(20'sd24935),

    .STAGE2_B0(20'sd32768),  .STAGE2_B1(-20'sd37190),  .STAGE2_B2(20'sd32768),
    .STAGE2_A1(-20'sd57785), .STAGE2_A2(20'sd29712)
  ) u_lpf (
    .clk(clk_50),
    .reset(reset),
    .x(stage2_audio),
    .x_valid(stage2_valid),
    .y(lpf_audio),
    .y_valid(lpf_valid)
  );

  assign stage3_audio = sw[3] ? lpf_audio : stage2_audio;
  assign stage3_valid = sw[3] ? lpf_valid : stage2_valid;

  // Stage 4: Robotic Voice Effect (Ring Modulation) without BSF
  robotic u_modulate_raw (
    .clk(clk_50),
    .reset(reset),
    .data_in(stage3_audio),
    .data_valid(stage3_valid),
    .data_out(modulated_raw_audio)
  );

  assign stage4_audio = sw[4] ? modulated_raw_audio : stage3_audio;
  assign stage4_valid = stage3_valid;

  assign out_audio = stage4_audio;
  assign out_ready = stage4_valid;

endmodule