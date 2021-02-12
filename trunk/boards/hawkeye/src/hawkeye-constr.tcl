set_global_assignment -name PRESERVE_UNUSED_XCVR_CHANNEL ON

# PCIe reset
set_location_assignment  PIN_AB11                   -to PCIE_RESET_N
set_instance_assignment -name   IO_STANDARD "1.8 V" -to PCIE_RESET_N

# CLK125
set_location_assignment  PIN_AA16                  -to CLK125

# MGT refclk
set_location_assignment  PIN_W24                   -to CLK644P
set_instance_assignment -name   IO_STANDARD LVDS    -to CLK644P
set_instance_assignment -name XCVR_REFCLK_PIN_TERMINATION AC_COUPLING -to CLK644P
set_instance_assignment -name XCVR_A10_REFCLK_TERM_TRISTATE TRISTATE_OFF -to CLK644P

# SFP [d:a] = [3:0]

set_location_assignment  PIN_AF26                  -to SFP_RXP[0]
set_location_assignment  PIN_AG28                  -to SFP_TXP[0]
set_location_assignment  PIN_AD26                  -to SFP_RXP[1]
set_location_assignment  PIN_AE28                  -to SFP_TXP[1]
set_location_assignment  PIN_AB26                  -to SFP_RXP[2]
set_location_assignment  PIN_AC28                  -to SFP_TXP[2]
set_location_assignment  PIN_Y26                   -to SFP_RXP[3]
set_location_assignment  PIN_AA28                  -to SFP_TXP[3]

set_instance_assignment -name   IO_STANDARD "HSSI DIFFERENTIAL I/O"    -to SFP_TXP
set_instance_assignment -name   IO_STANDARD "CURRENT MODE LOGIC (CML)" -to SFP_RXP

set_instance_assignment -name XCVR_A10_RX_TERM_SEL R_R1   -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_ONE_STAGE_ENABLE NON_S1_MODE -to SFP_RXP
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 0_9V -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_ADP_VGA_SEL RADP_VGA_SEL_4 -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_EQ_DC_GAIN_TRIM NO_DC_GAIN -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_ADP_CTLE_ACGAIN_4S RADP_CTLE_ACGAIN_4S_15 -to SFP_RXP

set_instance_assignment -name XCVR_A10_TX_VOD_OUTPUT_SWING_CTRL 23 -to SFP_TXP
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 0_9V -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SWITCHING_CTRL_1ST_POST_TAP 5 -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SIGN_1ST_POST_TAP FIR_POST_1T_NEG -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SWITCHING_CTRL_PRE_TAP_1T 1 -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SIGN_PRE_TAP_1T FIR_PRE_1T_NEG -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SWITCHING_CTRL_2ND_POST_TAP 2 -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SIGN_2ND_POST_TAP FIR_POST_2T_NEG -to SFP_TXP
