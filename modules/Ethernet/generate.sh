#!/bin/bash
rm -rf build/*

export PYTHONPATH="../liteeth:../liteiclink"
../liteeth/liteeth/gen.py --no-compile Nexys4Ethernet_UDP.yml

rm -rf build/*.csv
rm -rf build/software
rm -rf build/gateware/*.sh
rm -rf build/gateware/*.tcl

# convert verilog to VHDL header for instantiation
python ../../utils/pyVHDLinstTemplate/pyVHDLinstTemplate.py build/gateware/liteeth_core.v

