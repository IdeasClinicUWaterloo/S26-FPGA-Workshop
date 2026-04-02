module test_signal (
    input  logic clk,
    input  logic reset,
    input  logic sample_valid,
    output logic [15:0] out_signal
);

    impulse_generator u_impulse (
        .clk(clk),
        .sample_valid(sample_valid),
        .reset(reset),
        .out_signal(out_signal)
    );

endmodule