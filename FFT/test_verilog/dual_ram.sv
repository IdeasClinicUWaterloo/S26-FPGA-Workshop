module dual_port_ram #(
    parameter DATA_WIDTH = 24,
    parameter ADDR_WIDTH = 9
)(
    // -------- PORT A --------
    input  logic                     clk_a,
    input  logic [ADDR_WIDTH-1:0]    addr_a,
    input  logic [DATA_WIDTH-1:0]    data_a,
    input  logic                     wren_a,
    output logic [DATA_WIDTH-1:0]    q_a,

    // -------- PORT B --------
    input  logic                     clk_b,
    input  logic [ADDR_WIDTH-1:0]    addr_b,
    input  logic [DATA_WIDTH-1:0]    data_b,
    input  logic                     wren_b,
    output logic [DATA_WIDTH-1:0]    q_b
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // -------- PORT A --------
    always_ff @(posedge clk_a) begin
        if (wren_a)
            mem[addr_a] <= data_a;

        q_a <= mem[addr_a];
    end

    // -------- PORT B --------
    always_ff @(posedge clk_b) begin
        if (wren_b)
            mem[addr_b] <= data_b;

        q_b <= mem[addr_b];
    end

endmodule