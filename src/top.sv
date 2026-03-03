module top(
  input       clk,
  input [9:0] set_addr,
  output [15:0] read_data,
  output led_alive
);

  localparam N_TWIDDLE_ELEMS = 1024;
  
  assign led_alive = 1'b1;
  
  memory_ro #(
    .INIT_SRC("cosine_samples.mem"),
    .N(N_TWIDDLE_ELEMS),
    .BITW(16)
  ) memory_ro_inst (
    .clk(clk),
    .addr(set_addr),
    .data(read_data)
  );

endmodule  
