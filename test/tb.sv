`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

	logic 		          		MAX10_CLK1_50;
`ifdef ENABLE_ADC_CLOCK
  logic 		          		ADC_CLK_10;
`endif
`ifdef ENABLE_CLOCK2
	logic 		          		MAX10_CLK2_50;
`endif
`ifdef ENABLE_SDRAM
	logic		    [12:0]		DRAM_ADDR;
	logic [1:0]           DRAM_BA;
	logic                 DRAM_CAS_N;
	logic                 DRAM_CKE;
	logic                 DRAM_CLK;
	logic                 DRAM_CS_N;
	logic [15:0]          DRAM_DQ;
	logic                 DRAM_LDQM;
	logic                 DRAM_RAS_N;
	logic                 DRAM_UDQM;
	logic                 DRAM_WE_N;
`endif
`ifdef ENABLE_HEX0
  logic		     [7:0]		HEX0;
`endif
`ifdef ENABLE_HEX1
	logic		     [7:0]		HEX1;
  
`endif
`ifdef ENABLE_HEX2
	logic		     [7:0]		HEX2;
`endif
`ifdef ENABLE_HEX3
	logic		     [7:0]		HEX3;

`endif
`ifdef ENABLE_HEX4
	logic		     [7:0]		HEX4;
  
`endif
`ifdef ENABLE_HEX5
	logic		     [7:0]		HEX5;
  
`endif

	//////////// KEY: 3.3 V SCHMITT TRIGGER //////////
`ifdef ENABLE_KEY
	logic 		     [1:0]		KEY;
  
`endif

	//////////// LED: 3.3-V LVTTL //////////
`ifdef ENABLE_LED
	logic		     [9:0]		LEDR;
  
`endif

	//////////// SW: 3.3-V LVTTL //////////
`ifdef ENABLE_SW
	logic 		     [9:0]		SW;
  
`endif

	//////////// VGA: 3.3-V LVTTL //////////
`ifdef ENABLE_VGA
	logic		     [3:0]		VGA_B;
	logic		     [3:0]		VGA_G;
	logic                 VGA_HS;
  logic		     [3:0]		VGA_R;
	logic                 VGA_VS;
`endif

	//////////// Accelerometer: 3.3-V LVTTL //////////
`ifdef ENABLE_ACCELEROMETER
	logic		          		GSENSOR_CS_N;
	logic [2:1]           GSENSOR_INT;
	logic                 GSENSOR_SCLK;
	logic                 GSENSOR_SDI;
	logic                 GSENSOR_SDO;
`endif

	//////////// Arduino: 3.3-V LVTTL //////////
`ifdef ENABLE_ARDUINO
	logic 		    [15:0]		ARDUINO_IO;
	logic                   ARDUINO_RESET_N;
`endif

	//////////// GPIO, GPIO connect to GPIO Default: 3.3-V LVTTL //////////
`ifdef ENABLE_GPIO
	logic 		    [35:0]		GPIO;
`endif

  // Design Under Test
  top dut(
`ifdef ENABLE_ADC_CLOCK
    .ADC_CLK_10(ADC_CLK_10),
`endif
`ifdef ENABLE_CLOCK2
    .MAX10_CLK2_50(MAX10_CLK2_50),
`endif
`ifdef ENABLE_SDRAM
    .DRAM_ADDR(DRAM_ADDR),
    .DRAM_BA(DRAM_BA),
    .DRAM_CAS_N(DRAM_CAS_N),
    .DRAM_CKE(DRAM_CKE),
    .DRAM_CLK(DRAM_CLK),
    .DRAM_CS_N(DRAM_CS_N),
    .DRAM_DQ(DRAM_DQ),
    .DRAM_LDQM(DRAM_LDQM),
    .DRAM_RAS_N(DRAM_RAS_N),
    .DRAM_UDQM(DRAM_UDQM),
    .DRAM_WE_N(DRAM_WE_N),
`endif
`ifdef ENABLE_HEX0
    .HEX0(HEX0),
`endif
`ifdef ENABLE_HEX1
    .HEX1(HEX1),
`endif
`ifdef ENABLE_HEX2
    .HEX2(HEX2),
`endif
`ifdef ENABLE_HEX3
    .HEX3(HEX3),
`endif
`ifdef ENABLE_HEX4
    .HEX4(HEX4),
`endif
`ifdef ENABLE_HEX5
    .HEX5(HEX5),
`endif
`ifdef ENABLE_KEY
    .KEY(KEY),
`endif
`ifdef ENABLE_LED
    .LEDR(LEDR),
`endif
`ifdef ENABLE_SW
    .SW(SW),
`endif
`ifdef ENABLE_VGA
    .VGA_B(VGA_B),
    .VGA_G(VGA_G),
    .VGA_HS(VGA_HS),
    .VGA_R(VGA_R),
    .VGA_VS(VGA_VS),
`endif
`ifdef ENABLE_ACCELEROMETER
    .GSENSOR_CS_N(GSENSOR_CS_N),
    .GSENSOR_INT(GSENSOR_INT),
    .GSENSOR_SCLK(GSENSOR_SCLK),
    .GSENSOR_SDI(GSENSOR_SDI),
    .GSENSOR_SDO(GSENSOR_SDO),
`endif
`ifdef ENABLE_ARDUINO
    .ARDUINO_IO(ARDUINO_IO),
    .ARDUINO_RESET_N(ARDUINO_RESET_N),
`endif
`ifdef ENABLE_GPIO
    .GPIO(GPIO),
`endif
    .MAX10_CLK1_50(MAX10_CLK1_50)
  );

endmodule
