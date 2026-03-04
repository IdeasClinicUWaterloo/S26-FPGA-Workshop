module top(
  input                clk,
  input                reset,
  input signed [23:0]  xr_in, xi_in,
  output               fft_valid,
  output signed [23:0] fftr, ffti
);

  fft #(.N(512)) fft_inst(
    .clk(clk),
    .reset(reset),
    .xi_in(xi_in),
    .xr_in(xr_in),
    .fft_valid(fft_valid),
    .fftr(fftr),
    .ffti(ffti)
  );

endmodule  
