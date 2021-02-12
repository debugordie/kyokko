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
#    Setup RTL source list for Kyokko test pattern generator
# ----------------------------------------------------------------------

set RTLs [ concat $RTLs \
               [ list \
                     ${TOP}/src/test/tx-frame-gen.v \
                     ${TOP}/src/test/tx-ufc-gen.v \
                     ${TOP}/src/test/tx-nfc-gen.v \
                    ] ]
