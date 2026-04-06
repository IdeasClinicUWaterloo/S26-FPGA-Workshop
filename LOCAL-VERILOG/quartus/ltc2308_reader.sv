module ltc2308_reader (
    input  logic        clk,           // 50 MHz Master Clock
    input  logic        rst_n,         // Active-low reset
    input  logic        measure_start, // High to trigger reading
    input  logic [2:0]  channel,       // ADC Channel
    
    output logic        adc_convst,    // Conversion Start
    output logic        adc_sck,       // SPI Clock (Master out)
    output logic        adc_sdi,       // SPI Data In (Master out)
    input  logic        adc_sdo,       // SPI Data Out (Master in)
    
    output logic [11:0] data_out,      // The raw audio payload
    output logic        data_valid     // Pulses high for 1 tick when data is ready
);

    localparam IDLE    = 2'd0;
    localparam CONVST  = 2'd1;
    localparam READ    = 2'd2;
    localparam DONE    = 2'd3;

    logic [1:0]  state;
    logic [7:0]  delay_cnt;
    logic [4:0]  bit_cnt;
    logic [11:0] shift_in;
    logic [5:0]  config_cmd;

    // Dynamically maps the multiplexer bits based on the selected channel
    assign config_cmd = {1'b1, channel[0], channel[2], channel[1], 2'b00};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            adc_convst  <= 1'b0;
            adc_sck     <= 1'b0;
            adc_sdi     <= 1'b0;
            data_out    <= 12'd0;
            data_valid  <= 1'b0;
            delay_cnt   <= 8'd0;
            bit_cnt     <= 5'd0;
            shift_in    <= 12'd0;
        end else begin
            data_valid <= 1'b0; 
            
            case (state)
                IDLE: begin
                    adc_convst <= 1'b0;
                    adc_sck    <= 1'b0;
                    if (measure_start) begin
                        state      <= CONVST;
                        delay_cnt  <= 8'd0;
                        adc_convst <= 1'b1; 
                    end
                end
                
                CONVST: begin
                    if (delay_cnt < 8'd100) begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end else begin
                        adc_convst <= 1'b0;
                        adc_sdi    <= config_cmd[5]; 
                        state      <= READ;
                        delay_cnt  <= 8'd0;
                        bit_cnt    <= 5'd0;
                    end
                end
                
                READ: begin
                    delay_cnt <= delay_cnt + 1'b1;
                    
                    if (delay_cnt == 8'd1) begin
                        adc_sck <= 1'b1; 
                        shift_in <= {shift_in[10:0], adc_sdo};
                        
                    end else if (delay_cnt == 8'd3) begin
                        adc_sck <= 1'b0; 
                        
                        if (bit_cnt < 5) begin
                            adc_sdi <= config_cmd[4 - bit_cnt];
                        end else begin
                            adc_sdi <= 1'b0; 
                        end
                        
                        bit_cnt   <= bit_cnt + 1'b1;
                        delay_cnt <= 8'd0;
                        
                        if (bit_cnt == 5'd11) begin
                            state <= DONE;
                        end
                    end
                end
                
                DONE: begin
                    data_out   <= shift_in;     
                    data_valid <= 1'b1;         
                    state      <= IDLE;         
                end
            endcase
        end
    end
endmodule

