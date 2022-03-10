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
#    Setup base project for Alveo U55C, Kyokko on Dual-QSFP
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xcu55c-fsvh2892-2L-e [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

set RTLs [ list \
               ${TOP}/boards/au55c/src/top.sv \
               ${TOP}/boards/au55c/src/au55-kyokko.sv \
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
               ${TOP}/boards/au55c/src/au55.xdc \
               ]

source ${TOP}/tcl/kyokko-core.tcl
source ${TOP}/tcl/kyokko-test.tcl

# 

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/au55c/ip/${c}.xci
}

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs
