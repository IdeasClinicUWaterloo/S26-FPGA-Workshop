module robotic #(
    parameter SAMPLE_WIDTH = 16,
    parameter LUT_SIZE = 256
) (
    input  logic clk,
    input  logic reset,
    input  logic signed [SAMPLE_WIDTH-1:0] data_in,
    input  logic data_valid,
    output logic signed [SAMPLE_WIDTH-1:0] data_out
);

  logic [$clog2(LUT_SIZE)-1:0] index;
  logic signed [15:0] sine_lut [0:LUT_SIZE-1];
  logic signed [31:0] mult_result;

  initial begin
    $readmemh("sine_lut.txt", sine_lut);
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      index    <= '0;
      data_out <= '0;
    end 
    else if (data_valid) begin
      mult_result = (data_in * sine_lut[index]);
      data_out <= mult_result >>> 15;

      if (index == LUT_SIZE-1)
        index <= '0;
      else
        index <= index + 1'b1;
    end
  end

endmodule