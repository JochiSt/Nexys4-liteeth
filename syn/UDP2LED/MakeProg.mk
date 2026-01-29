
.PHONY: prog

prog: bitstream
	openFPGALoader --cable digilent --ftdi-serial 210274552340 --detect
	openFPGALoader --cable digilent --ftdi-serial 210274552340 $(PROJECT).runs/impl_1/$(TOP_MODULE).bit