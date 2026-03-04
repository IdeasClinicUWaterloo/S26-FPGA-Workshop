
module fft_512(clk, reset, xr_in, xi_in, fft_valid, fftr, ffti);

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

input wire clk;
input wire reset;
input wire signed [23:0] xr_in, xi_in;
output reg fft_valid;
output reg signed [23:0] fftr, ffti;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/
 
localparam N = 512;    // Number of points
localparam ldN = 9;    // Log_2(N)

// FSM states
localparam start=0, load=1, calc=2, update=3, reverse=4, done=5;
reg [2:0] s;
 
reg [7:0]  w;      
reg [9:0]  i1, i2; 
reg [9:0]  gcount; 
reg [10:0] k1, k2; 
reg [3:0]  stage;  
reg [9:0]  dw;     
reg [10:0] count; 
wire [9:0] rcount;

(* ramstyle = "M10K" *) reg signed [23:0] xr[511:0];
(* ramstyle = "M10K" *) reg signed [23:0] xi[511:0];

reg signed [31:0] tr, ti;
reg signed [31:0] cos_tr, sin_ti, cos_ti, sin_tr;
  
reg signed [15:0] cos_rom [0:255];
reg signed [15:0] sin_rom [0:255];

initial begin
	$readmemh("cos_lut.txt", cos_rom);
	$readmemh("sin_lut.txt", sin_rom);
end

// Combinational bit-reversal logic
assign rcount = {count[0], count[1], count[2], count[3], count[4], 
                 count[5], count[6], count[7], count[8]};
                 
/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/
always @(posedge clk or posedge reset) begin : States
	if (reset) begin
		s <= start; 
      count <= 0;
      gcount <= 0; 
      stage <= 1; 
      i1 <= 0; 
      i2 <= N/2; 
      k1 <= N;
      k2 <= N/2; 
      dw <= 1; 
      w <= 0;
      fft_valid <= 0;
      fftr <= 0; 
      ffti <= 0; 
	end else begin 
		case (s)
			start: begin
				s <= load; 
				count <= 0; 
            w <= 0;
            gcount <= 0; 
            stage <= 1; 
            i1 <= 0; 
            i2 <= N/2; 
            k1 <= N;
            k2 <= N/2; 
            dw <= 1; 
            fft_valid <= 0; 
			end

         load: begin
				xr[count] <= xr_in; 
            xi[count] <= xi_in;
            if (count == N-1) begin
               s <= calc;
               count <= 0;
            end else begin
               count <= count + 1;
            end
			end

			calc: begin
            // Butterfly
            tr = xr[i1] - xr[i2];
            xr[i1] <= xr[i1] + xr[i2];
            ti = xi[i1] - xi[i2];
            xi[i1] <= xi[i1] + xi[i2];

            cos_tr = cos_rom[w] * tr; 
            sin_ti = sin_rom[w] * ti;
            xr[i2] <= (cos_tr + sin_ti) >>> 15;

            cos_ti = cos_rom[w] * ti; 
            sin_tr = sin_rom[w] * tr;
            xi[i2] <= (cos_ti - sin_tr) >>> 15;
                        
            s <= update;
			end

         update: begin
            if (i1 + k1 < N) begin
               i1 <= i1 + k1;
               i2 <= (i1 + k1) + k2;
               s <= calc;
            end else if (gcount + 1 < k2) begin
               gcount <= gcount + 1;
               i1 <= gcount + 1;
               i2 <= gcount + 1 + k2;
               w <= w + dw;
               s <= calc;
            end else if (stage < ldN) begin
               stage <= stage + 1;
               k1 <= k2;
               k2 <= k2 / 2;
               dw <= dw * 2;
               w <= 0;
               gcount <= 0;
               i1 <= 0;
               i2 <= k2 / 2;
               s <= calc;
            end else begin
               count <= 0;
               s <= reverse;
            end
			end

         reverse: begin
				fft_valid <= 1;
            fftr <= xr[rcount]; 
            ffti <= xi[rcount];
            if (count == N-1) begin
               s <= done;
            end else begin
               count <= count + 1;
            end
         end

         done: begin
				fft_valid <= 0;
				s <= start;
         end
		endcase
	end
end
endmodule