module modulation #(
    parameter SAMPLE_WIDTH = 16,
    parameter LUT_SIZE = 1000
) (
    input  logic clk,
    input  logic reset,
    input  logic signed [SAMPLE_WIDTH-1:0] data_in,
    input  logic data_valid,
    output logic signed [SAMPLE_WIDTH-1:0] data_out
);

  logic [$clog2(LUT_SIZE)-1:0] index;
  logic signed [15:0] sine_lut [0:LUT_SIZE-1];

  logic signed [16:0] mod_gain;      // Q15-ish gain
  logic signed [31:0] mult_result;
  logic signed [SAMPLE_WIDTH-1:0] modulated_sample;

  assign data_out = modulated_sample;

  initial begin
    $readmemh("sin_lut.txt", sine_lut);
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      index <= '0;
      modulated_sample <= '0;
    end else if (data_valid) begin
      // gain range ~0.5 to 1.0
      mod_gain = 17'sd24576 + (sine_lut[index] >>> 1);

      mult_result = data_in * mod_gain;

      // divide by 2^15
      modulated_sample <= mult_result >>> 15;

      if (index == LUT_SIZE-1)
        index <= '0;
      else
        index <= index + 1'b1;
    end
  end
endmodule