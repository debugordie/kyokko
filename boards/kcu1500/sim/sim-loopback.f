      +xm64bit
      +access+r

      ${KYOKKO}/boards/kcu1500/sim/tb-loopback.v
      ${KYOKKO}/boards/kcu1500/src/top.v
      ${KYOKKO}/boards/kcu1500/src/kcu1500-kyokko.v
      ${KYOKKO}/src/test/*
      ${KYOKKO}/boards/kcu1500/ip/iploc/clk_300_100/clk_300_100_sim_netlist.v

      -f ${KYOKKO}/boards/kcu1500/sim/kcu1500-kyokko.f

      +define+NO_JTAG
