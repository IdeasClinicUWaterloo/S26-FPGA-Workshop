module fft_mag #(
    parameter N = 512,
    parameter log2N = 9,
    parameter SAMPLE_SIZE = 24
)(
    input  logic clk,
    input  logic reset,
    input  logic [SAMPLE_SIZE-1:0] in_sample,
    input  logic in_valid,

    output logic out_ram_ready, // High when RAM has a fresh batch
    input  logic [log2N-1:0] out_read_addr,
    output logic [SAMPLE_SIZE-1:0] out_read_data
);

    logic [log2N-1:0] out_index;
    logic signed [SAMPLE_SIZE-1:0] out_fftr, out_ffti;
    logic out_valid;
    logic [SAMPLE_SIZE-1:0] magnitude;

    // Instansiate the FFT
    fft_512 #( .N(N), .log2N(log2N), .SAMPLE_SIZE(SAMPLE_SIZE) ) fft (
        .clk(clk), .reset(reset),
        .in_sample(in_sample), .in_valid(in_valid),
        .out_index(out_index), .out_fftr(out_fftr), .out_ffti(out_ffti),
        .out_valid(out_valid)
    );

    // Magnitude Logic
    magnitude_approx #( .WIDTH(SAMPLE_SIZE) ) mag (
        .i_data(out_fftr), .q_data(out_ffti),
        .magnitude(magnitude)
    );

    // Ready when we finish writing the last bin
    always_ff @(posedge clk) begin
        if (reset) out_ram_ready <= 0;
        else if (out_valid && out_index == N-1) out_ram_ready <= 1;
    end

    // Storage RAM
    fft_ram mag_ram (
        .clock     (clk),
        .address_a (out_index),
        .data_a    (magnitude),
        .wren_a    (out_valid),
        .q_a       (), // Write only on Port A

        .address_b (out_read_addr),
        .data_b    ({SAMPLE_SIZE{1'b0}}),
        .wren_b    (1'b0),
        .q_b       (out_read_data) // Read only on Port B
    );

endmodule