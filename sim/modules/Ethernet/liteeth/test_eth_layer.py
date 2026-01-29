# general imports
import os
import sys
sys.path.insert(0, os.path.join( os.path.dirname(__file__), "../../../../python/cocotbext/cocotbext-eth" ) )

################################################################################
# SCAPY imports
#import scapy.all as scapy

################################################################################
# cocotb imports
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import Timer, First

# cocotb extension imports
from cocotbext.eth import GmiiFrame, RmiiPhy

################################################################################
# list all signals
#       from slide 33 of
#           https://github.com/lukedarnell/cocotb/blob/master/tests/test_cases/orconf2018/cocotb_orconf2018.pdf
#@cocotb.test()
async def list_signals(dut):
    for design_element in dut:
        dut._log.info("Found %s : python type = %s:"%(design_element, type(design_element)))
        dut._log.info("         : _name = %s"%(design_element._name))
        dut._log.info("         : _path = %s"%(design_element._path))

    raise cocotb.pass_test()

################################################################################
#         _      ____    ____
#        / \    |  _ \  |  _ \
#       / _ \   | |_) | | |_) |
#      / ___ \  |  _ <  |  __/
#     /_/   \_\ |_| \_\ |_|
#
# test proper ARP  packet receiving
@cocotb.test()
async def test_arp_reply(dut):

    # generate needed clocks
    clock_100MHz = Clock(dut.sys_clock, round(1/100e6*1e9,3), unit="ns")    # 100 MHz

    # connect RMII to (virtual) Ethernet PHY
    RMII_CLK_WIRE = dut.rmii_clocks_ref_clk
    RMII_CRS_DV_WIRE = dut.rmii_crs_dv
    RMII_TX_EN_WIRE = dut.rmii_tx_en

    # set initial values
    dut.rmii_rst_n.value = 1   # de-assert reset

    ############################################################################
    # wait some time
    #cocotb.log.info("Waiting some ns ...")
    #Timer(10, "ns")   # wait some time
    #cocotb.log.info("... done")

    ############################################################################
    # RMII PHY signals
    cocotb.log.info("Init RMII PHY ...")
    eth_rst = None #dut.rmii_rst_n
    eth_rx_err = None

    # initiate RMII PHY
    rmii_phy = RmiiPhy(
        dut.rmii_tx_data,
        RMII_TX_EN_WIRE,
        RMII_CLK_WIRE,
        dut.rmii_rx_data,
        eth_rx_err,
        RMII_CRS_DV_WIRE,
        eth_rst,
        speed=100e6
        )

    cocotb.log.info("... done")

    ############################################################################
    # Start the clock. Start it low to avoid issues on the first RisingEdge
    cocotb.log.info("Starting clock ...")
    await cocotb.start_soon(clock_100MHz.start(start_high=False))
    cocotb.log.info("... done")

    ############################################################################
    # wait some time
    cocotb.log.info("Waiting some clock cycles ...")
    for N in range(10):
        cocotb.log.info("  waiting cycle %d ..."%(N))
        await RisingEdge(dut.sys_clock)
        cocotb.log.info("  ... done")
    cocotb.log.info("... done")

    ############################################################################
    # reset the DUT and everything else
    cocotb.log.info("Asserting reset ...")

    dut.rmii_rst_n.value = 0   # assert reset

    # reset the module, wait 2 rising edges until we release reset
    for _ in range(10):
        await RisingEdge(dut.sys_clock)

    dut.rmii_rst_n.value = 1   # de-assert reset

    cocotb.log.info("... released reset")

    ############################################################################
    # scapy -> cocotb
    # send an ARP request packet

    pcap_packets = []   # store packets, which should be written to disk

    FPGA_IP = "192.168.1.20"

    arp_packet = scapy.Ether() / scapy.ARP(pdst=FPGA_IP)
    arp_packet.show()
    pcap_packets.append(arp_packet)

    arp_frame = GmiiFrame.from_payload( scapy.raw(arp_packet))

    await rmii_phy.rx.send( arp_frame )     # send out ARP packet

    ############################################################################
    # cocotb -> scapy

    timeout = Timer(50, "us")
    tx_data = cocotb.start_soon(rmii_phy.tx.recv())
    result = await First(timeout, tx_data)
    print(result)
    assert result is not timeout, ".... time out ...."

    # Dissect the packet
    arp_reply_packet = scapy.Ether(bytes(result.get_payload()))

    # Display the summary of each layer in the packet
    arp_reply_packet.show()

    # save packet as PCAP file
    pcap_packets.append(arp_reply_packet)
    # write packets to disk
    scapy.wrpcap("arp_packets.cap",pcap_packets)

    assert arp_reply_packet.psrc == FPGA_IP

    ############################################################################
    # wait some time
    for _ in range(20):
        await RisingEdge(dut.pll_clk)

################################################################################
from cocotb_tools.runner import get_runner
from pathlib import Path

def test_eth_layer_runner():
    # get environment variable or default
    sim = os.getenv("SIM", "verilator")    # uses verilator
    #sim = os.getenv("SIM", "ghdl")    # uses ghdl
    #sim = os.getenv("SIM", "icarus")    # uses iverilog

    # get path to this file
    proj_path = Path(__file__).resolve().parent
    MODULES_FOLDER = proj_path / "../../../../"

    ############################################################################
    # add Xilinx unisim
    sources = []

    #for files in os.listdir("/tools/Xilinx/Vivado/2024.2/data/verilog/src/unisims"):
    #    if files.endswith(".v"):
    sources += ["/tools/Xilinx/Vivado/2024.2/data/verilog/src/" + "glbl.v"]
    sources += ["/tools/Xilinx/Vivado/2024.2/data/verilog/src/unisims/" + "FDPE.v"]

    ############################################################################
    # define verilog sources
    sources += [
        MODULES_FOLDER / "modules" / "Ethernet" / "liteeth" / "liteeth_core.v",
    ]

    ############################################################################
    # build the runner
    runner = get_runner(sim)
    runner.build(
        sources=sources,

        # build arguments for GHDL
        #build_args=[
        #    "--std=08",
        #    "-frelaxed",
        #    "-Wno-unhandled-attribute",
        #    "-Wno-hide",
        #    ],

        # for icarus/verilator
        #build_args=[
        #    "-s","glbl",    # add glbl as additional top level for Xilinx designs
        #    ],

        # for verilator
        build_args=[
        #    "--top-module","glbl",  # add glbl as additional top level for Xilinx designs
            "--bbox-unsup",         # disable warnings about unsupported constructs
            "--timing",             # timing
            ],
        hdl_toplevel="liteeth_core",
        always=True,   # build always?
        timescale=("1ns", "1ps"),
        waves=True,
    )

    ############################################################################
    # execute the test
    runner.test(
        hdl_toplevel="liteeth_core",
        test_module="test_eth_layer",
        waves=True,         # store traces
        parameters={
            },
        plusargs =  [
            "--wave=test_eth_layer.ghw", # store waves into file
            ],
    )

if __name__ == "__main__":
    test_eth_layer_runner()