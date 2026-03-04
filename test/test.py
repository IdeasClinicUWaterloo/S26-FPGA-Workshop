# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.simtime import get_sim_time
import math

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock_50mhz = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock_50mhz.start())

    dut.reset.value = 1
    dut.xr_in.value = 0
    dut.xi_in.value = 0
    await ClockCycles(dut.clk, 10)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    for i in range(10):
        dut.xr_in.value = int(100 * math.sin(2 * math.pi * 10 * i / 512))
        dut.xi_in.value = 0
        await RisingEdge(dut.clk)

    await RisingEdge(dut.fft_valid)

    for i in range(512):
        print(f"Bin {i} | Real: {int(dut.fftr.value)} | Imag: {int(dut.ffti.value)}")
        await RisingEdge(dut.clk)

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
