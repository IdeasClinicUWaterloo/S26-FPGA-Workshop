# Makefile
# Attribution: https://github.com/TinyTapeout/ttihp-verilog-template/blob/main/test/Makefile
# Adapted

SIM ?= verilator
TOPLEVEL_LANG ?= verilog   # verilog means Verilog or SystemVerilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = top.sv memory_ro.sv

# Only gate-level SIM
SIM_BUILD = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS += --timing -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.sv
TOPLEVEL = tb
EXTRA_ARGS += --trace --trace-fst --trace-structs

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
