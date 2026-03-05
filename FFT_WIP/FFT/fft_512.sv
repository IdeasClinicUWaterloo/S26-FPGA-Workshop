module fft_512 #(
    parameter N = 512
) (
    input clk,
    input reset,
    input signed [23:0] xr_in,
    output fft_valid,
    output signed [23:0] fftr,
    ffti
);

  logic signed [23:0] xr_i1, xi_i1, xr_i2, xi_i2;
  logic [8:0] addr_a, addr_b;
  logic [47:0] data_a, data_b;
  logic [47:0] q_a, q_b;
  logic wren_a, wren_b;

  enum {
    START,
    LOAD,
    READ,
    CALC,
    WRITE,
    UPDATE,
    REVERSE,
    DONE
  } state;
  
  logic [9:0] w;
  logic [9:0] dw;

  logic [8:0] i1, i2;
  logic [8:0] gcount;
  logic [10:0] k1, k2;
  logic [ 3:0] stage;

  logic [10:0] count;
  logic [ 8:0] rcount;
  logic signed [31:0] tr, ti, cos_tr, cos_ti, sin_tr, sin_ti;

  logic signed [15:0] cos_read;
  logic signed [15:0] sin_read;

  logic               r_fft_valid;
  logic signed [23:0] r_fftr, r_ffti;

  assign rcount = {
    count[0], count[1], count[2], count[3], count[4], count[5], count[6], count[7], count[8]
  };

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= START;
      count <= 0;
      gcount <= 0;
      stage <= 1;
      i1 <= 0;
      i2 <= 9'(N / 2);
      k1 <= N;
      k2 <= N / 2;
      dw <= 1;
      w <= 0;
      r_fft_valid <= 0;
      r_fftr <= 0;
      r_ffti <= 0;
    end else begin  // if (reset)
      case (state)
        START: begin
          state <= LOAD;
          count <= 0;
          w <= 0;
          gcount <= 0;
          stage <= 1;
          i1 <= 0;
          i2 <= 9'(N / 2);
          k1 <= N;
          k2 <= N / 2;
          dw <= 1;
          r_fft_valid <= 0;
        end  // case: START
        LOAD: begin
          addr_a <= count[8:0];
          data_a <= {24'd0, xr_in};
          wren_a <= 1;
          wren_b <= 0;

          if (count == N - 1) begin
            state <= READ;
            count <= 0;
          end else begin
            count <= count + 1;
          end
        end
        READ: begin
          addr_a <= i1;
          addr_b <= i2;

          wren_a <= 0;
          wren_b <= 0;

          xr_i1  <= q_a[23:0];
          xi_i1  <= q_a[47:24];

          xr_i2  <= q_b[23:0];
          xi_i2  <= q_b[47:24];

          state  <= CALC;
        end
        CALC: begin
          tr = 32'(xr_i1) - 32'(xr_i2);
          xr_i1 <= xr_i1 + xr_i2;
          ti = 32'(xi_i1) - 32'(xi_i2);
          xi_i1 <= xi_i1 + xi_i2;

          cos_tr = cos_read * tr;
          sin_ti = sin_read * ti;
          xr_i2 <= 24'((cos_tr + sin_ti) >>> 15);

          cos_ti = cos_read * ti;
          sin_tr = sin_read * tr;
          xi_i2 <= 24'((cos_ti - sin_tr) >>> 15);

          state <= WRITE;
        end  // case: CALC
        WRITE: begin
          data_a <= {xi_i1, xr_i1};
          data_b <= {xi_i2, xr_i2};

          wren_a <= 1;
          wren_b <= 1;

          state  <= UPDATE;
        end
        UPDATE: begin
          if (11'(i1) + k1 < 11'(N)) begin
            i1 <= 9'(i1 + k1);
            i2 <= 9'(11'(i1) + k1 + k2);
            state <= READ;
          end else if (11'(gcount) + 1 < 11'(k2)) begin
            gcount <= 9'(gcount + 1);
            i1 <= 9'(gcount + 1);
            i2 <= 9'(11'(gcount) + 11'd1 + k2);
            w <= w + dw;
            state <= READ;
          end else begin
            count <= 0;
            state <= REVERSE;
          end
        end  // case: UPDATE
        REVERSE: begin
          addr_a <= rcount;
          addr_b <= rcount;

          wren_a <= 0;
          wren_b <= 0;

          r_fft_valid <= 1'b1;
          r_fftr <= q_a[23:0];
          r_ffti <= q_a[47:24];

          if (count == N - 1) begin
            state <= DONE;
          end else begin
            count <= count + 1;
          end
        end
        DONE: begin
          r_fft_valid <= 'd0;
          state <= START;
        end
      endcase  // case (state)
    end  // else: !if(reset)
  end  // block: if

  assign fftr = r_fftr;
  assign ffti = r_ffti;
  assign fft_valid = r_fft_valid;

  fft_ram x_ram (
      .address_a(addr_a),
      .address_b(addr_b),
      .clock(clk),
      .data_a(data_a),
      .data_b(data_b),
      .wren_a(wren_a),
      .wren_b(wren_b),
      .q_a(q_a),
      .q_b(q_b)
  );

  cos_rom cos_lut (
    .address(w[7:0]),
    .clock(clk),
    .q(cos_read)
  );

  sin_rom sin_lut (
    .address(w[7:0]),
    .clock(clk),
    .q(sin_read)
  );

endmodule  // fft  
