      -f ${KYOKKO}/sim/sim-common.f
      
      +define+NO_JTAG

      ${KYOKKO}/boards/hawkeye/sim/tb-loopback.v
      ${KYOKKO}/boards/hawkeye/src/top.v

      -f ${KYOKKO}/boards/hawkeye/sim/hawkeye-kyokko.f
      
