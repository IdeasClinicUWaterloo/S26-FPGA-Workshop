`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // INPUT INTO DUT
  logic clk;
  logic reset;
  logic signed [23:0] xr_in, xi_in;


  // OUTPUT FROM DUT
  logic               fft_valid;
  logic signed [23:0] fftr, ffti;

  // Design Under Test
  top dut(
    .clk(clk),
    .reset(reset),
    .xi_in(xi_in),
    .xr_in(xr_in),
    .fft_valid(fft_valid),
    .fftr(fftr),
    .ffti(ffti)
  );

endmodule
