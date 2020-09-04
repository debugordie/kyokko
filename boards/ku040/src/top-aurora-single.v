// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana at University of the Ryukyus,
//    Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster toolkit
// Kyokko project: an open Multi-vendor Aurora 64B/66B-compatible link
//
// Modules in this file:
//    ku040_aurora_single: Avnet KU040 DB top-level module, 1x Aurora on SFP
// ----------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module ku040_aurora_single
  ( input wire RST,
    input wire        CLK250P, CLK250N,
    input wire        SFP_REFCLKP, SFP_REFCLKN,

    output wire [1:1] SFP_TXP, SFP_TXN,
    input wire [1:1]  SFP_RXP, SFP_RXN, 
    output wire [7:0] LED
    );

   // ------------------------------------------------------------
   // DCM
   
   wire               CLK100, DCM_LOCKED;

   clk_250_100 dcm
     ( .clk_in1_p(CLK250P), .clk_in1_n(CLK250N), .clk100(CLK100),
       .reset(RST),         .locked(DCM_LOCKED) );

   // ------------------------------------------------------------
   // Aurora boot

   wire               RESET_PB, PMA_INIT;
   ku_aurora_boot ab
     ( .CLK100(CLK100),      .DCM_LOCKED(DCM_LOCKED),
       .PMA_INIT (PMA_INIT), .RESET_PB (RESET_PB) );

   // ------------------------------------------------------------
   // Aurora signals and core

   wire               CH_UP, LANE_UP;
   wire               AURORA_CLK, AURORA_RST;

   wire [63:0]        TX_DATA, RX_DATA;
   wire               TX_READY, TX_VALID, TX_LAST, RX_LAST, RX_VALID;

   wire [63:0]        UFC_TX_DATA, UFC_RX_DATA;
   wire               UFC_REQ, UFC_TX_VALID, UFC_TX_READY;
   wire               UFC_RX_VALID, UFC_RX_LAST;
   wire [7:0]         UFC_MS;

   wire [15:0]        NFC_DATA;
   wire               NFC_VALID, NFC_READY;

   aurora_sfp2 au_sfp2
     ( .rxp(SFP_RXP[1]),  .rxn(SFP_RXN[1]),       // I
       .txp(SFP_TXP[1]),  .txn(SFP_TXN[1]),       // O
      
       .reset_pb            (RESET_PB),           // I
       .pma_init            (PMA_INIT),           // I
       .power_down          (1'b0),               // I
       .loopback            (3'b0),               // I [2:0]
       .hard_err            (),                   // O
       .soft_err            (),                   // O
       .channel_up          (CH_UP),              // O
       .lane_up             (LANE_UP),            // O
       .tx_out_clk          (),                   // O
       .gt_pll_lock         (),                   // O
       .mmcm_not_locked_out (),                   // O

       // TX/RX AXIS ports
       .s_axi_tx_tdata      (TX_DATA),             // I [0:63]
       .s_axi_tx_tkeep      (8'hff),               // I [0:7]
       .s_axi_tx_tlast      (TX_LAST),             // I s_axi_tx_tlast
       .s_axi_tx_tvalid     (TX_VALID),            // I
       .s_axi_tx_tready     (TX_READY),            // O

       .m_axi_rx_tdata      (RX_DATA),             // O [0:63]
       .m_axi_rx_tkeep      (),                    // O [0:7]
       .m_axi_rx_tlast      (RX_LAST),             // O
       .m_axi_rx_tvalid     (RX_VALID),            // O

       // NFC ports
       .s_axi_nfc_tvalid    (NFC_VALID),           // I
       .s_axi_nfc_tdata     (NFC_DATA),            // I [0:15]
       .s_axi_nfc_tready    (NFC_READY),           // O
      
       // UFC ports
       .ufc_tx_req          (UFC_REQ),             // I
       .ufc_tx_ms           (UFC_MS),              // I [0:7]
       .ufc_in_progress     (),                    // O

       .s_axi_ufc_tx_tdata  (UFC_TX_DATA),         // I [0:63]
       .s_axi_ufc_tx_tvalid (UFC_TX_VALID),        // I
       .s_axi_ufc_tx_tready (UFC_TX_READY),        // O

       .m_axi_ufc_rx_tdata  (UFC_RX_DATA),         // O [0:63]
       .m_axi_ufc_rx_tkeep  (),                    // O [0:7]
       .m_axi_ufc_rx_tlast  (UFC_RX_LAST),         // O
       .m_axi_ufc_rx_tvalid (UFC_RX_VALID),        // O

       // DRP: disabled
       .gt0_drpaddr         (9'b0),                // I [8:0]
       .gt0_drpdi           (16'b0),               // I [15:0]
       .gt0_drprdy          (),                    // O
       .gt0_drpwe           (1'b0),                // I
       .gt0_drpen           (1'b0),                // I
       .gt0_drpdo           (),                    // O [15:0]

       .init_clk            (CLK100),              // I
       .link_reset_out      (),                    // O

       .gt_refclk1_p        (SFP_REFCLKP),         // I
       .gt_refclk1_n        (SFP_REFCLKN),         // I
       .user_clk_out        (AURORA_CLK),          // O
       .sync_clk_out        (),                    // O
       .gt_rxcdrovrden_in   (),                    // I
       .sys_reset_out       (AURORA_RST),          // O
       .gt_reset_out        (),                    // O
       .gt_refclk1_out      (),                    // O
       .gt_powergood        ()                     // O
       );

   // ------------------------------------------------------------
      // Status
   
   assign LED = CH_UP;

   // ------------------------------------------------------------
   // Test stuff
   
   wire               GO;

   // Frame generators
   tx_frame_gen txg
     ( .CLK   (AURORA_CLK), .RST(~CH_UP | ~GO),
       .DATA  (TX_DATA ),
       .LAST  (TX_LAST ),
       .VALID (TX_VALID),
       .READY (TX_READY) );

   tx_ufc_gen ufcg
     ( .CLK  (AURORA_CLK), .RST(~CH_UP | ~GO),
       .REQ  (UFC_REQ ),
       .MS   (UFC_MS  ),
       .DATA (UFC_TX_DATA ),
       .VALID(UFC_TX_VALID),
       .READY(UFC_TX_READY) );

   tx_nfc_gen nfcgen
     ( .CLK  (AURORA_CLK), .RST(~CH_UP | ~GO),
       .DATA (NFC_DATA ),
       .READY(NFC_READY),
       .VALID(NFC_VALID) );

`ifndef NO_JTAG
   vio_0 vio
     ( .clk(AURORA_CLK),
       .probe_in0 (CH_UP),
       .probe_out0(GO) );

   ila_0 ila
     ( .clk(AURORA_CLK),
       .probe0({ TX_DATA , TX_VALID,
                 TX_READY, TX_LAST ,
                 RX_DATA ,
                 RX_VALID, RX_LAST }) );
`else
   assign GO = 1;
`endif

endmodule // ku040_aurora

`default_nettype wire
