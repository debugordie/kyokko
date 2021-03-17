      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/kcu1500/sim/tb-loopback.v
      ${KYOKKO}/boards/kcu1500/src/top.sv
      ${KYOKKO}/boards/kcu1500/src/kcu1500-kyokko.sv
      ${KYOKKO}/src/test/*.v
      ${KYOKKO}/boards/kcu1500/ip/iploc/clk_300_100/clk_300_100_sim_netlist.v

      -f ${KYOKKO}/boards/kcu1500/sim/kcu1500-kyokko.f

      ${KYOKKO}/src/kyokko-cb.v

      +define+NO_JTAG
      +defparam+tb_kcu1500.BondingEnable=1
