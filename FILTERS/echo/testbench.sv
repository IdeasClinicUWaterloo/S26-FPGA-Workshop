`timescale 1ns/1ps

module tb_echo_cos;

    localparam SAMPLE_WIDTH = 16;
    localparam NUM_ECHO_SAMPLES = 8;

    logic clk;
    logic reset;
    logic signed [SAMPLE_WIDTH-1:0] sample;
    logic sample_valid;
    logic signed [SAMPLE_WIDTH-1:0] sample_out;

    // real variables for cosine
    real t;
    real freq;
    real sample_rate;
    real value;

    integer i;

    echo #(
        .SAMPLE_WIDTH(SAMPLE_WIDTH),
        .NUM_ECHO_SAMPLES(NUM_ECHO_SAMPLES)
    ) dut (
        .clk(clk),
        .reset(reset),
        .sample(sample),
        .sample_valid(sample_valid),
        .sample_out(sample_out)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        sample = 0;
        sample_valid = 0;

        sample_rate = 48000.0;
        freq = 1000.0;

        repeat(3) @(posedge clk);
        reset = 0;
        sample_valid = 1;

        // test with two impulses
        for(i = 0; i < 200; i++) begin
            @(posedge clk);
            if(i == 0 || i == 100) sample = 10_000;
            else sample = 0;
        end

        sample_valid = 0;
        
        repeat(5) @(posedge clk);
        $finish;
    end

    // print input and output
    always @(posedge clk) begin
        if(sample_valid) begin
            $display("in=%0d, out=%0d", sample, sample_out);
        end
    end

endmodule

