+sv
+xm64bit
+access+r

-allowredefinition

+xmmakelib+altera_ver
  $QUARTUS/quartus/eda/sim_lib/altera_primitives.v
+xmendlib

+xmmakelib+lpm_ver
  $QUARTUS/quartus/eda/sim_lib/220model.v
+xmendlib

+xmmakelib+sgate_ver
  $QUARTUS/quartus/eda/sim_lib/sgate.v
+xmendlib

+xmmakelib+altera_mf_ver
  $QUARTUS/quartus/eda/sim_lib/altera_mf.v
+xmendlib

+xmmakelib+altera_lnsim_ver
  $QUARTUS/quartus/eda/sim_lib/altera_lnsim.sv
+xmendlib

+xmmakelib+fourteennm_ver
  $QUARTUS/quartus/eda/sim_lib/fourteennm_atoms.sv
  $QUARTUS/quartus/eda/sim_lib/cadence/fourteennm_atoms_ncrypt.sv
+xmendlib

+xmmakelib+fourteennm_ct1_ver
  $QUARTUS/quartus/eda/sim_lib/ct1_hssi_atoms.sv
  $QUARTUS/quartus/eda/sim_lib/cadence/ct1_hssi_atoms_ncrypt.sv
  $QUARTUS/quartus/eda/sim_lib/cadence/cr3v0_serdes_models_ncrypt.sv

  $QUARTUS/quartus/eda/sim_lib/ct1_hip_atoms.sv
  $QUARTUS/quartus/eda/sim_lib/cadence/ct1_hip_atoms_ncrypt.sv 

  $QUARTUS/quartus/eda/sim_lib/ctp_hssi_atoms.sv
  $QUARTUS/quartus/eda/sim_lib/cadence/ctp_hssi_atoms_ncrypt.sv

  $QUARTUS/quartus/eda/sim_lib/cta_hssi_atoms.sv
  $QUARTUS/quartus/eda/sim_lib/cadence/cta_hssi_atoms_ncrypt.sv
+xmendlib

${KYOKKO}/boards/de10pro-b/ip/atx_5g/altera_xcvr_atx_pll_s10_htile_191/sim/*.v
${KYOKKO}/boards/de10pro-b/ip/atx_5g/altera_xcvr_atx_pll_s10_htile_191/sim/*.sv
${KYOKKO}/boards/de10pro-b/ip/atx_5g/sim/atx_5g.v

${KYOKKO}/boards/de10pro-b/ip/phy_rst_ctrl_4ch/altera_xcvr_reset_control_s10_1911/sim/*.v
${KYOKKO}/boards/de10pro-b/ip/phy_rst_ctrl_4ch/altera_xcvr_reset_control_s10_1911/sim/*.sv
${KYOKKO}/boards/de10pro-b/ip/phy_rst_ctrl_4ch/sim/phy_rst_ctrl_4ch.v

${KYOKKO}/boards/de10pro-b/ip/phy_10g_4ch/altera_xcvr_native_s10_htile_1921/sim/*v
${KYOKKO}/boards/de10pro-b/ip/phy_10g_4ch/sim/phy_10g_4ch.v

${KYOKKO}/boards/de10pro-b/ip/rst_rel/sim/rst_rel.v
${KYOKKO}/boards/de10pro-b/ip/rst_rel/altera_s10_user_rst_clkgate_1910/sim/altera_s10_user_rst_clkgate.sv

${KYOKKO}/boards/s10/src/s10-xcvr-4ch.sv

${KYOKKO}/boards/s10/src/s10-kyokko.sv

-f ${KYOKKO}/sim/sim-common.f

${KYOKKO}/src/*.v
${KYOKKO}/src/intel-gx/fifo_66x512_async.v
${KYOKKO}/src/test/*.v
