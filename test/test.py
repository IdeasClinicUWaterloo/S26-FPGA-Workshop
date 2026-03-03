# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock_50mhz = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock_50mhz.start())

    for i in range(0, 1023):
        dut.set_addr.value = i
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

    

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
