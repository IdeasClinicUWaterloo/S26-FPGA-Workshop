# FPGA Workshop S2026

Welcome to the intermediate FPGA workshop! 

## Table of Contents

1. [Set-up](workshop_instructions/setup.ipynb)
2. [Lower Volume](workshop_instructions/lower_volume.ipynb)
3. [Robotic Voice Effect](workshop_instructions/robotic_voice.ipynb)
4. [Echo Sound Effect](workshop_instructions/echo.ipynb)
5. [Filters](workshop_instructions/filters.ipynb)
6. [MATLAB for Filter Coefficients](workshop_instructions/matlab_filter.ipynb)

#### Resources
- [SystemVerilog Reference Sheet](reference_sheet.ipynb)
- [SystemVerilog Guide](./systemverilog_guide/table_contents.ipynb)
- [MATLAB Set-up](setup.ipynb)

## Learning Outcomes

### What you should know before this workshop

- Basic signal ideas: amplitude and frequency
- Basic confidence reading and editing SystemVerilog combinational and sequential logic.
- Basic FPGA workflow familiarity: compile, program, and test on hardware in Quartus.

### What you should learn by the end

- How to implement real-time audio DSP blocks in SystemVerilog.
- How to design, build, and test gain, waveform-mixing, delay/echo, and IIR filter effects in verilog.
- How filter coefficients map into a staged SystemVerilog filter module.
- How to verify DSP behavior on FPGA hardware with an edit-compile-program-test loop.

## Required Materials

- FPGA development board
- USB cable for programming
- Monitor
- HDMI cable
- Project files from this repository
- Intel Quartus Prime Lite Edition installed. Click here for instructions on how to install Quartus

## Setup

Start here: [Setup Notebook](workshop_instructions/setup.ipynb)