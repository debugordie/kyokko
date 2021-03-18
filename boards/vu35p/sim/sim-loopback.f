      -f ${KYOKKO}/sim/sim-common.f

      ${KYOKKO}/boards/vu35p/sim/tb-loopback.v
      ${KYOKKO}/boards/vu35p/src/top.sv
      ${KYOKKO}/src/test/*.v

      -f ${KYOKKO}/boards/vu35p/sim/vu35p-kyokko.f

      +define+NO_JTAG
      -y ${XILINX_VIVADO}/data/verilog/src/retarget
