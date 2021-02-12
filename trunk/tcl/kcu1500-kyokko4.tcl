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
#    Setup base project for Xilinx KCU1500, Kyokko on Dual-SFP (x4 bonding)
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xcku115-flvb2104-2-e [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]


set RTLs [ list \
               ${TOP}/boards/kcu1500/src/top.v \
               ${TOP}/boards/kcu1500/src/kcu1500-kyokko.v \
               ${TOP}/src/kyokko-cb.v \
               ${TOP}/src/kyokko-rx-cb.v \
               ${TOP}/src/test/tx-ufc-gen4.v \
               ${TOP}/src/test/tx-frame-gen4.v \
              ]

set COREs [ list \
                clk_300_100 \
                fifo_66x512_async \
                gth4 \
                ila4_0 \
                vio_0 \
           ]

set XDCs [ list \
               ${TOP}/boards/kcu1500/src/kcu1500.xdc \
               ]

source ${TOP}/tcl/kyokko-core.tcl
source ${TOP}/tcl/kyokko-test.tcl

# 

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/kcu1500/ip/${c}.xci
}

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs

set_property generic BondingEnable=1 [current_fileset]
