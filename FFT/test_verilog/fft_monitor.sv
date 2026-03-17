module fft_monitor #(
    parameter int N = 512,
    parameter int SAMPLE_SIZE = 16,
    parameter int FFT_OUT_WIDTH = 24,
    parameter int MAG_WIDTH = 24
) (
    input  logic                 clk,
    input  logic                 reset,

    input  logic                 clk_pixel,
    input  logic [10:0]          hcount,
    input  logic [9:0]           vcount,
    input  logic                 de,

    output logic [23:0]          hdmi_tx_d
);

  localparam int ADDR_WIDTH = $clog2(N);

  logic [ADDR_WIDTH-1:0] sample_count;
  logic signed [SAMPLE_SIZE-1:0] sample_rom;

  logic signed [SAMPLE_SIZE-1:0] fft_sample;
  logic                   sample_valid;

  logic [ADDR_WIDTH-1:0]  fft_index;
  logic signed [FFT_OUT_WIDTH-1:0] fftr, ffti;
  logic                   fft_valid;

  logic [MAG_WIDTH-1:0] magnitude_raw;
  logic [MAG_WIDTH-1:0] magnitude;

  logic                   ram_ready;

  logic [ADDR_WIDTH-1:0]  bin_idx;
  logic                   bin_read;

  logic [ADDR_WIDTH-1:0]  fft_read_addr;
  logic [MAG_WIDTH-1:0]   fft_read_data;

  assign fft_read_addr = bin_idx;
  assign magnitude = magnitude_raw;

  // send samples to fft
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      sample_count <= '0;
      fft_sample   <= '0;
      sample_valid <= 1'b0;
    end else begin
      if (sample_count < N) begin
        fft_sample   <= sample_rom;
        sample_valid <= 1'b1;
        sample_count <= sample_count + 1'b1;
      end else begin
        sample_valid <= 1'b0;
      end
    end
  end

  // ready when we finish writing the last bin
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      ram_ready <= 1'b0;
    end
    else if (fft_valid && (fft_index == N-1))
      ram_ready <= 1'b1;
  end

  // instantiate the FFT
  fft_512 fft (
      .clk      (clk),
      .reset    (reset),
      .in_sample(fft_sample),
      .in_valid (sample_valid),
      .out_index(fft_index),
      .out_fftr (fftr),
      .out_ffti (ffti),
      .out_valid(fft_valid)
  );

  // magnitude logic
  magnitude_approx mag (
      .i_data    (fftr),
      .q_data    (ffti),
      .magnitude (magnitude_raw)
  );

  // renderer turns fft magnitude into rgb pixels
  renderer draw (
      .clk      (clk_pixel),
      .hcount   (hcount),
      .vcount   (vcount),
      .de       (de),
      .rgb      (hdmi_tx_d),
      .bin_idx  (bin_idx),
      .bin_magnitude (magnitude)
  );

  // store magnitude in RAM
  dual_port_ram mag_ram (
      .clk_a    (clk),
      .clk_b    (clk_pixel),

      // write only on Port A
      .addr_a(fft_index),
      .data_a   (magnitude),
      .wren_a   (fft_valid),
      .q_a      (),

      // read only on Port B
      .addr_b(fft_read_addr),
      .data_b   ('0),
      .wren_b   (1'b0),
      .q_b      (fft_read_data)
  );

  cos_samples_rom cos_samples (
      .address(sample_count),
      .clock  (clk),
      .q      (sample_rom)
  );

endmodule