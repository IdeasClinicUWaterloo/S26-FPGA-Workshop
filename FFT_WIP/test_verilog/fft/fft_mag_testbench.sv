`timescale 1ns/1ps

module tb_fft_magnitude();

    parameter N = 512;
    parameter log2N = 9;
    parameter SAMPLE_SIZE = 24;
    parameter CLK_PERIOD = 10;

    logic clk;
    logic reset;
    logic [SAMPLE_SIZE-1:0] in_sample;
    logic in_valid;

    logic out_ram_ready;
    logic [log2N-1:0] out_read_addr;
    logic [SAMPLE_SIZE-1:0] out_read_data;

    // Instantiate the Unit Under Test (UUT)
    fft_mag #(
        .N(N),
        .log2N(log2N),
        .SAMPLE_SIZE(SAMPLE_SIZE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .in_sample(in_sample),
        .in_valid(in_valid),
        .out_ram_ready(out_ram_ready),
        .out_read_addr(out_read_addr),
        .out_read_data(out_read_data)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    real theta;
    real amplitude = 200; // Use 50% of max range to avoid overflow

    // Test Procedure
    initial begin
        // Initialize
        reset = 1;
        in_sample = 0;
        in_valid = 0;
        out_read_addr = 0;

        #(CLK_PERIOD * 5);
        reset = 0;
        #(CLK_PERIOD * 2);

        // --- Step 1: Feed a Ramp Signal (0 to 15) ---
        $display("--- Starting Input Feed (Ramp Signal) ---");
        for (int i = 0; i < N; i++) begin
            @(posedge clk);

            theta = 2.0 * 3.14159265 * 10.0 * i / N;
            in_sample = $rtoi(amplitude * $sin(theta));
            //in_sample = i;
            in_valid = 1;
        end

        @(posedge clk);
        in_valid = 0;
        in_sample = 0;

        // --- Step 2: Wait for FFT to process ---
        $display("Waiting for FFT processing and RAM storage...");
        wait(out_ram_ready == 1);

        // Give it one extra cycle to ensure the final write is retired
        #(CLK_PERIOD);

        // --- Step 3: Read from Magnitude RAM ---
        $display("--- Reading Magnitudes from RAM ---");
        for (int i = 0; i < N; i++) begin
            out_read_addr = i;
            #(CLK_PERIOD); // Wait for RAM read latency
            $display("Index: %2d | Magnitude: %d", i, out_read_data);
        end

        #(CLK_PERIOD * 10);
        $display("Test Complete.");
        $finish;
    end

    // Optional: Monitor the internal FFT output
    initial begin
        $monitor("At time %t: out_index=%d, out_valid=%b", $time, uut.out_index, uut.out_valid);
    end

endmodule