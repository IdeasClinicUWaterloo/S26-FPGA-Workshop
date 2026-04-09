module impulse_generator (
    input  logic clk,
    input  logic reset,
    input  logic sample_valid,
    output logic signed [15:0] out_signal
);

    // ~0.15 sec between clicks (easy to see echoes)
    localparam int PERIOD_SAMPLES = 7200;

    // Length of the click (in samples)
    localparam int CLICK_LENGTH = 128;

    // Initial amplitude
    localparam logic signed [15:0] START_AMPLITUDE = 16'sd12000;

    logic [$clog2(PERIOD_SAMPLES)-1:0] counter;
    logic [$clog2(CLICK_LENGTH)-1:0] click_idx;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter     <= 0;
            click_idx   <= 0;
            out_signal  <= 16'sd0;
        end else if (sample_valid) begin

            // advance main counter
            if (counter == PERIOD_SAMPLES - 1) begin
                counter   <= 0;
                click_idx <= 0;   // start new click
            end else begin
                counter <= counter + 1;
            end

            // generate decaying click
            if (click_idx < CLICK_LENGTH) begin
                // exponential-like decay using shifts (cheap in hardware)
                out_signal <= START_AMPLITUDE >>> (click_idx >> 3);
                click_idx  <= click_idx + 1;
            end else begin
                out_signal <= 16'sd0;
            end
        end
    end

endmodule