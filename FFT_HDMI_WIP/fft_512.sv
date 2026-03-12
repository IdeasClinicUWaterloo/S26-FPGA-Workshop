`timescale 1ns / 1ps

module fft_512 #(
    parameter N = 512,
    parameter log2N = 9,
    parameter SAMPLE_SIZE = 24
) (
    input  logic clk,
    input  logic reset,
    input  logic [SAMPLE_SIZE-1:0] in_sample,
    input  logic in_valid,

    output logic [log2N-1:0] out_index,
    output logic signed [SAMPLE_SIZE-1:0] out_fftr,
    output logic signed [SAMPLE_SIZE-1:0] out_ffti,
    output logic out_valid
);

  typedef enum logic [3:0] {
    LOAD_SAMPLES,
    READ_ADDR,
    READ_WAIT,
    READ,
    BUTTERFLY_MULT,
    BUTTERFLY_CALC,
    WRITE,
    UPDATE_INDICES,
    OUT_ADDR,
    OUT_WAIT,
    OUT_SHOW,
    DONE
  } state_t;
  state_t state;

  logic [log2N-1:0] twiddle_index; // twiddle factor
  logic [log2N-1:0] hi_index, lo_index;

  // indices for in-place memory
  logic [log2N-1:0] stage;
  logic [log2N-1:0] j; // j calculations per butterfly
  logic [log2N-1:0] Hindex; // Hindex Step BSep butterflies per stage
  logic [log2N:0]   BSep; // separation between butterflies = 2^stage
  logic [log2N:0] BWidth; // butterfly width (spacing between opposite points) = separation / 2

  // read/write RAM
  logic [log2N-1:0] count;
  logic             wren_hi, wren_lo;
  logic [log2N-1:0] addr_hi, addr_lo;
  logic signed [SAMPLE_SIZE*2-1:0] data_hi, data_lo, q_hi, q_lo;

  // bit-reversal
  logic [log2N-1:0] rcount;
  assign rcount = {count[0], count[1], count[2], count[3], count[4], count[5], count[6], count[7], count[8]};

  // butterfly
  logic signed [SAMPLE_SIZE-1:0] tr, ti, hi_r, lo_r, hi_i, lo_i; // real and imaginary parts
  logic signed [SAMPLE_SIZE+16-1:0] cos_r, sin_r, cos_i, sin_i;
  logic signed [SAMPLE_SIZE+17-1:0] sum_r, diff_i;
  logic signed [15:0] cos, sin;

  // derived values from stage
  always_comb begin
    BSep   = (1 << stage);
    BWidth = BSep >> 1;
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state     <= LOAD_SAMPLES;
      count     <= 0;

      stage     <= 1; j         <= 0; Hindex    <= 0;
      hi_index  <= 0; lo_index  <= 1; twiddle_index <= 0;

      wren_hi   <= 0; wren_lo   <= 0;
      addr_hi   <= 0; addr_lo   <= 0;
      data_hi   <= 0; data_lo   <= 0;

      tr <=0; ti <= 0; diff_i <= 0; sum_r <= 0;

      out_index <= 0; out_valid <= 0;
      out_fftr <= 0; out_ffti <= 0;
    end else begin
      // defaults
      wren_hi <= 0;
      wren_lo <= 0;

      case (state)
        // load in bit-reverse order
        LOAD_SAMPLES: begin
          if (in_valid) begin
            wren_hi <= 1;
            addr_hi <= rcount;
            data_hi <= {{SAMPLE_SIZE{1'b0}}, in_sample};

            if (count == N-1) begin
              count  <= 0;
              stage  <= 1;
              j      <= 0;
              Hindex <= 0;
              state  <= UPDATE_INDICES;
            end else begin
              count <= count + 1;
            end
          end
        end

        // set read address
        READ_ADDR: begin
          addr_hi <= hi_index;
          addr_lo <= lo_index;
          state  <= READ_WAIT;
        end

        // wait a cycle for address to load
        READ_WAIT: begin
          state  <= READ;
        end

        // read real and imag values
        READ: begin
          hi_i  <= q_hi[SAMPLE_SIZE*2-1:SAMPLE_SIZE];
          hi_r  <= q_hi[SAMPLE_SIZE-1:0];
          lo_i  <= q_lo[SAMPLE_SIZE*2-1:SAMPLE_SIZE];
          lo_r  <= q_lo[SAMPLE_SIZE-1:0];
          state  <= BUTTERFLY_MULT;
        end
			
		  // DIT butterfly (decimation-in-time)
        BUTTERFLY_MULT: begin
          cos_r <= $signed(lo_r) * $signed(cos);
          cos_i <= $signed(lo_i) * $signed(cos);
          sin_r <= $signed(lo_r) * $signed(sin);
          sin_i <= $signed(lo_i) * $signed(sin);
          state  <= BUTTERFLY_CALC;
        end

        BUTTERFLY_CALC: begin
          tr <= (cos_r + sin_i + 16'sd16384) >>> 15;
          ti <= (cos_i - sin_r + 16'sd16384) >>> 15;

          state  <= WRITE;
        end

        WRITE: begin
          wren_hi <= 1;
          wren_lo <= 1;

          data_hi <= {hi_i + ti, hi_r + tr};
          data_lo <= {hi_i - ti, hi_r - tr};

          state  <= UPDATE_INDICES;
        end

        UPDATE_INDICES: begin
          if (stage <= log2N) begin
            state <= READ_ADDR;

            if (Hindex + BSep >= N) begin
              Hindex <= 0;

              if (j + 1 >= BWidth[log2N-1:0]) begin
                j <= 0;

                if (stage == log2N) begin
                  count <= 0;
                  state <= OUT_ADDR;
                end else begin
                  stage <= stage + 1;
                end
              end else begin
                j <= j + 1;
              end
            end else begin
              Hindex <= Hindex + BSep[log2N-1:0];
            end
          end else begin
            count <= 0;
            state <= OUT_ADDR;
          end

          // update indices for next butterfly operation
          hi_index <= Hindex + j;
          lo_index <= Hindex + j + BWidth[log2N-1:0];
          twiddle_index <= j << (log2N - stage);
        end

        // set address
        OUT_ADDR: begin
          out_valid <= 0;
          addr_hi <= count;
          state   <= OUT_WAIT;
        end

        // wait a cycle for the address to change
        OUT_WAIT: begin
          state <= OUT_SHOW;
        end

        // send out samples
        OUT_SHOW: begin
          out_index <= count;
          out_fftr <= q_hi[SAMPLE_SIZE-1:0];
          out_ffti <= q_hi[SAMPLE_SIZE*2 - 1: SAMPLE_SIZE];
          out_valid <= 1;

          if (count == N - 1) begin
            state <= DONE;
          end else begin
            count <= count + 1;
            state <= OUT_ADDR;
          end
        end

        DONE: begin
          out_valid <= 0;
			 count <= 0;
          //state <= LOAD_SAMPLES; // loop back
        end

        default: begin
          state <= LOAD_SAMPLES;
        end
      endcase
    end
  end

  cos_rom cos_lut (
    .address(twiddle_index),
    .clock(clk),
    .q(cos)
  );

  sin_rom sin_lut (
    .address(twiddle_index),
    .clock(clk),
    .q(sin)
  );

  fft_ram ram (
      .clock    (clk),
      .address_a(addr_hi),
      .data_a   (data_hi),
      .wren_a   (wren_hi),
      .q_a      (q_hi),
      .address_b(addr_lo),
      .data_b   (data_lo),
      .wren_b   (wren_lo),
      .q_b      (q_lo)
  );

endmodule