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
    clock_100MHz = Clock(dut.sys_clock, round(1/100e6*1e9,3), units="ns")    # 100 MHz

    # connect RMII to (virtual) Ethernet PHY
    RMII_CLK_WIRE = dut.rmii_clocks_ref_clk
    RMII_CRS_DV_WIRE = dut.rmii_crs_dv
    RMII_TX_EN_WIRE = dut.rmii_tx_en

    eth_rst = dut.rmii_rst_n
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

    ############################################################################

    ############################################################################
    # Start the clock. Start it low to avoid issues on the first RisingEdge
    cocotb.start_soon(clock_100MHz.start(start_high=False))

    ############################################################################

    # reset the module, wait 2 rising edges until we release reset
    for _ in range(2):
        await RisingEdge(dut.sys_clock)

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
    #sim = os.getenv("SIM", "verilator")
    sim = os.getenv("SIM", "icarus")

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

    print(sources)

    ############################################################################
    # define VHDL sources
    sources += [
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
        build_args=[
            "-s","glbl",
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