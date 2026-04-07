module echo #(
    parameter SAMPLE_WIDTH = 16,
    parameter DELAYED_SAMPLES = 9000
) (
    input  logic clk,
    input  logic reset, // active-high reset
    input  logic signed [SAMPLE_WIDTH-1:0] data_in,
    input  logic data_valid,
    output logic signed [SAMPLE_WIDTH-1:0] data_out
);

    logic [$clog2(DELAYED_SAMPLES)-1:0] index;

    // array of previous samples
    logic signed [SAMPLE_WIDTH-1:0] prev_samples [0:DELAYED_SAMPLES-1];
    logic signed [SAMPLE_WIDTH-1:0] delayed_sample;

    always_ff @(posedge clk) begin
        if (reset) begin
            index <= 0;
            data_out <= 0;
        end else if (data_valid) begin
            delayed_sample <= prev_samples[index];
            data_out <= data_in + (delayed_sample >>> 1);

            prev_samples[index] <= data_in + (delayed_sample >>> 1);

            if (index == DELAYED_SAMPLES - 1) index <= 0;
            else index <= index + 1;
        end
    end
endmodule