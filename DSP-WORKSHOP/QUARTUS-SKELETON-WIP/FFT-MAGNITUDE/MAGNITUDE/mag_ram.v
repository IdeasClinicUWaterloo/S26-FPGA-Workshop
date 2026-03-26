`timescale 1 ps / 1 ps
// Simple inferred dual-clock dual-port RAM for magnitudes.
//
// Port A: write clocked by `clock_a` (FFT clock domain)
// Port B: read clocked by `clock_b` (pixel clock domain)
//
// The wizard-generated version in this repo was configured incorrectly
// (8 words / 3-bit address). We need 512 words for a 512-point FFT.
module mag_ram #(
  parameter integer ADDR_WIDTH = 9,
  parameter integer DATA_WIDTH = 24
) (
  input  wire [ADDR_WIDTH-1:0] address_a,
  input  wire [ADDR_WIDTH-1:0] address_b,
  input  wire                  clock_a,
  input  wire                  clock_b,
  input  wire [DATA_WIDTH-1:0] data_a,
  input  wire [DATA_WIDTH-1:0] data_b,
  input  wire                  wren_a,
  input  wire                  wren_b,
  output reg  [DATA_WIDTH-1:0] q_a,
  output reg  [DATA_WIDTH-1:0] q_b
);

  localparam integer DEPTH = (1 << ADDR_WIDTH);

  (* ramstyle = "M10K" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Port A (write/readback in FFT clock domain)
  always @(posedge clock_a) begin
    q_a <= mem[address_a];
    if (wren_a) mem[address_a] <= data_a;
  end

  // Port B (read in pixel clock domain; write disabled by design)
  always @(posedge clock_b) begin
    if (wren_b) mem[address_b] <= data_b;
    q_b <= mem[address_b];
  end

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: BYTEENA_ACLR_A NUMERIC "0"
// Retrieval info: PRIVATE: BYTEENA_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_ENABLE_A NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_ENABLE_B NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_SIZE NUMERIC "8"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLRdata NUMERIC "0"
// Retrieval info: PRIVATE: CLRq NUMERIC "0"
// Retrieval info: PRIVATE: CLRrdaddress NUMERIC "0"
// Retrieval info: PRIVATE: CLRrren NUMERIC "0"
// Retrieval info: PRIVATE: CLRwraddress NUMERIC "0"
// Retrieval info: PRIVATE: CLRwren NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "5"
// Retrieval info: PRIVATE: Clock_A NUMERIC "0"
// Retrieval info: PRIVATE: Clock_B NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: INDATA_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: INDATA_REG_B NUMERIC "1"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_A"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "512"
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: MIFfilename STRING ""
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "3"
// Retrieval info: PRIVATE: OUTDATA_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: OUTDATA_REG_B NUMERIC "1"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "2"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_PORT_A NUMERIC "3"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_PORT_B NUMERIC "3"
// Retrieval info: PRIVATE: REGdata NUMERIC "1"
// Retrieval info: PRIVATE: REGq NUMERIC "1"
// Retrieval info: PRIVATE: REGrdaddress NUMERIC "0"
// Retrieval info: PRIVATE: REGrren NUMERIC "0"
// Retrieval info: PRIVATE: REGwraddress NUMERIC "1"
// Retrieval info: PRIVATE: REGwren NUMERIC "1"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: USE_DIFF_CLKEN NUMERIC "0"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "64"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "64"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "64"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "64"
// Retrieval info: PRIVATE: WRADDR_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: WRADDR_REG_B NUMERIC "1"
// Retrieval info: PRIVATE: WRCTRL_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: enable NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "0"
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK1"
// Retrieval info: CONSTANT: CLOCK_ENABLE_INPUT_A STRING "BYPASS"
// Retrieval info: CONSTANT: CLOCK_ENABLE_INPUT_B STRING "BYPASS"
// Retrieval info: CONSTANT: CLOCK_ENABLE_OUTPUT_A STRING "BYPASS"
// Retrieval info: CONSTANT: CLOCK_ENABLE_OUTPUT_B STRING "BYPASS"
// Retrieval info: CONSTANT: INDATA_REG_B STRING "CLOCK1"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "8"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "BIDIR_DUAL_PORT"
// Retrieval info: CONSTANT: OUTDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_REG_A STRING "CLOCK0"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "CLOCK1"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "M10K"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_PORT_A STRING "NEW_DATA_NO_NBE_READ"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_PORT_B STRING "NEW_DATA_NO_NBE_READ"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "3"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "3"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "64"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "64"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_B NUMERIC "1"
// Retrieval info: CONSTANT: WRCONTROL_WRADDRESS_REG_B STRING "CLOCK1"
// Retrieval info: USED_PORT: address_a 0 0 3 0 INPUT NODEFVAL "address_a[2..0]"
// Retrieval info: USED_PORT: address_b 0 0 3 0 INPUT NODEFVAL "address_b[2..0]"
// Retrieval info: USED_PORT: clock_a 0 0 0 0 INPUT VCC "clock_a"
// Retrieval info: USED_PORT: clock_b 0 0 0 0 INPUT NODEFVAL "clock_b"
// Retrieval info: USED_PORT: data_a 0 0 64 0 INPUT NODEFVAL "data_a[63..0]"
// Retrieval info: USED_PORT: data_b 0 0 64 0 INPUT NODEFVAL "data_b[63..0]"
// Retrieval info: USED_PORT: q_a 0 0 64 0 OUTPUT NODEFVAL "q_a[63..0]"
// Retrieval info: USED_PORT: q_b 0 0 64 0 OUTPUT NODEFVAL "q_b[63..0]"
// Retrieval info: USED_PORT: wren_a 0 0 0 0 INPUT GND "wren_a"
// Retrieval info: USED_PORT: wren_b 0 0 0 0 INPUT GND "wren_b"
// Retrieval info: CONNECT: @address_a 0 0 3 0 address_a 0 0 3 0
// Retrieval info: CONNECT: @address_b 0 0 3 0 address_b 0 0 3 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock_a 0 0 0 0
// Retrieval info: CONNECT: @clock1 0 0 0 0 clock_b 0 0 0 0
// Retrieval info: CONNECT: @data_a 0 0 64 0 data_a 0 0 64 0
// Retrieval info: CONNECT: @data_b 0 0 64 0 data_b 0 0 64 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren_a 0 0 0 0
// Retrieval info: CONNECT: @wren_b 0 0 0 0 wren_b 0 0 0 0
// Retrieval info: CONNECT: q_a 0 0 64 0 @q_a 0 0 64 0
// Retrieval info: CONNECT: q_b 0 0 64 0 @q_b 0 0 64 0
// Retrieval info: GEN_FILE: TYPE_NORMAL mag_ram.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL mag_ram.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL mag_ram.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL mag_ram.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL mag_ram_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL mag_ram_bb.v TRUE
// Retrieval info: LIB_FILE: altera_mf
