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
#    Setup base project for a VU35P board, Kyokko on Dual-QSFP
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xcvu35p-fsvh2892-2L-e [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

set RTLs [ list \
               ${TOP}/boards/vu35p/src/top.sv \
               ${TOP}/boards/vu35p/src/vu35p-kyokko.sv \
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
               ${TOP}/boards/vu35p/src/vu35p.xdc \
               ]

source ${TOP}/tcl/kyokko-core.tcl
source ${TOP}/tcl/kyokko-test.tcl

# 

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/vu35p/ip/${c}.xci
}

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs
