      +sv
      +xm64bit
      +access+r
      
      -allowredefinition

      -disable_sem2009

     ${KYOKKO}/boards/de10-agilex/ip/phy_10g_8ch/xcvrnphy_fme_410/sim/*v

     +xmmakelib+altera_ver
     ${QUARTUS}/quartus/eda/sim_lib/altera_primitives.v
     +xmendlib

     +xmmakelib+lpm_ver
     ${QUARTUS}/quartus/eda/sim_lib/220model.v
     +xmendlib

     +xmmakelib+sgate_ver
     ${QUARTUS}/quartus/eda/sim_lib/sgate.v
     +xmendlib

     +xmmakelib+altera_mf_ver
     ${QUARTUS}/quartus/eda/sim_lib/altera_mf.v
     +xmendlib

     +xmmakelib+altera_lnsim_ver
     ${QUARTUS}/quartus/eda/sim_lib/altera_lnsim.sv
      +xmendlib

     
     +xmmakelib+tennm_hssi_ver
     ${QUARTUS}/quartus/eda/sim_lib/tennm_hssi_atoms.sv
     ${QUARTUS}/quartus/eda/sim_lib/tennm_hssi_atoms_ncrypt.sv
     +xmendlib

     +xmmakelib+tennm_hssi_e0_ver
     ${QUARTUS}/quartus/eda/sim_lib/cadence/cr3v0_serdes_models_ncrypt.sv
     +xmendlib

     +xmmakelib+tennm_hssi_p0_ver
     ${QUARTUS}/quartus/eda/sim_lib/ctp_hssi_atoms.sv
     ${QUARTUS}/quartus/eda/sim_lib/ctp_hssi_atoms_ncrypt.sv
     +xmendlib

     ${KYOKKO}/boards/de10-agilex/ip/rst_rel/sim/rst_rel.v
     ${KYOKKO}/boards/de10-agilex/ip/rst_rel/altera_s10_user_rst_clkgate_1932/sim/altera_s10_user_rst_clkgate.sv

     ${KYOKKO}/boards/de10-agilex/ip/phy_10g_8ch/sim/phy_10g_8ch.v

     ${KYOKKO}/boards/de10-agilex/src/de10-agilex-kyokko.sv

     ${KYOKKO}/boards/de10-agilex/src/agilexf-xcvr.sv
      
     -f ${KYOKKO}/sim/sim-common.f
     ${KYOKKO}/src/*.v
     ${KYOKKO}/src/intel-gx/fifo_66x512_async.v
     ${KYOKKO}/src/test/*.v
      
