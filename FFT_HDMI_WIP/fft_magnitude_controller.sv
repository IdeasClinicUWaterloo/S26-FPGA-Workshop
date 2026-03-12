module fft_mag_controller #(
    parameter int N = 512,
	 parameter int ADDR_WIDTH = 9, // log2(512) = 9
    parameter int FFT_WIDTH  = 24,
    parameter int MAG_WIDTH  = 24
) (
    input  logic                 			clk,
    input  logic                 			reset,
    input  logic 									clk_pixel,
	 
	 input  logic signed [FFT_WIDTH-1:0]	sample,
	 input  logic 									sample_valid,
	 
	 input  logic [ADDR_WIDTH-1:0]			magnitude_index,
    output logic [MAG_WIDTH-1:0] 			magnitude_data
);

  logic [ADDR_WIDTH-1:0]  fft_index;
  logic signed [FFT_WIDTH-1:0] fftr, ffti;
  logic                   fft_valid;

  logic [MAG_WIDTH-1:0] magnitude;

  // instantiate the FFT
  fft_512 u_fft (
      .clk      (clk),
      .reset    (reset),
      .in_sample(sample),
      .in_valid (sample_valid),
      .out_index(fft_index),
      .out_fftr (fftr),
      .out_ffti (ffti),
      .out_valid(fft_valid)
  );

  // magnitude logic
  magnitude_approx u_mag (
      .i_data    (fftr),
      .q_data    (ffti),
      .magnitude (magnitude)
  );

  // store magnitude in RAM
  mag_ram u_ram (
      .clock_a    (clk),
      .clock_b    (clk_pixel),

      // write only on Port A
      .address_a(fft_index),
      .data_a   (magnitude),
      .wren_a   (fft_valid),
      .q_a      (),

      // read only on Port B
      .address_b(magnitude_index),
      .data_b   ({MAG_WIDTH{1'b0}}),
      .wren_b   (1'b0),
      .q_b      (magnitude_data)
  );

endmodule