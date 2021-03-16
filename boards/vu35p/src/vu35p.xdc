# PCIe reset

set_property PACKAGE_PIN BF41     [get_ports PCIE_RESET_N]
set_property IOSTANDARD  LVCMOS18 [get_ports PCIE_RESET_N]

# User clk @ 100MHz

set_property PACKAGE_PIN BM8      [get_ports SI_RSTBB]
set_property IOSTANDARD  LVCMOS18 [get_ports SI_RSTBB]

set_property PACKAGE_PIN BK44     [get_ports SLR0_CLK100N]
set_property PACKAGE_PIN BK43     [get_ports SLR0_CLK100P]

set_property PACKAGE_PIN BL10     [get_ports SLR1_CLK100N]
set_property PACKAGE_PIN BK10     [get_ports SLR1_CLK100P]

set_property IOSTANDARD  LVDS \
    [get_ports {SLR0_CLK100P SLR0_CLK100N SLR1_CLK100P SLR1_CLK100N}]

create_clock -period 10.0 -name clk100_0 [get_ports SLR0_CLK100P]
create_clock -period 10.0 -name clk100_1 [get_ports SLR1_CLK100P]

# QSFP GTrefclk @ 161.1328125MHz, MGTREFCLK0_130

set_property PACKAGE_PIN AD43     [get_ports CLK161N]
set_property PACKAGE_PIN AD42     [get_ports CLK161P]

create_clock -period 6.20606 -name clk161 [get_ports CLK161P]

# QSFP signals: QSFP0 on Bank 130, QSFP1 on Bank 131

set_property PACKAGE_PIN AD52     [get_ports QSFP0_RXN[0]]
set_property PACKAGE_PIN AC54     [get_ports QSFP0_RXN[1]]
set_property PACKAGE_PIN AC50     [get_ports QSFP0_RXN[2]]
set_property PACKAGE_PIN AB52     [get_ports QSFP0_RXN[3]]
set_property PACKAGE_PIN AD51     [get_ports QSFP0_RXP[0]]
set_property PACKAGE_PIN AC53     [get_ports QSFP0_RXP[1]]
set_property PACKAGE_PIN AC49     [get_ports QSFP0_RXP[2]]
set_property PACKAGE_PIN AB51     [get_ports QSFP0_RXP[3]]
set_property PACKAGE_PIN AD47     [get_ports QSFP0_TXN[0]]
set_property PACKAGE_PIN AC45     [get_ports QSFP0_TXN[1]]
set_property PACKAGE_PIN AB47     [get_ports QSFP0_TXN[2]]
set_property PACKAGE_PIN AA49     [get_ports QSFP0_TXN[3]]
set_property PACKAGE_PIN AD46     [get_ports QSFP0_TXP[0]]
set_property PACKAGE_PIN AC44     [get_ports QSFP0_TXP[1]]
set_property PACKAGE_PIN AB46     [get_ports QSFP0_TXP[2]]
set_property PACKAGE_PIN AA48     [get_ports QSFP0_TXP[3]]
set_property PACKAGE_PIN AA54     [get_ports QSFP1_RXN[0]]
set_property PACKAGE_PIN Y52      [get_ports QSFP1_RXN[1]]
set_property PACKAGE_PIN W54      [get_ports QSFP1_RXN[2]]
set_property PACKAGE_PIN V52      [get_ports QSFP1_RXN[3]]
set_property PACKAGE_PIN AA53     [get_ports QSFP1_RXP[0]]
set_property PACKAGE_PIN Y51      [get_ports QSFP1_RXP[1]]
set_property PACKAGE_PIN W53      [get_ports QSFP1_RXP[2]]
set_property PACKAGE_PIN V51      [get_ports QSFP1_RXP[3]]
set_property PACKAGE_PIN AA45     [get_ports QSFP1_TXN[0]]
set_property PACKAGE_PIN Y47      [get_ports QSFP1_TXN[1]]
set_property PACKAGE_PIN W49      [get_ports QSFP1_TXN[2]]
set_property PACKAGE_PIN W45      [get_ports QSFP1_TXN[3]]
set_property PACKAGE_PIN AA44     [get_ports QSFP1_TXP[0]]
set_property PACKAGE_PIN Y46      [get_ports QSFP1_TXP[1]]
set_property PACKAGE_PIN W48      [get_ports QSFP1_TXP[2]]
set_property PACKAGE_PIN W44      [get_ports QSFP1_TXP[3]]

# Link Status LEDs

set_property PACKAGE_PIN BK14     [get_ports QSFP1_ACT]
set_property PACKAGE_PIN BK15     [get_ports QSFP1_LEDG]
set_property PACKAGE_PIN BL12     [get_ports QSFP1_LEDY]
set_property PACKAGE_PIN BL13     [get_ports QSFP0_ACT]
set_property PACKAGE_PIN BK11     [get_ports QSFP0_LEDG]
set_property PACKAGE_PIN BJ11     [get_ports QSFP0_LEDY]

set_property IOSTANDARD  LVCMOS18 \
 [get_ports { QSFP1_ACT QSFP1_LEDG QSFP1_LEDY QSFP0_ACT QSFP0_LEDG QSFP0_LEDY} ]


# Clocking stuff

connect_debug_port dbg_hub/clk [get_nets CLK100]

set_false_path -from \
    [get_pins -match_style ucf */rxinit/LINK_ERR_TIMER_reg[*]/C]

set_false_path \
    -from [get_pins -match_style ucf */rxinit/RXSLIP_LIMIT_reg/C] \
    -to [get_pins -match_style ucf */rxrst/RXSLIP_LIMITi_reg/D]

set_false_path -to [get_pins -match_style ucf */RXRST100i_reg/S]
