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
#    Setup base project for Intel Cyclone 10 GX Board, Kyokko on Dual-SFP
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_global_assignment -name FAMILY "Cyclone 10 GX"
set_global_assignment -name TOP_LEVEL_ENTITY c10gx
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name DEVICE 10CX220YF780E5G
# set_global_assignment -name SEARCH_PATH ${top}/path/to/verilog-headers
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SDC_FILE ${TOP}/boards/c10gx/src/c10gx.sdc

set RTLs [ list \
               ${TOP}/boards/c10gx/src/top.v \
               ${TOP}/boards/c10gx/src/c10gx-kyokko.v \
               ${TOP}/boards/c10gx/src/c10-xcvr-2ch.v \
               ${TOP}/src/intel-gx/fifo_66x512_async.v \
              ]

set COREs [ list \
                ${TOP}/boards/c10gx/ip/atx_5g.ip \
                ${TOP}/boards/c10gx/ip/phy_10g.ip \
                ${TOP}/boards/c10gx/ip/phy_rst_ctrl_2ch.ip \
                ${TOP}/boards/c10gx/ip/ila.ip \
                ${TOP}/boards/c10gx/ip/vio.ip \
               ]

set CONSTRs [ list \
                  ${TOP}/boards/c10gx/src/c10gx-constr.tcl ]

source ${TOP}/tcl/kyokko-core.tcl
source ${TOP}/tcl/kyokko-test.tcl


foreach r $RTLs {
    set_global_assignment -name VERILOG_FILE $r
}

foreach c $COREs {
    set_global_assignment -name IP_FILE $c
}

foreach c $CONSTRs {
    source $c
}


