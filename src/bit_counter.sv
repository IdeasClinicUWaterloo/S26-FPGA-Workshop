module bit_counter_deserial(
    input  wire        reset,
    input  wire        bclk,
    input  wire        dat,
    input  wire        start_read,   // gate shifting while high

    output reg  [15:0] data,
    output reg         data_valid
);

    reg [15:0] shifted_reg;
    reg [4:0]  counter;
    reg        skip_bit;

    always @(negedge bclk or posedge reset) begin
        if (reset) begin
            data        <= 16'd0;
            data_valid  <= 1'b0;
            shifted_reg <= 16'd0;
            counter     <= 5'd0;
            skip_bit    <= 1'b1;   // skip first bit after start_read begins
        end else begin
            data_valid <= 1'b0;    // default: pulse for 1 cycle only

            if (!start_read) begin
                // not reading: reset for the next word
                shifted_reg <= 16'd0;
                counter     <= 5'd0;
                skip_bit    <= 1'b1;
            end else begin
                // reading this word
                if (skip_bit) begin
                    skip_bit <= 1'b0;      // consume the I2S 1-bit offset
                end else begin
                    shifted_reg <= {shifted_reg[14:0], dat};
                    counter     <= counter + 5'd1;

                    if (counter == 5'd15) begin
                        data       <= {shifted_reg[14:0], dat};
                        data_valid <= 1'b1; // 16 bits collected
                    end
                end
            end
        end
    end

endmodule