      -f ${KYOKKO}/sim/sim-common.f
      +define+NO_LOOPBACK

      ${KYOKKO}/sim/kc705a-ku040k-c10gx/tb.v

      -f ${KYOKKO}/boards/kc705/sim/sim-loopback.f
      -f ${KYOKKO}/boards/ku040/sim/sim-loopback-kyokko-single.f
      -f ${KYOKKO}/boards/c10gx/sim/sim-loopback.f
