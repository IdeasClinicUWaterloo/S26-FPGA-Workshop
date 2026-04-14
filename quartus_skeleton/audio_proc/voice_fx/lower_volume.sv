module lower_volume #(
    parameter SAMPLE_WIDTH = 16
) (
    input logic clk,
    input logic reset,
    input logic signed [SAMPLE_WIDTH-1:0] data_in,
    input logic data_valid,
    output logic signed [SAMPLE_WIDTH-1:0] data_out
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin

    end else if (data_valid) begin

    end
  end

endmodule
