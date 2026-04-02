module test_signal (
    input  logic clk,
    input  logic reset,
    output logic out_signal16
);

    impulse_generator u_impulse (
        .clk(clk),
        .reset(reset),
        .impulse(out_signal16)
    );

endmodule