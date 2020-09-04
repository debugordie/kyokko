      +xm64bit

      ${KYOKKO}/boards/ku040/src/top-aurora-single.v
      ${KYOKKO}/src-aurora/ku-aurora-boot.v
      ${KYOKKO}/src/test/*.v
      
      ${KYOKKO}/boards/ku040/ip/iploc/clk_250_100/clk_250_100_sim_netlist.v

      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2_core.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2/src/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2/example_design/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/aurora_sfp2/example_design/gt/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/ip_0/sim/*.v
      ${KYOKKO}/boards/ku040/ip/iploc/aurora_sfp2/ip_1/sim/*.v

      +libext+.v
      -y /home/cad/Xilinx/Vivado/2019.2/data/verilog/src/unisims
      -y /home/cad/Xilinx/Vivado/2019.2/data/verilog/src/retarget

      -f /home/cad/Xilinx/Vivado/2019.2/data/secureip/gthe3_common/gthe3_common_cell.list.vf
      -f /home/cad/Xilinx/Vivado/2019.2/data/secureip/gthe3_channel/gthe3_channel_cell.list.vf

      # FIFO generator required by Aurora core
      +xmcdslib+/home/cad/Xilinx/libs/XCELIUM1903_Vivado2019_2/cds.lib
      
      +define+NO_JTAG
      
