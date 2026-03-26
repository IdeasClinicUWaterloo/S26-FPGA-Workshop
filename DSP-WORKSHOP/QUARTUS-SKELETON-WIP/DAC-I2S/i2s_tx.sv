module i2s_tx (
    input  logic        rst_n,      
    input  logic        bclk,       // Bit Clock
    input  logic [15:0] audio_l,    
    input  logic [15:0] audio_r,    
    
    output logic        lrck,       // Word Select
    output logic        sdata       // Serial Audio Out
);

    logic [5:0] bit_cnt; 
    logic [31:0] shift_reg;
    
    always_ff @(negedge bclk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt   <= 0;
            lrck      <= 0;
            sdata     <= 0;
            shift_reg <= 0;
        end else begin
            bit_cnt <= bit_cnt + 1'b1;
            
            if (bit_cnt == 6'd31) begin
                lrck <= 1'b1; // Right Channel
            end else if (bit_cnt == 6'd63) begin
                lrck <= 1'b0; // Left Channel
            end
            
            if (bit_cnt == 6'd31) begin
                shift_reg <= {audio_r, 16'd0}; 
            end else if (bit_cnt == 6'd63) begin
                shift_reg <= {audio_l, 16'd0}; 
            end else begin
                shift_reg <= {shift_reg[30:0], 1'b0};
            end
            
            sdata <= shift_reg[31];
        end
    end
endmodule

