`timescale 1ns/1ps

module fft_ram #(
    parameter WIDTH = 48,
    parameter DEPTH = 512,
    parameter ADDR_W = $clog2(DEPTH)
)(
    input  wire clock,

    input  wire [ADDR_W-1:0] address_a,
    input  logic signed [WIDTH-1:0]  data_a,
    input  wire              wren_a,
    output logic signed  [WIDTH-1:0]  q_a,

    input  wire [ADDR_W-1:0] address_b,
    input  logic signed [WIDTH-1:0]  data_b,
    input  wire              wren_b,
    output logic signed  [WIDTH-1:0]  q_b
);

reg [WIDTH-1:0] mem [0:DEPTH-1];

integer i;
initial begin
    for (i = 0; i < DEPTH; i = i + 1)
        mem[i] = '0;
        q_a = '0;
        q_b = '0;
end

always @(posedge clock) begin

    // PORT A
    if (wren_a) begin
        mem[address_a] <= data_a;
        q_a <= data_a;
    end
    else begin
        q_a <= mem[address_a];
    end

    // PORT B
    if (wren_b) begin
        mem[address_b] <= data_b;
        q_b <= data_b;
    end
    else begin
        q_b <= mem[address_b];
    end

end

endmodule