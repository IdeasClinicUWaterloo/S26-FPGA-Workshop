`timescale 1ns/1ps

module tb_fourth_order_bpf;

    logic clk;
    logic reset;

    logic signed [15:0] data_in;
    logic signed [15:0] data_out;

    real fs = 48000.0;

    integer i;
    integer fout;

    real t;
    real value;

    fourth_order_bpf dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("bpf.vcd");
        $dumpvars(0, tb_fourth_order_bpf);
    end

    initial begin

        fout = $fopen("bpf_samples.txt","w");

        reset = 1;
        data_in = 0;

        repeat(4) @(posedge clk);
        reset = 0;

        // -----------------------------
        // 100 Hz (below passband)
        // -----------------------------
        for(i = 0; i < 512; i++) begin
            @(posedge clk);

            t = i/fs;
            value = $cos(2.0 * 3.1415926535 * 100.0 * t);

            data_in = $rtoi(value * 12000);

            $fwrite(fout,"100Hz in=%0d out=%0d\n", data_in, data_out);
        end

        // -----------------------------
        // 1000 Hz (inside passband)
        // -----------------------------
        for(i = 0; i < 512; i++) begin
            @(posedge clk);

            t = i/fs;
            value = $cos(2.0 * 3.1415926535 * 1000.0 * t);

            data_in = $rtoi(value * 12000);

            $fwrite(fout,"1000Hz in=%0d out=%0d\n", data_in, data_out);
        end

        // -----------------------------
        // 8000 Hz (above passband)
        // -----------------------------
        for(i = 0; i < 512; i++) begin
            @(posedge clk);

            t = i/fs;
            value = $cos(2.0 * 3.1415926535 * 8000.0 * t);

            data_in = $rtoi(value * 12000);

            $fwrite(fout,"8000Hz in=%0d out=%0d\n", data_in, data_out);
        end

        $fclose(fout);

        repeat(10) @(posedge clk);
        $finish;

    end

endmodule