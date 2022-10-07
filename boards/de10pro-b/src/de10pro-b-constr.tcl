# PCIe reset
set_location_assignment  PIN_AJ34                        -to PCIE_PERST_N
set_instance_assignment -name IO_STANDARD  "3.0-V LVTTL" -to PCIE_PERST_N

# CLK100
set_location_assignment  PIN_U24                  -to CLK100
set_instance_assignment -name IO_STANDARD "1.8 V" -to CLK100


# LEDs
set_location_assignment PIN_B24  -to LED_N[0]
set_location_assignment PIN_A24  -to LED_N[1]
set_location_assignment PIN_A25  -to LED_N[2]
set_location_assignment PIN_A26  -to LED_N[3]
set_instance_assignment -name IO_STANDARD "1.8 V" -to LED_N

# MGT refclk [D:A] -> [3:0]
set_instance_assignment -name IO_STANDARD "LVDS" -to QSFP_REFCLKP
set_location_assignment PIN_T41  -to QSFP_REFCLKP[0]
set_location_assignment PIN_AM38 -to QSFP_REFCLKP[1]
set_location_assignment PIN_AM12 -to QSFP_REFCLKP[2]
set_location_assignment PIN_T9   -to QSFP_REFCLKP[3]

# QSFP [d:a] = [3:0]

set_location_assignment PIN_F49  -to QSFP_TXP[0][0]
set_location_assignment PIN_G47  -to QSFP_TXP[0][1]
set_location_assignment PIN_E47  -to QSFP_TXP[0][2]
set_location_assignment PIN_C47  -to QSFP_TXP[0][3]
set_location_assignment PIN_G43  -to QSFP_RXP[0][0]
set_location_assignment PIN_D45  -to QSFP_RXP[0][1]
set_location_assignment PIN_C43  -to QSFP_RXP[0][2]
set_location_assignment PIN_A43  -to QSFP_RXP[0][3]

set_location_assignment PIN_AK49 -to QSFP_TXP[1][0]
set_location_assignment PIN_AL47 -to QSFP_TXP[1][1]
set_location_assignment PIN_AJ47 -to QSFP_TXP[1][2]
set_location_assignment PIN_AF49 -to QSFP_TXP[1][3]
set_location_assignment PIN_AL43 -to QSFP_RXP[1][0]
set_location_assignment PIN_AH45 -to QSFP_RXP[1][1]
set_location_assignment PIN_AF45 -to QSFP_RXP[1][2]
set_location_assignment PIN_AG43 -to QSFP_RXP[1][3]

set_location_assignment PIN_AK1  -to QSFP_TXP[2][0]
set_location_assignment PIN_AL3  -to QSFP_TXP[2][1]
set_location_assignment PIN_AJ3  -to QSFP_TXP[2][2]
set_location_assignment PIN_AF1  -to QSFP_TXP[2][3]
set_location_assignment PIN_AL7  -to QSFP_RXP[2][0]
set_location_assignment PIN_AH5  -to QSFP_RXP[2][1]
set_location_assignment PIN_AF5  -to QSFP_RXP[2][2]
set_location_assignment PIN_AG7  -to QSFP_RXP[2][3]

set_location_assignment PIN_F1   -to QSFP_TXP[3][0]
set_location_assignment PIN_G3   -to QSFP_TXP[3][1]
set_location_assignment PIN_E3   -to QSFP_TXP[3][2]
set_location_assignment PIN_C3   -to QSFP_TXP[3][3]
set_location_assignment PIN_G7   -to QSFP_RXP[3][0]
set_location_assignment PIN_D5   -to QSFP_RXP[3][1]
set_location_assignment PIN_C7   -to QSFP_RXP[3][2]
set_location_assignment PIN_A7   -to QSFP_RXP[3][3]

set_instance_assignment -name IO_STANDARD "HSSI DIFFERENTIAL I/O" -to QSFP_TXP
set_instance_assignment -name IO_STANDARD "HSSI DIFFERENTIAL I/O" -to QSFP_RXP

# Unused transceivers
set_global_assignment -name PRESERVE_UNUSED_XCVR_CHANNEL ON

# Power management
set_global_assignment -name USE_PWRMGT_SCL SDM_IO0
set_global_assignment -name USE_PWRMGT_SDA SDM_IO12
set_global_assignment -name VID_OPERATION_MODE "PMBUS MASTER"
set_global_assignment -name PWRMGT_BUS_SPEED_MODE "400 KHZ"
set_global_assignment -name PWRMGT_SLAVE_DEVICE_TYPE LTM4677
set_global_assignment -name PWRMGT_SLAVE_DEVICE0_ADDRESS 4F
set_global_assignment -name PWRMGT_SLAVE_DEVICE1_ADDRESS 00
set_global_assignment -name PWRMGT_SLAVE_DEVICE2_ADDRESS 00
set_global_assignment -name PWRMGT_SLAVE_DEVICE3_ADDRESS 00
set_global_assignment -name PWRMGT_SLAVE_DEVICE4_ADDRESS 00
set_global_assignment -name PWRMGT_SLAVE_DEVICE5_ADDRESS 00
set_global_assignment -name PWRMGT_SLAVE_DEVICE6_ADDRESS 00
set_global_assignment -name PWRMGT_SLAVE_DEVICE7_ADDRESS 00
set_global_assignment -name PWRMGT_PAGE_COMMAND_ENABLE ON
set_global_assignment -name PWRMGT_VOLTAGE_OUTPUT_FORMAT "AUTO DISCOVERY"
set_global_assignment -name PWRMGT_TRANSLATED_VOLTAGE_VALUE_UNIT VOLTS
