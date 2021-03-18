# create_clock -name MGT_REFCLK -period 8.000 [get_ports REFCLK125P]
create_clock -name MGT_REFCLK -period 1.551515 [get_ports REFCLK644P]
create_clock -name CLK100 -period 10.000 [get_ports USRCLK]

set_false_path -from {*|rx|rxinit|RX_STAT[3]} -to {*|rx|rxaxis|RX_READYr}
set_false_path -from {*|rx|rxinit|RX_STAT[*]} -to {*|tx|init|RX_STAT_TXi[*]}

set_location_assignment PIN_AC7 -to LED[3]
set_location_assignment PIN_AC6 -to LED[2]
set_location_assignment PIN_AE6 -to LED[1]
set_location_assignment PIN_AF6 -to LED[0]
set_instance_assignment -name IO_STANDARD "1.8 V" -to LED[*]

derive_pll_clocks -create_base_clocks
