`timescale 1ns/1ps

module tb_fft_16;

  parameter N = 512;
  parameter log2N = 9;
  parameter SAMPLE_SIZE = 24;

  logic clk;
  logic reset;
  logic [SAMPLE_SIZE-1:0] in_sample;
  logic in_valid, out_valid;

  logic [log2N-1:0] out_index;
  logic signed [SAMPLE_SIZE-1:0] out_fftr, out_ffti;

  // DUT
  fft_512 #(
    .N(N),
    .log2N(log2N),
    .SAMPLE_SIZE(SAMPLE_SIZE)
  ) dut (
    .clk(clk),
    .reset(reset),
    .in_sample(in_sample),
    .in_valid(in_valid),
    .out_index(out_index),
    .out_fftr(out_fftr),
    .out_ffti(out_ffti),
    .out_valid(out_valid)
  );

  // Clock: 10 ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test data
  logic [SAMPLE_SIZE-1:0] test_vec [0:N-1];
  integer i;

  real theta;
  real amplitude = 4000; // Use 50% of max range to avoid overflow
  initial begin
    for (i = 0; i < N; i = i + 1) begin
      theta = 2.0 * 3.14159265 * 10.0 * i / N;
      test_vec[i] = $signed($rtoi(amplitude * $cos(theta)));
      //test_vec[i] = 1;
    end
  end

  // Stimulus
  initial begin
    reset     = 1;
    in_valid  = 0;
    in_sample = 0;

    // Hold reset for a bit
    #20;
    reset = 0;

    // Load 16 samples, one per clock
    @(posedge clk);
    in_valid = 1;
    for (i = 0; i < N; i = i + 1) begin
      in_sample = test_vec[i];
      @(posedge clk);
    end
    in_valid  = 0;
    in_sample = 0;

    // Wait long enough for readback/output
    repeat (100000) @(posedge clk);

    $finish;
  end

  // Monitor
  /*always @(posedge clk) begin
    $display("T=%0t | reset=%0b state=%0d count=%0d | in_valid=%0b in_sample=%0d | hi=%0d lo=%0d | out_index=%0d out_value=%0d",
             $time, reset, dut.state, dut.count, in_valid, in_sample,
             hi_index, lo_index, out_index, out_value);
  end*/

  // Optional: print readback more clearly
  /*always @(posedge clk) begin
    if (!reset && dut.state == dut.BUTTERFLY_CALC) begin
      $display("stage=%0d j=%0d | hi_index =%0d lo_index=%0d | twiddle_index=%0d cos_tw =%0d sin_tw=%0d",
         dut.stage, dut.j, dut.hi_index, dut.lo_index, dut.twiddle_index,
         dut.cos, dut.sin);
    end
  end*/

  /*always @(posedge clk) begin
    if (!reset && dut.state == dut.WRITE) begin
      $display("hi_index=%0d hi =%0d + (%0d)j | lo_index=%0d lo =%0d + (%0d)j | cos_tw =%0d sin_tw=%0d | tr=%0d ti=%0d",
         dut.addr_hi, dut.hi_r, dut.hi_i, dut.addr_lo, dut.lo_r, dut.lo_i, dut.cos, dut.sin, dut.tr, dut.ti);
    end
  end*/

  always @(posedge clk) begin
    if(out_valid == 1) begin
        $display("index= %0d | fftr= %0d | ffti= %0d", out_index, out_fftr, out_ffti);
    end
  end

  /*always @(posedge clk) begin
    if (!reset && dut.state == dut.WRITE) begin
      $display("READBACK --> hi=%0d  lo=%0d | hi_value=%0d lo_value=%0d", dut.addr_hi, dut.addr_lo, dut.data_hi, dut.data_lo);
    end
  end*/

endmodule