# FPGA Workshop S2026

This is the IDEAS Clinic upcoming FPGA workshop repository.
The objective is to allow students to experience various digital signal processing (DSP) methods through a set of comprehensive one-day activities which build upon each other.
In this way it is similar to the W26 FPGA Workshop.
Both may be run in alternate sequence to introduce students to different FPGA applications.

## Verilator in development

To increase throughput in development time, cocotb and Verilator may be used to run a C++ simulation of the RTL. This technique may also be used in the workshop.
To make use of the simulation and testing features:

1. Install dependencies.
1. Go to `./test`
2. Run `make`: this should build all of the 

NOTE! Memory files must be included in the ./test directory, not the ./src directory.
