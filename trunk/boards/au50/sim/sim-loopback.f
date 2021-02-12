      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/au50/sim/tb-loopback.v
      ${KYOKKO}/boards/au50/src/top.v
      ${KYOKKO}/src/test/*.v

      -f ${KYOKKO}/boards/au50/sim/au50-kyokko.f

      +define+NO_JTAG
      -y ${XILINX_VIVADO}/data/verilog/src/retarget
