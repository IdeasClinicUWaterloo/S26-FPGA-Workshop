
// DIF Butterfly 

module butterfly(clk, reset, w, i_ar, i_ai, i_br, i_bi, o_ar, o_ai, o_br, o_bi, done);

	/*****************************************************************************
	 *                             Port Declarations                             *
	*****************************************************************************/
	
	input wire clk, reset;
	input wire [9:0] w; // twiddle factor index
	
	input wire signed [15:0] i_ar, i_ai; // a
	input wire signed [15:0] i_br, i_bi; // b
	
	output reg signed [15:0] o_ar, o_ai;// A
	output reg signed [15:0] o_br, o_bi;// B
	
	output reg done; 
	
	
	/*****************************************************************************
	 *                 Internal wires and registers Declarations                 *
	 *****************************************************************************/

	// temp register  
	reg signed [15:0] tr, ti; 
	reg signed [31:0] cos_tr, sin_ti, cos_ti, sin_tr;
	
	// twiddle factor registers 
	reg [15:0] cos_rom [0:511];
	reg [15:0] sin_rom [0:511];
	reg signed [15:0] sin;
	reg signed [15:0] cos;
	
	/*****************************************************************************
	 *                             Sequential logic                              *
	 *****************************************************************************/

	// load the lookup for twiddle factors for form: Wn = cos(2*pi*n/N) - j sin(2*pi*n/N)
	initial begin
		$readmemh("cos_512.txt", cos_rom);
		$readmemh("sin_512.txt", sin_rom);
	end

	// every falling edge, get the real and imag of the current twiddle factor
	always @ (negedge clk or posedge reset) begin
		if (reset == 1) begin
			cos <= 0; sin <= 0;
		end else begin
			cos <= cos_rom[w[8:0]];
			sin <= sin_rom[w[8:0]];
		end
	end
	
	// butterfly calculation
	always @(posedge clk or posedge reset) begin
	
		if (reset) begin
			done <= 0;
			
			o_ar <= 0; o_ai <= 0;
			o_br <= 0; o_bi <= 0;

			tr <= 0; ti <= 0;
			cos_tr <= 0; sin_ti <= 0;
			cos_ti <= 0; sin_tr <= 0;
			
		end else begin	
			done <= 0;
			
			// top summation branch: a + b 
			o_ar <= i_ar + i_br; 
			tr <= i_ar - i_br;
			
			o_ai <= i_ai + i_bi; 
			ti <= i_ai - i_bi; 

			// bottom differential branch: (a-b)Wn
			cos_tr <= cos * tr; 
			sin_ti <= sin * ti;
			o_br <= (cos_tr >>> 15) + (sin_ti >>> 15);
			
			cos_ti <= cos * ti;
			sin_tr <= sin * tr;
			o_bi <= (cos_ti >>> 15) - (sin_tr >>> 15);
			
			done <= 1;
		end
	end
  
endmodule