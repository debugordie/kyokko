      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/kc705/src/top-aurora4.v
      ${KYOKKO}/src-aurora/k7-aurora-boot.v
      ${KYOKKO}/src/test/*.v
      
      ${KYOKKO}/boards/kc705/ip/iploc/aurora_sfp4/aurora_sfp4.v
      ${KYOKKO}/boards/kc705/ip/iploc/aurora_sfp4/aurora_sfp4_core.v
      ${KYOKKO}/boards/kc705/ip/iploc/aurora_sfp4/aurora_sfp4/src/*.v
      ${KYOKKO}/boards/kc705/ip/iploc/aurora_sfp4/aurora_sfp4/example_design/gt/*.v
      
      ${KYOKKO}/boards/kc705/ip/iploc/clk_200_100_50/clk_200_100_50_sim_netlist.v
      
      +libext+.v
      -y ${XILINX_VIVADO}/data/verilog/src/unisims
      -y ${XILINX_VIVADO}/data/verilog/src/retarget
      -f ${XILINX_VIVADO}/data/secureip/gtxe2_common/gtxe2_common_cell.list.vf
      -f ${XILINX_VIVADO}/data/secureip/gtxe2_channel/gtxe2_channel_cell.list.vf 

      +define+NO_JTAG
      
