module impulse_generator (
    input  logic clk,
    input  logic reset,
    input  logic sample_valid,
    output logic signed [15:0] out_signal
);

// Repeat every 0.25 s at 48 kHz
    localparam int PERIOD_SAMPLES = 12000;

    logic [$clog2(PERIOD_SAMPLES)-1:0] counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter    <= 0;
            out_signal <= 16'sd0;
        end else if (sample_valid) begin
            if (counter == PERIOD_SAMPLES - 1)
                counter <= 0;
            else
                counter <= counter + 1;

            // Short bipolar click, then silence
            case (counter)
                0: out_signal <=  16'sd12000;
                1: out_signal <= -16'sd6000;
                2: out_signal <=  16'sd3000;
                3: out_signal <= -16'sd1500;
                default: out_signal <= 16'sd0;
            endcase
        end
    end

endmodule