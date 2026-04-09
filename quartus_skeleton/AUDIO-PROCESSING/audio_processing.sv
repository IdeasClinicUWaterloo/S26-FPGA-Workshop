module audio_processing (
    input logic clk_50,
    input logic reset,
    input logic [9:0] sw,
    input logic signed [15:0] in_audio,
    input logic in_valid,
    output logic signed [15:0] out_audio,
    output logic out_ready
);

    assign out_audio = in_audio;
    assign out_ready = in_valid;

endmodule
