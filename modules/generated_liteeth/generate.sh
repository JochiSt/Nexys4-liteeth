#!/bin/bash
rm -rf build/*

export PYTHONPATH="../liteeth:../liteiclink"
../liteeth/liteeth/gen.py --no-compile Nexys4Ethernet_UDP.yml
