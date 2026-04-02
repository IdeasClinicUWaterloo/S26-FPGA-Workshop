module impulse_generator (
    input  logic clk,
    input  logic reset,
    output logic impulse
);

    // 2 seconds at 48.1 kHz
    localparam int MAX_COUNT = 96200;

    // Enough bits to hold 96200
    logic [$clog2(MAX_COUNT)-1:0] counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            impulse <= 0;
        end else begin
            if (counter == MAX_COUNT - 1) begin
                counter <= 0;
                impulse <= 1;   // 1-cycle impulse
            end else begin
                counter <= counter + 1;
                impulse <= 0;
            end
        end
    end

endmodule