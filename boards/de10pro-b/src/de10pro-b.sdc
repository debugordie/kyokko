create_clock -name MGT_REFCLK -period 1.551515 [get_ports QSFP_REFCLKP[*]]
create_clock -name CLK100 -period 10.000 [get_ports CLK100]

set_false_path -from {*|rx|rxinit|RX_STAT[3]} -to {*|rx|rxaxis|RX_READYr}
set_false_path -from {*|rx|rxinit|RX_STAT[*]} -to {*|tx|init|RX_STAT_TXi[*]}

set_false_path -to {ky|kyokko_cb_gen.kycb|kyokko_gen[*].ky|rx|CB_READY_R}
set_false_path -to {ky|kyokko_cb_gen.kycb|kyokko_gen[*].ky|tx|init|RXRST_TXi}

derive_pll_clocks -create_base_clocks
