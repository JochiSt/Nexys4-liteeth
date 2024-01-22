.PHONY: ghdlana ghdlclean

# move packages to front of source file list
SOURCES_VHDLFiles  = $(shell grep "vhd" files.tcl | grep "pkg")
SOURCES_VHDLFiles += $(shell grep "vhd" files.tcl | grep -v "pkg" )

ghdlana: files.tcl unisim-obj93.cf
	mkdir -p ghdl
	ghdl -a -fsynopsys --workdir=ghdl $(SOURCES_VHDLFiles)

ghdlclean:
	rm -f *.o
	rm -f *.cf
	rm -f ghdl/*

##############################################################################
# Xilinx UNISIM
unisim-obj93.cf:
	ghdl -a --work=unisim $(TOOL_PATH)/../data/vhdl/src/unisims/unisim_VCOMP.vhd