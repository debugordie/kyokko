# PCIe reset

set_property PACKAGE_PIN AW27 [get_ports PCIE_RESET_N]
set_property IOSTANDARD LVCMOS18 [get_ports PCIE_RESET_N]

# CMC clk @ 100MHz

set_property PACKAGE_PIN G17 [get_ports CMC_CLKP]
set_property PACKAGE_PIN G16 [get_ports CMC_CLKN]
set_property IOSTANDARD LVDS [get_ports CMC_CLKP]
set_property IOSTANDARD LVDS [get_ports CMC_CLKN]
set_property DQS_BIAS TRUE [get_ports CMC_CLKP]
set_property DQS_BIAS TRUE [get_ports CMC_CLKN]

create_clock -period 10.000 -name cmc_clk [get_ports CMC_CLKP]

# QSFP GTrefclk @ 322MHz

set_property PACKAGE_PIN M39 [get_ports CLK322N]
set_property PACKAGE_PIN M38 [get_ports CLK322P]

create_clock -period 3.10303 -name clk322 [get_ports CLK322N]

# QSFP signals

set_property PACKAGE_PIN J46  [get_ports QSFP_RXN[0]]
set_property PACKAGE_PIN G46  [get_ports QSFP_RXN[1]]
set_property PACKAGE_PIN F44  [get_ports QSFP_RXN[2]]
set_property PACKAGE_PIN E46  [get_ports QSFP_RXN[3]]
set_property PACKAGE_PIN J45  [get_ports QSFP_RXP[0]]
set_property PACKAGE_PIN G45  [get_ports QSFP_RXP[1]]
set_property PACKAGE_PIN F43  [get_ports QSFP_RXP[2]]
set_property PACKAGE_PIN E45  [get_ports QSFP_RXP[3]]
set_property PACKAGE_PIN D43  [get_ports QSFP_TXN[0]]
set_property PACKAGE_PIN C41  [get_ports QSFP_TXN[1]]
set_property PACKAGE_PIN B43  [get_ports QSFP_TXN[2]]
set_property PACKAGE_PIN A41  [get_ports QSFP_TXN[3]]
set_property PACKAGE_PIN D42  [get_ports QSFP_TXP[0]]
set_property PACKAGE_PIN C40  [get_ports QSFP_TXP[1]]
set_property PACKAGE_PIN B42  [get_ports QSFP_TXP[2]]
set_property PACKAGE_PIN A40  [get_ports QSFP_TXP[3]]

# Clocking stuff

connect_debug_port dbg_hub/clk [get_nets CLK100]

set_false_path -from \
    [get_pins -match_style ucf */rxinit/LINK_ERR_TIMER_reg[*]/C]

set_false_path \
    -from [get_pins -match_style ucf */rxinit/RXSLIP_LIMIT_reg/C] \
    -to [get_pins -match_style ucf */rxrst/RXSLIP_LIMITi_reg/D]

set_false_path -to [get_pins -match_style ucf */RXRST100i_reg/*]
