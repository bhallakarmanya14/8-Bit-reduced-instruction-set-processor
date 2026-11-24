#!/usr/bin/env bash
set -e

echo "Compiling and running 8-Bit RISC simulation via Icarus Verilog..."
iverilog -g2012 -I rtl -o sim.out rtl/*.sv sim/tb.sv
vvp sim.out
rm -f sim.out waveform.vcd
