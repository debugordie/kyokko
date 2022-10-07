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
#    Setup base project for DE10-Pro Rev.B board (with L-tile)
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_global_assignment -name FAMILY "Stratix 10"
set_global_assignment -name TOP_LEVEL_ENTITY de10pro_b
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name DEVICE 1SG280LU2F50E1VG
# set_global_assignment -name SEARCH_PATH ${top}/path/to/verilog-headers
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SDC_FILE ${TOP}/boards/de10pro-b/src/de10pro-b.sdc

set RTLs [ list \
               ${TOP}/boards/de10pro-b/src/top.sv \
               ${TOP}/boards/s10/src/s10-kyokko.sv \
               ${TOP}/boards/s10/src/s10-xcvr-4ch.sv \
               ${TOP}/src/intel-gx/fifo_66x512_async.v \
              ]

set COREs [ list \
                ${TOP}/boards/de10pro-b/ip/atx_5g.ip \
                ${TOP}/boards/de10pro-b/ip/phy_10g_4ch.ip \
                ${TOP}/boards/de10pro-b/ip/phy_rst_ctrl_4ch.ip \
                ${TOP}/boards/de10pro-b/ip/ila.ip \
                ${TOP}/boards/de10pro-b/ip/vio.ip \
               ]

set CONSTRs [ list \
                  ${TOP}/boards/de10pro-b/src/de10pro-b-constr.tcl ]

source ${TOP}/tcl/kyokko-core.tcl
source ${TOP}/tcl/kyokko-test.tcl


foreach r $RTLs {
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


