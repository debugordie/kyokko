      +xm64bit
      +access+r

      ${KYOKKO}/boards/ku040/sim/tb-loopback.v
      ${KYOKKO}/boards/ku040/src/top.v
      ${KYOKKO}/boards/ku040/ip/iploc/clk_250_100/clk_250_100_sim_netlist.v
      ${KYOKKO}/src/test/*.v

      -f ${KYOKKO}/boards/ku040/sim/ku040-kyokko.f 

      +define+NO_JTAG
