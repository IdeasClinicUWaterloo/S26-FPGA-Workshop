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
  logic signed [15:0] formatted_audio16;
  assign formatted_audio16 = ($signed({4'b0000, raw_audio}) - 16'sd1650) <<< 5;

  logic signed [15:0] echo_audio16;

  echo u_echo (
    .clk(clk_50),
    .reset(reset),
    .data_in(formatted_audio16),
    .data_valid(raw_valid),
    .data_out(echo_audio16)
  );

  always @(posedge clk_50) begin
    if (sw0) begin
      audio_ready <= raw_valid;
      out_audio16 <= echo_audio16;
      out_audio24 <= ({{8{echo_audio16[15]}}, echo_audio16}) <<< 8;
    end else begin
      audio_ready <= raw_valid;
      out_audio16 <= formatted_audio16;
      out_audio24 <= ({{8{formatted_audio16[15]}}, formatted_audio16}) <<< 8;
    end
  end

endmodule
