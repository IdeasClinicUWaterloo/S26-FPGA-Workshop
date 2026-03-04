module fft #(
  parameter N = 512
)(
  input clk,
  input reset,
  input signed [23:0] xr_in, xi_in,
  output fft_valid,
  output signed [23:0] fftr, ffti
);

  (* ramstyle = "M10K" *) reg signed [23:0] xr[N-1:0];
  (* ramstyle = "M10K" *) reg signed [23:0] xi[N-1:0];

  enum {START, LOAD, CALC, UPDATE, REVERSE, DONE} state;
  logic [9:0] w;
  logic [9:0]  dw;
  
  logic [8:0] i1, i2;
  logic [8:0] gcount;
  logic [10:0] k1, k2;
  logic [3:0]  stage;

  logic [10:0] count;
  logic [8:0]  rcount;
  logic signed [31:0] tr, ti, cos_tr, cos_ti, sin_tr, sin_ti;

  logic signed [15:0] cos_read;
  logic signed [15:0] sin_read;

  logic               r_fft_valid;
  logic signed [23:0] r_fftr, r_ffti;
  
  
  memory_ro #(
    .BITW(16),
    .N(256),
    .INIT_SRC("cos_lut.txt")
  ) cos_rom_inst(
    .clk(clk),
    .addr(w[7:0]),
    .data(cos_read)
  );

  memory_ro #(
    .BITW(16),
    .N(256),
    .INIT_SRC("sin_lut.txt")
  ) sin_rom_inst(
    .clk(clk),
    .addr(w[7:0]),
    .data(sin_read)
  );

  assign rcount = {count[0] , count[1], count[2], count[3], count[4],
                   count[5], count[6], count[7], count[8]};

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= START;
      count <= 0;
      gcount <= 0;
      stage <= 1;
      i1 <= 0;
      i2 <= 9'(N/2);
      k1 <= N;
      k2 <= N/2;
      dw <= 1;
      w <= 0;
      r_fft_valid <= 0;
      r_fftr <= 0;
      r_ffti <= 0;
    end else begin // if (reset)
      case (state)
        START: begin
          state <= LOAD;
          count <= 0;
          w <= 0;
          gcount <= 0;
          stage <= 1;
          i1 <= 0;
          i2 <= 9'(N/2);
          k1 <= N;
          k2 <= N/2;
          dw <= 1;
          r_fft_valid <= 0;
        end // case: START
        LOAD: begin
          xr[count[8:0]] <= xr_in;
          xi[count[8:0]] <= xi_in;
          if (count == N-1) begin
            state <= CALC;
            count <= 0;
          end else begin
            count <= count + 1;
          end
        end
        CALC: begin
          tr = 32'(xr[i1]) - 32'(xr[i2]);
          xr[i1] <= xr[i1] + xr[i2];
          ti = 32'(xi[i1]) - 32'(xi[i2]);
          xi[i1] <= xi[i1] + xi[i2];

          cos_tr = cos_read * tr;
          sin_ti = sin_read * ti;
          xr[i2] <= 24'((cos_tr + sin_ti) >>> 15);

          cos_ti = cos_read * ti;
          sin_tr = sin_read * tr;
          xi[i2] <= 24'((cos_ti - sin_tr) >>> 15);

          state <= UPDATE;
        end // case: CALC
        UPDATE: begin
          if (11'(i1) + k1 < 11'(N)) begin
            i1 <= 9'(i1 + k1);
            i2 <= 9'(11'(i1) + k1 + k2);
            state <= CALC;
          end else if (11'(gcount) + 1 < 11'(k2)) begin
            gcount <= 9'(gcount + 1);
            i1 <= 9'(gcount + 1);
            i2 <= 9'(11'(gcount) + 11'd1 + k2);
            w <= w + dw;
            state <= CALC;
          end else begin
            count <= 0;
            state <= REVERSE;
          end
        end // case: UPDATE
        REVERSE: begin
          r_fft_valid <= 1'b1;
          r_fftr <= xr[rcount];
          r_ffti <= xi[rcount];
          if (count == N-1) begin
            state <= DONE;
          end else begin
            count <= count + 1;
          end
        end
        DONE: begin
          r_fft_valid <= 'd0;
          state <= START;
        end
      endcase // case (state)
    end // else: !if(reset)
  end // block: if

  assign fftr = r_fftr;
  assign ffti = r_ffti;
  assign fft_valid = r_fft_valid;
  
endmodule // fft  
