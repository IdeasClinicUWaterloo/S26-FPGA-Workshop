module memory_ro #(
  parameter BITW = 8,
  parameter N = 1024,
  parameter INIT_SRC
)(
  input                 clk,
  input [$clog2(N)-1:0] addr,
  output [BITW-1:0]     data
);

  logic [BITW-1:0] mem[0:N-1];
  logic [BITW-1:0] reg_data;
  
  initial begin
    $readmemh(INIT_SRC, mem);
  end

  always @(posedge clk) begin
    reg_data <= mem[addr];
  end

  assign data = reg_data;

endmodule
