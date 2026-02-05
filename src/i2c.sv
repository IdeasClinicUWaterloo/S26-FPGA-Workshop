module i2c (
    input  wire clk,     // 50 MHz system clock
    input  wire reset,   // active-high reset
    output wire scl,     // I2C clock (push-pull ok on many FPGA boards w/ pullups)
    inout  wire sda      // I2C data (open-drain)
);

    /***************************************************************
                           TIMING SETUP
    ***************************************************************/
    parameter integer CLK_HZ  = 50000000;
    parameter integer I2C_HZ  = 100000;
    parameter integer DIV     = (CLK_HZ/(I2C_HZ*2)); // ~250 for 50 MHz

    // SSM2603: 7-bit 0x1A => 8-bit write 0x34 (if CSB=0)
    localparam [7:0] I2C_ADDR_WR = 8'h34;

    /***************************************************************
                           INIT TABLE
      Each write is: START + (ADDR) + (CTRL_HI) + (CTRL_LO) + STOP
      CTRL_WORD = { reg_addr[6:0], reg_data[8:0] }  (7+9 = 16 bits)
    ***************************************************************/
    localparam N_PAIRS = 8;
    reg [6:0] reg_addr [0:N_PAIRS-1];
    reg [8:0] reg_data [0:N_PAIRS-1];

    initial begin
        reg_addr[0] = 7'h0F; reg_data[0] = 9'h000; // reset
        reg_addr[1] = 7'h06; reg_data[1] = 9'h000; // R6 pre: OUT=1 (off), MIC=1 (off), DAC/ADC/LINEIN on
        reg_addr[2] = 7'h04; reg_data[2] = 9'h012; // analog path (verify bits later)
        reg_addr[3] = 7'h05; reg_data[3] = 9'h000; // digital path
        reg_addr[4] = 7'h07; reg_data[4] = 9'h002; // I2S + 16-bit
        reg_addr[5] = 7'h08; reg_data[5] = 9'h000; // sample rate ctrl
        reg_addr[6] = 7'h09; reg_data[6] = 9'h001; // ACTIVE=1  (must be after VMID delay)
        reg_addr[7] = 7'h06; reg_data[7] = 9'h002; // R6 post: OUT=0 (on), MIC=1 (off), DAC/ADC/LINEIN on
    end

    /***************************************************************
                      OPEN-DRAIN SDA + SCL DRIVER
    ***************************************************************/
    reg scl_r;
    reg sda_drive_low;
    assign scl = scl_r;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    wire sda_in = sda; // (optional) for ACK checking

    /***************************************************************
                    I2C BIT-TICK GENERATOR (half SCL)
    ***************************************************************/
    reg [15:0] div_cnt;
    reg        tick;

    always @(posedge clk) begin
        if (reset) begin
            div_cnt <= 16'd0;
            tick    <= 1'b0;
        end else begin
            if (div_cnt == DIV-1) begin
                div_cnt <= 16'd0;
                tick    <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 16'd1;
                tick    <= 1'b0;
            end
        end
    end

    /***************************************************************
                        VMID DELAY (50 ms)
      NOTE: runs on clk (50 MHz), NOT on tick.
    ***************************************************************/
    localparam integer VMID_DELAY_CYCLES = 2500000; // 50 ms @ 50 MHz
    reg [21:0] vmid_cnt; // enough for 2.5M
    reg        vmid_waiting;

    /***************************************************************
                        I2C STATE MACHINE
    ***************************************************************/
    localparam ST_IDLE       = 5'd0;
    localparam ST_START1     = 5'd1;
    localparam ST_START2     = 5'd2;
    localparam ST_LOAD_BYTE  = 5'd3;
    localparam ST_BIT_LOW    = 5'd4;
    localparam ST_BIT_HIGH   = 5'd5;
    localparam ST_BIT_DONE   = 5'd6;
    localparam ST_ACK_LOW    = 5'd7;
    localparam ST_ACK_HIGH   = 5'd8;
    localparam ST_ACK_DONE   = 5'd9;
    localparam ST_STOP1      = 5'd10;
    localparam ST_STOP2      = 5'd11;
    localparam ST_NEXT_PAIR  = 5'd12;
    localparam ST_WAIT_VMID  = 5'd13;
    localparam ST_DONE       = 5'd14;

    reg [4:0] state;
    reg [7:0] tx_byte;
    reg [3:0] bit_cnt;
    reg [1:0] byte_idx;
    reg [7:0] pair_idx;

    wire [15:0] ctrl_word = { reg_addr[pair_idx], reg_data[pair_idx] };
    wire [7:0]  ctrl_hi   = ctrl_word[15:8];
    wire [7:0]  ctrl_lo   = ctrl_word[7:0];

    always @(posedge clk) begin
        if (reset) begin
            state         <= ST_IDLE;
            scl_r         <= 1'b1;
            sda_drive_low <= 1'b0;
            bit_cnt       <= 4'd7;
            byte_idx      <= 2'd0;
            pair_idx      <= 8'd0;
            tx_byte       <= 8'h00;

            vmid_cnt      <= 22'd0;
            vmid_waiting  <= 1'b0;

        end else begin
            /*************** VMID WAIT runs on clk (not tick) ***************/
            if (state == ST_WAIT_VMID) begin
                // keep bus idle during wait
                scl_r         <= 1'b1;
                sda_drive_low <= 1'b0;

                if (!vmid_waiting) begin
                    vmid_waiting <= 1'b1;
                    vmid_cnt     <= 22'd0;
                end else if (vmid_cnt >= VMID_DELAY_CYCLES[21:0]) begin
                    vmid_waiting <= 1'b0;
                    state        <= ST_START1; // proceed to write ACTIVE (pair_idx already points to it)
                end else begin
                    vmid_cnt <= vmid_cnt + 22'd1;
                end

            end else if (tick) begin
                /*************** I2C FSM runs on tick ***************/
                case (state)
                    ST_IDLE: begin
                        scl_r         <= 1'b1;
                        sda_drive_low <= 1'b0;
                        bit_cnt       <= 4'd7;
                        byte_idx      <= 2'd0;
                        pair_idx      <= 8'd0;
                        state         <= ST_START1;
                    end

                    ST_START1: begin
                        // START: SDA 1->0 while SCL high
                        scl_r         <= 1'b1;
                        sda_drive_low <= 1'b1;
                        state         <= ST_START2;
                    end

                    ST_START2: begin
                        // pull SCL low to begin bit transfers
                        scl_r <= 1'b0;
                        state <= ST_LOAD_BYTE;
                    end

                    ST_LOAD_BYTE: begin
                        case (byte_idx)
                            2'd0: tx_byte <= I2C_ADDR_WR;
                            2'd1: tx_byte <= ctrl_hi;
                            default: tx_byte <= ctrl_lo;
                        endcase
                        state <= ST_BIT_LOW;
                    end

                    ST_BIT_LOW: begin
                        // SCL low: drive next data bit
                        sda_drive_low <= (tx_byte[bit_cnt] == 1'b0);
                        state         <= ST_BIT_HIGH;
                    end

                    ST_BIT_HIGH: begin
                        // SCL high: slave samples
                        scl_r <= 1'b1;
                        state <= ST_BIT_DONE;
                    end

                    ST_BIT_DONE: begin
                        // drop SCL, move to next bit or ACK
                        scl_r <= 1'b0;
                        if (bit_cnt != 0) begin
                            bit_cnt <= bit_cnt - 4'd1;
                            state   <= ST_BIT_LOW;
                        end else begin
                            sda_drive_low <= 1'b0; // release SDA for ACK
                            state         <= ST_ACK_LOW;
                        end
                    end

                    ST_ACK_LOW: begin
                        // raise SCL to sample ACK
                        scl_r <= 1'b1;
                        state <= ST_ACK_HIGH;
                    end

                    ST_ACK_HIGH: begin
                        // optionally check: if (sda_in==1) NACK ...
                        state <= ST_ACK_DONE;
                    end

                    ST_ACK_DONE: begin
                        scl_r <= 1'b0;
                        if (byte_idx != 2'd2) begin
                            byte_idx <= byte_idx + 2'd1;
                            bit_cnt  <= 4'd7;
                            state    <= ST_LOAD_BYTE;
                        end else begin
                            state <= ST_STOP1;
                        end
                    end

                    ST_STOP1: begin
                        // STOP prep: SDA low, SCL high
                        sda_drive_low <= 1'b1;
                        scl_r         <= 1'b1;
                        state         <= ST_STOP2;
                    end

                    ST_STOP2: begin
                        // STOP: release SDA high while SCL high
                        sda_drive_low <= 1'b0;
                        state         <= ST_NEXT_PAIR;
                    end

                    ST_NEXT_PAIR: begin
                        // reset per-write counters
                        bit_cnt  <= 4'd7;
                        byte_idx <= 2'd0;

                        if (pair_idx < (N_PAIRS-1)) begin
                            // If we just finished pair 5 (R8), pause before pair 6 (ACTIVE)
                            if (pair_idx == 8'd5) begin
                                pair_idx <= pair_idx + 8'd1; // advance to ACTIVE entry
                                state    <= ST_WAIT_VMID;
                            end else begin
                                pair_idx <= pair_idx + 8'd1;
                                state    <= ST_START1;
                            end
                        end else begin
                            state <= ST_DONE;
                        end
                    end

                    ST_DONE: begin
                        scl_r         <= 1'b1;
                        sda_drive_low <= 1'b0;
                        state         <= ST_DONE;
                    end

                    default: state <= ST_IDLE;
                endcase
            end
        end
    end

endmodule
