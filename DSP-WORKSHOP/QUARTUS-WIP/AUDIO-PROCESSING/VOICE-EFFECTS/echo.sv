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

    logic [$clog2(DELAYED_SAMPLES)-1:0] counter;

    // array of previous samples
    logic signed [SAMPLE_WIDTH-1:0] prev_samples [0:DELAYED_SAMPLES-1];
    logic signed [SAMPLE_WIDTH-1:0] delayed_sample;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            data_out <= 0;
        end else if (data_valid) begin
            delayed_sample <= prev_samples[counter];
            data_out <= data_in + (delayed_sample >>> 1);

            prev_samples[counter] <= data_in + (delayed_sample >>> 1);

            if (counter == DELAYED_SAMPLES - 1) counter <= 0;
            else counter <= counter + 1;
        end
    end
endmodule