# ----------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
#    <yasu@prosou.nu> wrote this file. As long as you retain this
#    notice you can do whatever you want with this stuff. If we meet
#    some day, and you think this stuff is worth it, you can buy me a
#    beer in return Yasunori Osana at University of the Ryukyus,
#    Japan.
# ----------------------------------------------------------------------
# OpenFC project: an open FPGA accelerated cluster toolkit
# Kyokko project: an open Multi-vendor Aurora 64B/66B-compatible link
#
# This file is to:
#    Setup base project for Xilinx Alveo U50, Kyokko on QSFP
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xcu50-fsvh2104-2-e [current_project]
set_property board_part xilinx.com:au50:1.0 [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]


set RTLs [ list \
               ${TOP}/boards/au50/src/top.v \
               ${TOP}/boards/au50/src/au50-kyokko.sv \
              ]

set COREs [ list \
                fifo_66x512_async \
                gty_w_qpll \
                gty_wo_qpll \
                gty4 \
                ila_0 \
                vio_0 \
           ]

set XDCs [ list \
               ${TOP}/boards/au50/src/au50.xdc \
               ]

source ${TOP}/tcl/kyokko-core.tcl
source ${TOP}/tcl/kyokko-test.tcl

# 

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/au50/ip/${c}.xci
}

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs
