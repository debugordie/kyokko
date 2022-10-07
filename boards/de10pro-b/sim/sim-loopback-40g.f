      -f ${KYOKKO}/sim/sim-common.f

      +define+NO_JTAG

      ${KYOKKO}/boards/de10pro-b/sim/tb-loopback.sv
      ${KYOKKO}/boards/de10pro-b/src/top.sv

      -f ${KYOKKO}/boards/de10pro-b/sim/de10pro-b-kyokko-40g.f
      
      +defparam+tb_de10pro_b.BondingEnable=1
