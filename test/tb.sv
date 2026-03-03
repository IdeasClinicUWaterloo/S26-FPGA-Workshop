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
  logic [9:0] set_addr;

  // OUTPUT FROM DUT
  logic [15:0] read_data;
  logic led_alive;

  // Design Under Test
  top dut(
    .clk(clk),
    .set_addr(set_addr),
    .read_data(read_data),
    .led_alive(led_alive)
  );

endmodule
