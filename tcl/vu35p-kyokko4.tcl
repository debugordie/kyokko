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
#    Setup base project for a VU35P board, Kyokko on Dual-QSFP (x4 bonding)
# ----------------------------------------------------------------------


source [file join [file dirname [info script]] "config.tcl"]
source ${TOP}/tcl/vu35p-kyokko.tcl

source ${TOP}/tcl/kyokko-cb.tcl

set CBCOREs [ list \
                  ila4_0 ]

#

set CBCOREFILEs [list ]
foreach c $CBCOREs {
    lappend CBCOREFILEs ${TOP}/boards/vu35p/ip/${c}.xci
}

import_files -flat $CBCOREFILEs
add_files $CBRTLs

set_property generic BondingEnable=1 [current_fileset]
