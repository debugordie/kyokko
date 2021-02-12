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
#    Setup RTL source list for Kyokko
# ----------------------------------------------------------------------

set RTLs [ concat $RTLs \
               [ list \
                     ${TOP}/src/byte-reverse8.v \
                     ${TOP}/src/teng-sc.v \
                     ${TOP}/src/kyokko-rx-ctrl.v \
                     ${TOP}/src/kyokko-rx-init.v \
                     ${TOP}/src/kyokko-rx-axis.v \
                     ${TOP}/src/kyokko-tx-ctrl.v \
                     ${TOP}/src/kyokko-tx-init.v \
                     ${TOP}/src/kyokko-tx-data.v \
                     ${TOP}/src/kyokko-tx-ufc.v \
                     ${TOP}/src/kyokko-tx-nfc.v \
                     ${TOP}/src/kyokko.v \
                     ${TOP}/src/gt-rst.v \
                     ${TOP}/src/rxpath-rst.v \
                    ] ]

