#!/bin/bash
rm -rf build/*

export PYTHONPATH="../liteeth:../liteiclink"
../liteeth/liteeth/gen.py --no-compile Nexys4Ethernet_UDP.yml

rm -rf build/*.csv
rm -rf build/software
rm -rf build/gateware/*.sh
rm -rf build/gateware/*.tcl

# remove all lines starting with set_property
