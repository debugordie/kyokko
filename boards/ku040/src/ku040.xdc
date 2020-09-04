# RST button
set_property PACKAGE_PIN N24 [get_ports RST]
set_property IOSTANDARD LVCMOS12 [get_ports RST]
set_property DRIVE 8 [get_ports RST]

# CLK250
set_property PACKAGE_PIN H22 [get_ports CLK250P]
set_property PACKAGE_PIN H23 [get_ports CLK250N]
set_property IOSTANDARD DIFF_SSTL12 [get_ports {CLK250P CLK250N}]

# SFP/SMA refclk @ 156.25MHz
set_property  PACKAGE_PIN M5   [get_ports SFP_REFCLKN]
set_property  PACKAGE_PIN M6   [get_ports SFP_REFCLKP]

# SFP/SMA signals
set_property PACKAGE_PIN N4 [get_ports SFP_TXP[0]]
set_property PACKAGE_PIN M2 [get_ports SFP_RXP[0]]
set_property PACKAGE_PIN M1 [get_ports SFP_RXN[0]]
set_property PACKAGE_PIN N3 [get_ports SFP_TXN[0]]

set_property PACKAGE_PIN L4 [get_ports SFP_TXP[1]]
set_property PACKAGE_PIN K2 [get_ports SFP_RXP[1]]
set_property PACKAGE_PIN K1 [get_ports SFP_RXN[1]]
set_property PACKAGE_PIN L3 [get_ports SFP_TXN[1]]

set_property PACKAGE_PIN J4 [get_ports SMA_TXP[0]]
set_property PACKAGE_PIN H2 [get_ports SMA_RXP[0]]
set_property PACKAGE_PIN H1 [get_ports SMA_RXN[0]]
set_property PACKAGE_PIN J3 [get_ports SMA_TXN[0]]

set_property PACKAGE_PIN G4 [get_ports SMA_TXP[1]]
set_property PACKAGE_PIN F2 [get_ports SMA_RXP[1]]
set_property PACKAGE_PIN F1 [get_ports SMA_RXN[1]]
set_property PACKAGE_PIN G3 [get_ports SMA_TXN[1]]

# LEDs
set_property PACKAGE_PIN D16 [get_ports LED[0]]
set_property PACKAGE_PIN G16 [get_ports LED[1]]
set_property PACKAGE_PIN H16 [get_ports LED[2]]
set_property PACKAGE_PIN E18 [get_ports LED[3]]
set_property PACKAGE_PIN E17 [get_ports LED[4]]
set_property PACKAGE_PIN E16 [get_ports LED[5]]
set_property PACKAGE_PIN H18 [get_ports LED[6]]
set_property PACKAGE_PIN H17 [get_ports LED[7]]
set_property IOSTANDARD LVCMOS18 [get_ports LED[*]]
