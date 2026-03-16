module echo #(
    parameter SAMPLE_WIDTH = 16,
    parameter NUM_ECHO_SAMPLES = 4500
) (
    input  logic clk,
    input  logic reset, // Active-high reset
    input  logic signed [SAMPLE_WIDTH-1:0] sample,
    input  logic sample_valid,
    output logic signed [SAMPLE_WIDTH-1:0] sample_out
);

    logic [$clog2(NUM_ECHO_SAMPLES)-1:0] count;

    logic signed [SAMPLE_WIDTH-1:0] arr [0:NUM_ECHO_SAMPLES-1];
    logic signed [SAMPLE_WIDTH-1:0] ram_data_out;

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= 0;
            sample_out <= 0;
        end else if (sample_valid) begin
            ram_data_out <= arr[count];
            sample_out <= sample + (ram_data_out >>> 1);

            arr[count] <= sample + (ram_data_out >>> 1);

            if (count == NUM_ECHO_SAMPLES - 1)
                count <= 0;
            else
                count <= count + 1;
        end
    end
endmodule