      -f ${KYOKKO}/sim/sim-common.f
      
      ${KYOKKO}/sim/kcu1500k-au50k-hawkeye/tb.v
      +define+NO_LOOPBACK

      -f ${KYOKKO}/boards/kcu1500/sim/sim-loopback.f
      -f ${KYOKKO}/boards/au50/sim/sim-loopback.f
      -f ${KYOKKO}/boards/hawkeye/sim/sim-loopback.f
      
