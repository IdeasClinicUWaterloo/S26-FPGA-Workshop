`timescale 1ns/1ps

module cos_samples_rom (
    input  wire [8:0]  address,
    input  wire        clock,
    output reg  signed [15:0] q
);

    // ROM storage
    reg signed [15:0] mem [0:511];

    // Load ROM contents
    initial begin
        $readmemh("cos_samples.txt", mem);
    end

    // synchronous read
    always @(posedge clock) begin
        q <= mem[address];
    end

endmodule