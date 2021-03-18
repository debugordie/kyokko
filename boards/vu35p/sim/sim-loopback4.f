      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/vu35p/sim/tb-loopback.v
      ${KYOKKO}/boards/vu35p/src/top.sv
      ${KYOKKO}/src/test/*.v

      -f ${KYOKKO}/boards/vu35p/sim/vu35p-kyokko.f

      ${KYOKKO}/src/kyokko-cb.v
      
      +define+NO_JTAG
      +defparam+tb_vu35p.BondingEnable=1

      -y ${XILINX_VIVADO}/data/verilog/src/retarget
