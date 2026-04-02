module impulse_generator (
    input  logic clk,
    input  logic reset,
    input  logic sample_valid,
    output logic signed [15:0] out_signal
);

    // Number of valid audio samples between pulses
    // 24000 samples at 48 kHz ≈ 0.5 seconds
    localparam int PERIOD_SAMPLES = 24000;

    // Width of the pulse in audio samples
    // 200 samples at 48 kHz ≈ 4.2 ms
    localparam int PULSE_WIDTH = 200;

    // Keep this moderate so it does not dominate the screen
    localparam logic signed [15:0] PULSE_AMPLITUDE = 16'sd6000;

    logic [$clog2(PERIOD_SAMPLES)-1:0] counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter    <= 0;
            out_signal <= 16'sd0;
        end else begin
            if (sample_valid) begin
                if (counter == PERIOD_SAMPLES - 1)
                    counter <= 0;
                else
                    counter <= counter + 1;

                if (counter < PULSE_WIDTH)
                    out_signal <= PULSE_AMPLITUDE;
                else
                    out_signal <= 16'sd0;
            end
        end
    end

endmodule