
# generate liteeth core
liteeth_core.v: Nexys4Ethernet_UDP.yml
	liteeth_gen --gateware-dir . --no-compile-software $<