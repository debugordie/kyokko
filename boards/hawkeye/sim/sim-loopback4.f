      -f ${KYOKKO}/sim/sim-common.f
      
      +define+NO_JTAG
      +defparam+tb_hawkeye.BondingEnable=1
      
      ${KYOKKO}/boards/hawkeye/sim/tb-loopback.v
      ${KYOKKO}/boards/hawkeye/src/top.sv

      -f ${KYOKKO}/boards/hawkeye/sim/hawkeye-kyokko4.f
      
