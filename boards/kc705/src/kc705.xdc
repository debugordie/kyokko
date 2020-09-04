# RST
set_property PACKAGE_PIN AB7 [get_ports RST]
set_property IOSTANDARD LVCMOS15 [get_ports RST]

# LEDs
set_property PACKAGE_PIN AB8  [get_ports LED[0]]
set_property PACKAGE_PIN AA8  [get_ports LED[1]]
set_property PACKAGE_PIN AC9  [get_ports LED[2]]
set_property PACKAGE_PIN AB9  [get_ports LED[3]]
set_property PACKAGE_PIN AE26 [get_ports LED[4]]
set_property PACKAGE_PIN G19  [get_ports LED[5]]
set_property PACKAGE_PIN E18  [get_ports LED[6]]
set_property PACKAGE_PIN F16  [get_ports LED[7]]
set_property IOSTANDARD LVCMOS15 [get_ports -regexp {LED\[[0-3]\]}]
set_property IOSTANDARD LVCMOS25 [get_ports -regexp {LED\[[4-7]\]}]

set_property DCI_CASCADE {32 34} [get_iobanks 33]

# CPU Reset button, active high
set_property PACKAGE_PIN AD12 [get_ports CLK200P]
set_property PACKAGE_PIN AD11 [get_ports CLK200N]
set_property DIFF_TERM FALSE [get_ports {CLK200P, CLK200N}]
set_property IOSTANDARD LVDS [get_ports {CLP200P, CLK200N}]

# SFP signals
set_property PACKAGE_PIN H2 [get_ports SFP_TXP]
set_property PACKAGE_PIN G3 [get_ports SFP_RXN]
set_property PACKAGE_PIN H1 [get_ports SFP_TXN]
set_property PACKAGE_PIN G4 [get_ports SFP_RXP]
set_property PACKAGE_PIN Y20 [get_ports SFP_TX_DISABLE]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_TX_DISABLE]

# 125MHz LVDS
set_property PACKAGE_PIN G8 [get_ports REFCLKP]
set_property PACKAGE_PIN G7 [get_ports REFCLKN]

# USER_CLK
set_property PACKAGE_PIN K28 [get_ports CLK156P]
set_property PACKAGE_PIN K29 [get_ports CLK156N]
set_property IOSTANDARD LVDS_25 [get_ports CLK156P]
set_property IOSTANDARD LVDS_25 [get_ports CLK156N]

connect_debug_port dbg_hub/clk [get_nets CLK100]

