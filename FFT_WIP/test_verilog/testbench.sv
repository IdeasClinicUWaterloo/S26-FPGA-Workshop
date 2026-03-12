`timescale 1ns/1ps

module tb_fft_monitor;

  localparam int N             = 512;
  localparam int SAMPLE_SIZE   = 16;
  localparam int FFT_OUT_WIDTH = 24;
  localparam int MAG_WIDTH     = 24;

  logic        clk;
  logic        reset;
  logic        clk_pixel;
  logic [10:0] hcount;
  logic [9:0]  vcount;
  logic        de;
  logic [23:0] hdmi_tx_d;

  // DUT
  fft_monitor #(
      .N(N),
      .SAMPLE_SIZE(SAMPLE_SIZE),
      .FFT_OUT_WIDTH(FFT_OUT_WIDTH),
      .MAG_WIDTH(MAG_WIDTH)
  ) dut (
      .clk       (clk),
      .reset     (reset),
      .clk_pixel (clk_pixel),
      .hcount    (hcount),
      .vcount    (vcount),
      .de        (de),
      .hdmi_tx_d (hdmi_tx_d)
  );

  // -------------------------
  // Clock generation
  // -------------------------
  initial begin
    clk = 0;
    forever #10 clk = ~clk;      // 50 MHz
  end

  initial begin
    clk_pixel = 0;
    forever #20 clk_pixel = ~clk_pixel; // 25 MHz
  end

  // -------------------------
  // Simple video timing stimulus
  // -------------------------
  always @(posedge clk_pixel or posedge reset) begin
    if (reset) begin
      hcount <= '0;
      vcount <= '0;
      de     <= 1'b0;
    end else begin
      // simple fake raster, not real HDMI timing
      if (hcount == 11'd799) begin
        hcount <= 11'd0;
        if (vcount == 10'd524)
          vcount <= 10'd0;
        else
          vcount <= vcount + 10'd1;
      end else begin
        hcount <= hcount + 11'd1;
      end

      // active display area
      de <= (hcount < 11'd640) && (vcount < 10'd480);
    end
  end

  // -------------------------
  // Reset
  // -------------------------
  initial begin
    reset = 1'b1;
    hcount = '0;
    vcount = '0;
    de = 1'b0;

    repeat (5) @(posedge clk);
    reset = 1'b0;
  end

  // -------------------------
  // Monitoring
  // -------------------------
  /*initial begin
    $display("Starting tb_fft_monitor...");
    $monitor("[%0t] reset=%0b sample_count=%0d sample_valid=%0b fft_valid=%0b fft_index=%0d magnitude=%0d rgb=%h",
             $time,
             reset,
             dut.sample_count,
             dut.sample_valid,
             dut.fft_valid,
             dut.fft_index,
             dut.magnitude,
             hdmi_tx_d);
  end*/

  // Watch FFT outputs
  always_ff @(posedge clk) begin
    if (!reset && dut.fft_valid) begin
      $display("[%0t] FFT bin %0d | Mag=%0d",
               $time, dut.fft_index, dut.magnitude);
    end
  end

  // Detect when RAM has been fully written
  /*always_ff @(posedge clk) begin
    if (!reset && dut.ram_ready) begin
      $display("[%0t] RAM ready asserted: all FFT bins should be written.", $time);
    end
  end*/

  // -------------------------
  // End simulation
  // -------------------------
  initial begin
    // enough time for:
    // - sample loading
    // - fft processing
    // - some renderer reads
    #(2000000);
    $display("Finished tb_fft_monitor.");
    $finish;
  end

endmodule