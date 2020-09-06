      -f ${KYOKKO}/sim-common.f

      ${KYOKKO}/boards/ku040/src/ku040-kyokko.v
      ${KYOKKO}/src/*.v
      +libext+.v

      ${KYOKKO}/boards/ku040/ip/iploc/fifo_66x512_async/fifo_66x512_async_sim_netlist.v
      ${KYOKKO}/boards/ku040/ip/iploc/gth_w_qpll/gth_w_qpll_sim_netlist.v
      ${KYOKKO}/boards/ku040/ip/iploc/gth_wo_qpll/gth_wo_qpll_sim_netlist.v

      -y ${XILINX_VIVADO}/data/verilog/src/unisims
      ${XILINX_VIVADO}/data/verilog/src/glbl.v
      -f ${XILINX_VIVADO}/data/secureip/gthe3_common/gthe3_common_cell.list.vf
      -f ${XILINX_VIVADO}/data/secureip/gthe3_channel/gthe3_channel_cell.list.vf
