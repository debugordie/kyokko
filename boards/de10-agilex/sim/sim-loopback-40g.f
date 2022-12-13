      -f ${KYOKKO}/sim/sim-common.f
      
      +define+NO_JTAG
      
      ${KYOKKO}/boards/de10-agilex/sim/tb-loopback.v
      ${KYOKKO}/boards/de10-agilex/src/top.sv
      
      -f ${KYOKKO}/boards/de10-agilex/sim/de10-agilex-kyokko-10g.f

      +defparam+tb_de10_agilex.BondingEnable=1