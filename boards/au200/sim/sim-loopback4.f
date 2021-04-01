      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/au200/sim/tb-loopback.v
      ${KYOKKO}/boards/au200/src/top.sv
      ${KYOKKO}/src/test/*.v

      -f ${KYOKKO}/boards/au200/sim/au200-kyokko.f

      ${KYOKKO}/src/kyokko-cb.v
      
      +define+NO_JTAG
      +defparam+tb_au200.BondingEnable=1
      
      -y ${XILINX_VIVADO}/data/verilog/src/retarget
