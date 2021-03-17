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
#    Setup base project for Gidel HawkEye-40G-48 (w/ Arria 10 GX 480)
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_global_assignment -name FAMILY Arria10
set_global_assignment -name TOP_LEVEL_ENTITY hawkeye
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name DEVICE 10AX048E4F29E3SG
# set_global_assignment -name SEARCH_PATH ${top}/path/to/verilog-headers
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SDC_FILE ${TOP}/boards/hawkeye/src/hawkeye.sdc

set RTLs [ list \
               ${TOP}/boards/hawkeye/src/top.sv \
               ${TOP}/boards/hawkeye/src/hawkeye-kyokko.sv \
               ${TOP}/boards/hawkeye/src/a10-xcvr-cb4.sv \
               ${TOP}/src/intel-gx/fifo_66x512_async.v \
              ]

set COREs [ list \
                ${TOP}/boards/hawkeye/ip/atx_5g_4cb.ip \
                ${TOP}/boards/hawkeye/ip/phy_10g_4cb.ip \
                ${TOP}/boards/hawkeye/ip/phy_rst_ctrl_4ch.ip \
                ${TOP}/boards/hawkeye/ip/ila.ip \
                ${TOP}/boards/hawkeye/ip/vio.ip \
               ]

set CONSTRs [ list \
                  ${TOP}/boards/hawkeye/src/hawkeye-constr.tcl ]

source ${TOP}/tcl/kyokko-core.tcl
source ${TOP}/tcl/kyokko-cb.tcl
source ${TOP}/tcl/kyokko-test.tcl


foreach r [concat $RTLs $CBRTLs] {
    if {[fileext $r] == "sv"} {
        set_global_assignment -name SYSTEMVERILOG_FILE $r
    } else {
        set_global_assignment -name VERILOG_FILE $r
    }
}

foreach c $COREs {
    set_global_assignment -name IP_FILE $c
}

foreach c $CONSTRs {
    source $c
}

set_parameter -name BondingEnable 1

