`timescale 1ns/1ps

module cos_rom (
    input  wire [7:0]  address,
    input  wire        clock,
    output reg  signed [15:0] q
);

    // ROM storage
    reg signed [15:0] mem [0:255];

    // Load ROM contents
    initial begin
        $readmemh("cos_lut.txt", mem);
    end

    // synchronous read
    always @(posedge clock) begin
        q <= mem[address];
    end

endmodule