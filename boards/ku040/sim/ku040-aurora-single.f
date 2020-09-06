      -f ${KYOKKO}/sim-common.f

      ${KYOKKO}/boards/ku040/src/top-aurora-single.v
      ${KYOKKO}/src-aurora/ku-aurora-boot.v
      ${KYOKKO}/src/test/*.v
      
      ${KYOKKO}/boards/ku040/ip/iploc/clk_250_100/clk_250_100_sim_netlist.v

      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2_core.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2/src/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2/example_design/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2/example_design/gt/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/ip_0/sim/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/ip_1/sim/*.v

      +libext+.v
      -y ${XILINX_VIVADO}/data/verilog/src/unisims
      -y ${XILINX_VIVADO}/data/verilog/src/retarget

      -f ${XILINX_VIVADO}/data/secureip/gthe3_common/gthe3_common_cell.list.vf
      -f ${XILINX_VIVADO}/data/secureip/gthe3_channel/gthe3_channel_cell.list.vf

      # FIFO generator required by Aurora core
      -f ${KYOKKO}/sim/xilinx-lib.f
      
      +define+NO_JTAG
      
