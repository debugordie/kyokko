      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/au200/src/au200-kyokko.sv
      ${KYOKKO}/src/*.v
      +libext+.v

      ${KYOKKO}/boards/au200/ip/iploc/fifo_66x512_async/fifo_66x512_async_sim_netlist.v
      ${KYOKKO}/boards/au200/ip/iploc/gty_w_qpll/gty_w_qpll_sim_netlist.v
      ${KYOKKO}/boards/au200/ip/iploc/gty_wo_qpll/gty_wo_qpll_sim_netlist.v
      ${KYOKKO}/boards/au200/ip/iploc/gty4/gty4_sim_netlist.v
      ${KYOKKO}/boards/au200/ip/iploc/clk_300_100/clk_300_100_sim_netlist.v

      -y ${XILINX_VIVADO}/data/verilog/src/unisims
      ${XILINX_VIVADO}/data/verilog/src/glbl.v
      -f ${XILINX_VIVADO}/data/secureip/gtye4_common/gtye4_common_cell.list.f
      -f ${XILINX_VIVADO}/data/secureip/gtye4_channel/gtye4_channel_cell.list.f
