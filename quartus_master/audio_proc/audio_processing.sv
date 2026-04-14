module audio_processing (
    input logic clk_50,
    input logic reset,
    input logic [9:0] sw,
    input logic signed [15:0] in_audio,
    input logic in_valid,
    output logic signed [15:0] out_audio,
    output logic out_ready
);

  // ------------------------------------------------------------------
  // Internal signals and registers
  // ------------------------------------------------------------------

  logic signed [15:0] lower_vol_audio, modulated_audio, echo_audio, lpf_audio, bsf_audio;
  logic signed [15:0] stage0_audio, stage1_audio, stage2_audio, stage3_audio; 
  logic stage0_valid, stage1_valid, stage2_valid; 
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

  // Stage 1: Robotic Voice Effect (Ring Modulation)
  robotic u_modulated (
    .clk(clk_50),
    .reset(reset),
    .data_in(stage0_audio),
    .data_valid(stage0_valid),
    .data_out(modulated_audio)
  );

  // Dampen constant tone from voice effect
  fourth_order_filter #(
    // Stage 1
    .STAGE1_B0(20'sd28484), .STAGE1_B1(-20'sd57329), .STAGE1_B2(20'sd28860),
    .STAGE1_A1(-20'sd64335), .STAGE1_A2(20'sd31621),

    // Stage 2
    .STAGE2_B0(20'sd32768), .STAGE2_B1(-20'sd65092), .STAGE2_B2(20'sd32341),
    .STAGE2_A1(-20'sd65282), .STAGE2_A2(20'sd32516)
  ) u_bsf (
    .clk  (clk_50),
    .reset(reset),
    .x(modulated_audio),
    .x_valid(stage0_valid),
    .y(bsf_audio),
    .y_valid(bsf_valid)
  );

  assign stage1_audio = sw[1] ? bsf_audio : stage0_audio;
  assign stage1_valid = sw[1] ? bsf_valid : stage0_valid;

  //Stage 2: Echoes
  echo u_echoes(
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
    // Stage 1
    .STAGE1_B0(20'sd209), .STAGE1_B1(20'sd263), .STAGE1_B2(20'sd209),
    .STAGE1_A1(-20'sd49832), .STAGE1_A2(20'sd20665),

    // Stage 2
    .STAGE2_B0(20'sd32768), .STAGE2_B1(-20'sd7142), .STAGE2_B2(20'sd32768),
    .STAGE2_A1(-20'sd48390), .STAGE2_A2(20'sd28034)
  ) u_lpf (
    .clk  (clk_50),
    .reset(reset),
    .x(stage2_audio),
    .x_valid(stage2_valid),
    .y(lpf_audio),
    .y_valid(lpf_valid)
  );

  assign stage3_audio = sw[3] ? lpf_audio : stage2_audio;
  assign stage3_valid = sw[3] ? lpf_valid : stage2_valid;

  assign out_audio = stage3_audio;
  assign out_ready = stage3_valid;

endmodule