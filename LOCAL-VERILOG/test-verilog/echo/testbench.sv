`timescale 1ns/1ps

module tb_echo;

    localparam int SAMPLE_WIDTH     = 16;
    localparam int DELAYED_SAMPLES = 8;    // small for easy simulation
    localparam int NUM_SAMPLES      = 200;

    logic clk;
    logic reset;
    logic signed [SAMPLE_WIDTH-1:0] data_in;
    logic data_valid;
    logic signed [SAMPLE_WIDTH-1:0] data_out;

    integer i;

    echo #(
        .SAMPLE_WIDTH(SAMPLE_WIDTH),
        .DELAYED_SAMPLES(DELAYED_SAMPLES)
    ) dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out)
    );

    // clock: 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // initialize signals
        reset        = 1'b1;
        data_in       = '0;
        data_valid = 1'b0;

        // initialize DUT memory to zero for simulation clarity
        for (i = 0; i < DELAYED_SAMPLES; i = i + 1) begin
            dut.prev_samples[i] = '0;
        end
        dut.delayed_sample = '0;

        // hold reset for a few cycles
        repeat (3) @(posedge clk);
        reset = 1'b0;
        data_valid = 1'b1;

        // stimulus: one impulse, then zeros
        for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
            @(posedge clk);
            if (i == 0 || i == 100)
                data_in <= 16'sd10000;
            else
                data_in <= 16'sd0;
        end

        // stop driving samples
        @(posedge clk);
        data_valid <= 1'b0;
        data_in       <= 16'sd0;

        repeat (5) @(posedge clk);
        $finish;
    end

    // monitor
    always @(posedge clk) begin
        if (data_valid) begin
            $display("in=%0d,out=%0d",
                     data_in, data_out);
        end
    end

endmodule