
module bit_count_serial (
    input  wire        reset,
    input  wire        bclk,
    input  wire        start_word,   // LRCLK edge pulse
    input  wire        send_enable,  // gate while channel active
    input  wire [15:0] data_in,

    output reg         dat
);

    reg [15:0] shifted_reg;
    reg [4:0]  counter;
    reg        skip_bit;

    always @(negedge bclk or posedge reset) begin
        if (reset) begin
            dat         <= 1'b0;
            shifted_reg <= 16'd0;
            counter     <= 5'd0;
            skip_bit    <= 1'b0;
        end else begin
            if (start_word) begin
                shifted_reg <= data_in; // load new word
                counter     <= 5'd0;
                skip_bit    <= 1'b1;    // I2S 1-bit delay
            end else if (send_enable) begin
                if (skip_bit) begin
                    skip_bit <= 1'b0;   // consume skip
                    dat      <= 1'b0;
                end else begin
                    dat         <= shifted_reg[15];          // MSB first
                    shifted_reg <= {shifted_reg[14:0], 1'b0};
                    counter     <= counter + 5'd1;
                end
            end
        end
    end

endmodule
