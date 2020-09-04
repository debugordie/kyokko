      +xm64bit
      +access+r

      ${KYOKKO}/boards/ku040/sim/tb-loopback-kyokko-single.v
      ${KYOKKO}/boards/ku040/src/top-kyokko-single.v

      ${KYOKKO}/src/test/*.v

      ${KYOKKO}/boards/ku040/ip/iploc/clk_250_100/clk_250_100_sim_netlist.v
      
      -f ${KYOKKO}/boards/ku040/sim/ku040-kyokko.f
      
      +define+NO_JTAG
