# PCIe reset

set_property PACKAGE_PIN BD21 [get_ports PCIE_RESET_N]
set_property IOSTANDARD POD12 [get_ports PCIE_RESET_N]

# SYSCLK0 as CLK300

set_property PACKAGE_PIN AY37 [get_ports CLK300P]
set_property PACKAGE_PIN AY38 [get_ports CLK300N]
set_property IOSTANDARD DIFF_SSTL12 [get_ports {CLK300P CLK300N}]

# QSFP0 GTrefclk @ 156.25MHz

set_property PACKAGE_PIN K10 [get_ports CLK156N]
set_property PACKAGE_PIN K11 [get_ports CLK156P]

create_clock -period 6.40 -name clk156 [get_ports CLK156N]

# QSFP signals
set_property PACKAGE_PIN N3 [get_ports QSFP0_RXN[0] ]
set_property PACKAGE_PIN M1 [get_ports QSFP0_RXN[1] ]
set_property PACKAGE_PIN L3 [get_ports QSFP0_RXN[2] ]
set_property PACKAGE_PIN K1 [get_ports QSFP0_RXN[3] ]
set_property PACKAGE_PIN N4 [get_ports QSFP0_RXP[0] ]
set_property PACKAGE_PIN M2 [get_ports QSFP0_RXP[1] ]
set_property PACKAGE_PIN L4 [get_ports QSFP0_RXP[2] ]
set_property PACKAGE_PIN K2 [get_ports QSFP0_RXP[3] ]
set_property PACKAGE_PIN N8 [get_ports QSFP0_TXN[0] ]
set_property PACKAGE_PIN M6 [get_ports QSFP0_TXN[1] ]
set_property PACKAGE_PIN L8 [get_ports QSFP0_TXN[2] ]
set_property PACKAGE_PIN K6 [get_ports QSFP0_TXN[3] ]
set_property PACKAGE_PIN N9 [get_ports QSFP0_TXP[0] ]
set_property PACKAGE_PIN M7 [get_ports QSFP0_TXP[1] ]
set_property PACKAGE_PIN L9 [get_ports QSFP0_TXP[2] ]
set_property PACKAGE_PIN K7 [get_ports QSFP0_TXP[3] ]

set_property PACKAGE_PIN U3 [get_ports QSFP1_RXN[0] ]
set_property PACKAGE_PIN T1 [get_ports QSFP1_RXN[1] ]
set_property PACKAGE_PIN R3 [get_ports QSFP1_RXN[2] ]
set_property PACKAGE_PIN P1 [get_ports QSFP1_RXN[3] ]
set_property PACKAGE_PIN U4 [get_ports QSFP1_RXP[0] ]
set_property PACKAGE_PIN T2 [get_ports QSFP1_RXP[1] ]
set_property PACKAGE_PIN R4 [get_ports QSFP1_RXP[2] ]
set_property PACKAGE_PIN P2 [get_ports QSFP1_RXP[3] ]
set_property PACKAGE_PIN U8 [get_ports QSFP1_TXN[0] ]
set_property PACKAGE_PIN T6 [get_ports QSFP1_TXN[1] ]
set_property PACKAGE_PIN R8 [get_ports QSFP1_TXN[2] ]
set_property PACKAGE_PIN P6 [get_ports QSFP1_TXN[3] ]
set_property PACKAGE_PIN U9 [get_ports QSFP1_TXP[0] ]
set_property PACKAGE_PIN T7 [get_ports QSFP1_TXP[1] ]
set_property PACKAGE_PIN R9 [get_ports QSFP1_TXP[2] ]
set_property PACKAGE_PIN P7 [get_ports QSFP1_TXP[3] ]

# Clocking stuff

connect_debug_port dbg_hub/clk [get_nets CLK100]

set_false_path -from \
    [get_pins -match_style ucf */rxinit/LINK_ERR_TIMER_reg[*]/C]

set_false_path \
    -from [get_pins -match_style ucf */rxinit/RXSLIP_LIMIT_reg/C] \
    -to [get_pins -match_style ucf */rxrst/RXSLIP_LIMITi_reg/D]

set_false_path -to [get_pins -match_style ucf */RXRST100i_reg/*]
