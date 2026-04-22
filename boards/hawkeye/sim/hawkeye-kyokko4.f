      -f ${KYOKKO}/sim/sim-common.f
      +sv

      ${KYOKKO}/boards/hawkeye/src/hawkeye-kyokko.sv
      ${KYOKKO}/boards/hawkeye/src/a10-xcvr-cb4.sv
      
      ${KYOKKO}/src/*.v
      ${KYOKKO}/src/intel-gx/fifo_66x512_async.v
      ${KYOKKO}/src/test/*.v

      ${KYOKKO}/boards/hawkeye/ip/atx_5g_4cb/sim/atx_5g_4cb.v
      ${KYOKKO}/boards/hawkeye/ip/atx_5g_4cb/altera_xcvr_atx_pll_a10_1911/sim/*.sv

      ${KYOKKO}/boards/hawkeye/ip/phy_rst_ctrl_4ch/sim/phy_rst_ctrl_4ch.v
      ${KYOKKO}/boards/hawkeye/ip/phy_rst_ctrl_4ch/altera_xcvr_reset_control_1912/sim/*.sv
      
      ${KYOKKO}/boards/hawkeye/ip/phy_10g_4cb/sim/phy_10g_4cb.v
      ${KYOKKO}/boards/hawkeye/ip/phy_10g_4cb/altera_xcvr_native_a10_1912/sim/*sv

     $QUARTUS/quartus/eda/sim_lib/altera_mf.v
      
      +xmmakelib+twentynm_ver
     $QUARTUS/quartus/eda/sim_lib/twentynm_atoms.v
     $QUARTUS/quartus/eda/sim_lib/cadence/twentynm_atoms_ncrypt.v
      +xmendlib

      +xmmakelib+twentynm_hssi_ver
     $QUARTUS/quartus/eda/sim_lib/cadence/twentynm_hssi_atoms_ncrypt.v
     $QUARTUS/quartus/eda/sim_lib/twentynm_hssi_atoms.v
      +xmendlib

      +xmmakelib+twentynm_hip_ver
     $QUARTUS/quartus/eda/sim_lib/cadence/twentynm_hip_atoms_ncrypt.v
     $QUARTUS/quartus/eda/sim_lib/twentynm_hip_atoms.v
      +xmendlib
