      +xm64bit
      +access+r

      ${KYOKKO}/boards/au50/sim/tb-loopback.v
      ${KYOKKO}/boards/au50/src/top.v
      ${KYOKKO}/src/test/*.v

      -f ${KYOKKO}/boards/au50/sim/au50-kyokko.f

      +define+NO_JTAG
      -y /home/cad/Xilinx/Vivado/2019.2/data/verilog/src/retarget
