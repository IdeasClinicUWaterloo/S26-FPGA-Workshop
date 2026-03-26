module echo #(
    parameter SAMPLE_WIDTH = 16,
    parameter DELAYED_SAMPLES = 9000
) (
    input logic clk,
    input logic reset,  // active-high reset
    input logic signed [SAMPLE_WIDTH-1:0] data_in,
    input logic data_valid,
    output logic signed [SAMPLE_WIDTH-1:0] data_out
);

  // ------------------------------------------------------------------
  // Internal signals and registers
  // ------------------------------------------------------------------


  // ------------------------------------------------------------------
  // Sequential logic
  // ------------------------------------------------------------------

  always_ff @(posedge clk) begin
    if (reset) begin
      // Reset logic

    end
    else if (data_valid) begin
      // Echo effect logic

    end
  end
endmodule
