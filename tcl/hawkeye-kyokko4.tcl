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
source ${TOP}/tcl/hawkeye-kyokko.tcl

source ${TOP}/tcl/kyokko-cb.tcl

lappend CBRTLs ${TOP}/boards/hawkeye/src/a10-xcvr-cb4.sv

set CBCOREs [ list \
                ${TOP}/boards/hawkeye/ip/atx_5g_4cb.ip \
                ${TOP}/boards/hawkeye/ip/phy_10g_4cb.ip \
               ]

foreach r $CBRTLs {
    if {[fileext $r] == "sv"} {
        set_global_assignment -name SYSTEMVERILOG_FILE $r
    } else {
        set_global_assignment -name VERILOG_FILE $r
    }
}

foreach c $CBCOREs {
    set_global_assignment -name IP_FILE $c
}

set_parameter -name BondingEnable 1

