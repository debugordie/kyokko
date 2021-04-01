      -f ${KYOKKO}/sim/sim-common.f

      +define+NO_JTAG+

     ${KYOKKO}/boards/s10/sim/tb-loopback.v
     ${KYOKKO}/boards/s10/src/top.sv

      -f ${KYOKKO}/boards/s10/sim/s10-kyokko-40g.f
      
      +defparam+tb_s10.BondingEnable=1
