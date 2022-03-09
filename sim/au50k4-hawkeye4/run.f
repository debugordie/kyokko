      -f ${KYOKKO}/sim/sim-common.f
      
      +define+CHBOND_4CH +define+NO_LOOPBACK
      tb.v

      -f ../../boards/au50/sim/sim-loopback4.f
      -f ../../boards/hawkeye/sim/sim-loopback4.f
      
