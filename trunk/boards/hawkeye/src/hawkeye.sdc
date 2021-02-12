create_clock -name MGT_REFCLK -period 1.551515 [get_ports CLK644P]
create_clock -name CLK125 -period 8.000 [get_ports CLK125]

set_false_path -from {*|rx|rxinit|RX_STAT[3]} -to {*|rx|rxaxis|RX_READYr}
set_false_path -from {*|rx|rxinit|RX_STAT[*]} -to {*|tx|init|RX_STAT_TXi[*]}

derive_pll_clocks -create_base_clocks
