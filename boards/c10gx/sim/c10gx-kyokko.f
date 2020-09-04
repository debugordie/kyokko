      +sv
      -allowredefinition      
      +ncnamemap_mixgen

      ${KYOKKO}/boards/c10gx/src/c10gx-kyokko.v
      ${KYOKKO}/boards/c10gx/src/c10-xcvr-2ch.v
      
      ${KYOKKO}/src/*.v
      ${KYOKKO}/src/intel-gx/fifo_66x512_async.v
      ${KYOKKO}/src/test/*.v

      ${KYOKKO}/boards/c10gx/ip/atx_5g/sim/atx_5g.v
      ${KYOKKO}/boards/c10gx/ip/atx_5g/altera_xcvr_atx_pll_a10_191/sim/*.sv

      ${KYOKKO}/boards/c10gx/ip/phy_rst_ctrl_2ch/sim/phy_rst_ctrl_2ch.v
      ${KYOKKO}/boards/c10gx/ip/phy_rst_ctrl_2ch/altera_xcvr_reset_control_191/sim/*.sv
      
      ${KYOKKO}/boards/c10gx/ip/phy_10g/sim/phy_10g.v
      ${KYOKKO}/boards/c10gx/ip/phy_10g/altera_xcvr_native_a10_191/sim/*sv

#      +xmcdslib+/home/cad/intelFPGA/libs/XCELIUM1903_Quartus20_1/cds.lib

     $QUARTUS/quartus/eda/sim_lib/altera_mf.v
      
      +xmmakelib+cyclone10gx_ver
     $QUARTUS/quartus/eda/sim_lib/cyclone10gx_atoms.v
     $QUARTUS/quartus/eda/sim_lib/cadence/cyclone10gx_atoms_ncrypt.v
      +xmendlib

      +xmmakelib+cyclone10gx_hssi_ver
     $QUARTUS/quartus/eda/sim_lib/cadence/cyclone10gx_hssi_atoms_ncrypt.v
     $QUARTUS/quartus/eda/sim_lib/cyclone10gx_hssi_atoms.v
      +xmendlib

      +xmmakelib+cyclone10gx_hip_ver
     $QUARTUS/quartus/eda/sim_lib/cadence/cyclone10gx_hip_atoms_ncrypt.v
     $QUARTUS/quartus/eda/sim_lib/cyclone10gx_hip_atoms.v
      +xmendlib
