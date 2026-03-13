module echo #(
    parameter SAMPLE_WIDTH = 16,
    parameter NUM_ECHO_SAMPLES = 12000
) (
    input logic clk,
    input logic reset,
    input logic signed [SAMPLE_WIDTH-1:0] sample,
    input logic sample_valid,
    output logic signed [SAMPLE_WIDTH-1:0] sample_out
);

  logic [$clog2(NUM_ECHO_SAMPLES)-1:0] count;

  // delay memory
  logic signed [SAMPLE_WIDTH-1:0] arr[0:NUM_ECHO_SAMPLES-1];

  // delayed sample
  logic signed [SAMPLE_WIDTH-1:0] delayed_sample;

  // mixed signal
  logic signed [SAMPLE_WIDTH:0] mixed;

  integer i;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      count          <= 0;
      delayed_sample <= 0;
      mixed          <= 0;
      sample_out     <= 0;

      for (i = 0; i < NUM_ECHO_SAMPLES; i = i + 1) arr[i] <= 0;

    end else begin
      if (sample_valid) begin
        delayed_sample <= arr[count];

        // current + half delayed
        mixed <= sample + (delayed_sample >>> 1);
        sample_out <= mixed[SAMPLE_WIDTH-1:0];

        // store mixed for repeated echoes
        arr[count] <= mixed[SAMPLE_WIDTH-1:0];

        if (count == NUM_ECHO_SAMPLES - 1) count <= 0;
        else count <= count + 1;
      end
    end
  end

endmodule
