action = "synthesis"
target = "xilinx"

incl_makefiles = [
    "MakeProg.mk",
]

# FPGA on the Nexys4 Board
syn_device = "xc7a100t"
syn_grade = "-1"
syn_package = "csg324"

# set project name and top module
syn_top = "EthernetTest"
syn_project = "EthernetTest"

# use VIVADO as synthesis tool
syn_tool = "vivado"

# when done with bitstream generation, remove jou and log files from vivado
syn_pre_bitstream_cmd = "rm -rf *.jou *.log"
syn_post_bitstream_cmd = "rm -rf *.jou"

syn_properties = [
    #["steps.synth_design.args.more options", "-verbose"],
    ["steps.synth_design.args.retiming", "1"],
    ["steps.synth_design.args.assert", "1"],

    ["steps.opt_design.args.verbose", "0"],
    ["steps.opt_design.args.directive", "Explore"],
    ["steps.opt_design.is_enabled", "1"],

    #["steps.place_design.args.more options", "-verbose"],
    ["steps.place_design.args.directive", "Explore"],

    #["steps.phys_opt_design.args.more options", "-verbose"],
    ["steps.phys_opt_design.args.directive", "AlternateFlowWithRetiming"],
    ["steps.phys_opt_design.is_enabled", "1"],

    #["steps.route_design.args.more options", "-verbose"],
    ["steps.route_design.args.directive", "Explore"],

    #["steps.post_route_phys_opt_design.args.more options", "-verbose"],
    ["steps.post_route_phys_opt_design.args.directive", "AddRetime"],
    ["steps.post_route_phys_opt_design.is_enabled", "1"],

    ["steps.write_bitstream.args.verbose", "0"],
    ]

# modules, which needed to be included
modules = {
    "local": [
        "../modules/Ethernet",
    ],
}

# local files needed for synthesis
files = [
    "EthernetTest.vhdl",
    "Nexys-4-Master.xdc"
    ]
