      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/au50/sim/tb-loopback.v
      ${KYOKKO}/boards/au50/src/top.sv
      ${KYOKKO}/src/test/*.v

      -f ${KYOKKO}/boards/au50/sim/au50-kyokko.f

      ${KYOKKO}/src/kyokko-cb.v
      
      +define+NO_JTAG
      +defparam+tb_au50.BondingEnable=1

      -y ${XILINX_VIVADO}/data/verilog/src/retarget
