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
//    kcu1500: Top-level module for Xilinx KCU1500 board with Aurora x4
// ----------------------------------------------------------------------

`default_nettype none

module kcu1500 
  ( input wire RST_N,
    input wire        CLK300P, CLK300N,
    input wire        QSFP0_REFCLKP, QSFP0_REFCLKN,
     
    input wire [3:0]  QSFP0_RXP, QSFP0_RXN, QSFP1_RXP, QSFP1_RXN,
    output wire [3:0] QSFP0_TXP, QSFP0_TXN, QSFP1_TXP, QSFP1_TXN,
    
    output wire [7:0] LED
     );

   // ------------------------------------------------------------
   // Clock buffers and DCM

   
   wire                        GTREFCLK;
   IBUFDS_GTE3 refclkbuf
     ( .O(GTREFCLK),      .ODIV2(),                             // O
       .I(QSFP0_REFCLKP), .IB   (QSFP0_REFCLKN), .CEB(1'b0) );  // I
   
   wire               CLK100, DCM_LOCKED, RST;
   assign RST = ~RST_N;

   clk_300_100 dcm
     ( .clk_in1_p(CLK300P), .clk_in1_n(CLK300N),
       .clk100(CLK100),
       .reset(RST),         .locked(DCM_LOCKED) );

   // ------------------------------------------------------------
   // Aurora boot

   wire               RESET_PB, PMA_INIT;
   ku_aurora_boot ab
     ( .CLK100    (CLK100),
       .DCM_LOCKED(DCM_LOCKED),

       .RESET_PB  (RESET_PB),
       .PMA_INIT  (PMA_INIT) );

   // ------------------------------------------------------------
   // Aurora signals and core

   wire [1:0]         CH_UP;
   wire [1:0][3:0]    LANE_UP;
   wire [1:0]         AURORA_CLK, AURORA_RST;
   
   wire [1:0] [255:0] TX_DATA, RX_DATA;
   wire [1:0]         TX_READY, TX_VALID, TX_LAST,  RX_LAST, RX_VALID;   
   
   wire [1:0] [255:0] UFC_TX_DATA, UFC_RX_DATA;
   wire [1:0]         UFC_REQ, UFC_TX_VALID, UFC_TX_READY;
   wire [1:0]         UFC_RX_VALID, UFC_RX_LAST;
   wire [1:0] [7:0]   UFC_MS;

   wire [1:0] [15:0]  NFC_DATA;
   wire [1:0]         NFC_VALID, NFC_READY;

   aurora_qsfp au_qsfp0
     ( .rxp(QSFP0_RXP),  .rxn(QSFP0_RXN),          // I [0:3]
       .txp(QSFP0_TXP),  .txn(QSFP0_TXN),          // O [0:3]

       .reset_pb            (RESET_PB),            // I
       .pma_init            (PMA_INIT),            // I
       .power_down          (1'b0),                // I
       .loopback            (3'b000),              // I [2:0]
       .hard_err            (),                    // O
       .soft_err            (),                    // O
       .channel_up          (CH_UP  [0]),          // O
       .lane_up             (LANE_UP[0]),          // O [0:3]
       .tx_out_clk          (),                    // O
       .gt_pll_lock         (),                    // O
       .mmcm_not_locked_out (),                    // O

       // TX/RX AXIS ports
       .s_axi_tx_tdata      (TX_DATA  [0]),        // I [0:255]
       .s_axi_tx_tkeep      (32'hffff_ffff),       // I [0:31]
       .s_axi_tx_tlast      (TX_LAST  [0]),        // I
       .s_axi_tx_tvalid     (TX_VALID [0]),        // I
       .s_axi_tx_tready     (TX_READY [0]),        // O
       
       .m_axi_rx_tdata      (RX_DATA  [0]),        // O [0:255]
       .m_axi_rx_tkeep      (),                    // O [0:31]
       .m_axi_rx_tlast      (RX_LAST  [0]),        // O
       .m_axi_rx_tvalid     (RX_VALID [0]),        // O

       // NFC ports
       .s_axi_nfc_tvalid    (NFC_VALID[0]),        // I
       .s_axi_nfc_tdata     (NFC_DATA [0]),        // I [0:15]
       .s_axi_nfc_tready    (NFC_READY[0]),        // O
       
       // UFC ports
       .ufc_tx_req          (UFC_REQ  [0]),        // I
       .ufc_tx_ms           (UFC_MS   [0]),        // I [0:7]
       .ufc_in_progress     (),                    // O
       
       .s_axi_ufc_tx_tdata  (UFC_TX_DATA [0]),     // I [0:255]
       .s_axi_ufc_tx_tvalid (UFC_TX_VALID[0]),     // I
       .s_axi_ufc_tx_tready (UFC_TX_READY[0]),     // O
       .m_axi_ufc_rx_tdata  (UFC_RX_DATA [0]),     // O [0:255]
       .m_axi_ufc_rx_tkeep  (),                    // O [0:31]
       .m_axi_ufc_rx_tlast  (UFC_RX_LAST [0]),     // O
       .m_axi_ufc_rx_tvalid (UFC_RX_VALID[0]),     // O
        
       // DRP: disabled
       .gt0_drpaddr(0), .gt1_drpaddr(0),                            // I [8:0]
       .gt2_drpaddr(0), .gt3_drpaddr(0),                            // I [8:0]
       .gt0_drpdi(0), .gt1_drpdi(0), .gt2_drpdi(0), .gt3_drpdi(0),  // I [15:0]
       .gt0_drprdy(), .gt1_drprdy(), .gt2_drprdy(), .gt3_drprdy(),  // O
       .gt0_drpwe(0), .gt1_drpwe(0), .gt2_drpwe(0), .gt3_drpwe(0),  // I
       .gt0_drpen(0), .gt1_drpen(0), .gt2_drpen(0), .gt3_drpen(0),  // I
       .gt0_drpdo(),  .gt1_drpdo(),  .gt2_drpdo(),  .gt3_drpdo(),   // O [15:0]

       .init_clk            (CLK100),              // I
       .link_reset_out      (),                    // O
       .refclk1_in          (GTREFCLK),            // I
       .user_clk_out        (AURORA_CLK[0]),       // O
       .sync_clk_out        (),                    // O
       .gt_qpllclk_quad1_out(),                    // O
       .gt_qpllrefclk_quad1_out(),                 // O
       .gt_qpllrefclklost_quad1_out(),             // O
       .gt_qplllock_quad1_out(),                   // O
       .gt_rxcdrovrden_in   (),                    // I
       .sys_reset_out       (),                    // O
       .gt_reset_out        (AURORA_RST[0]),       // O
       .gt_powergood        ()                     // O [3:0]
       );
   
   aurora_qsfp au_qsfp1
     ( .rxp(QSFP1_RXP),  .rxn(QSFP1_RXN),          // I [0:3]
       .txp(QSFP1_TXP),  .txn(QSFP1_TXN),          // O [0:3]

       .reset_pb            (RESET_PB),            // I
       .pma_init            (PMA_INIT),            // I
       .power_down          (1'b0),                // I
       .loopback            (3'b000),              // I [2:0]
       .hard_err            (),                    // O
       .soft_err            (),                    // O
       .channel_up          (CH_UP  [1]),          // O
       .lane_up             (LANE_UP[1]),          // O [0:3]
       .tx_out_clk          (),                    // O
       .gt_pll_lock         (),                    // O
       .mmcm_not_locked_out (),                    // O

       // TX/RX AXIS ports
       .s_axi_tx_tdata      (TX_DATA  [1]),        // I [0:255]
       .s_axi_tx_tkeep      (32'hffff_ffff),       // I [0:31]
       .s_axi_tx_tlast      (TX_LAST  [1]),        // I
       .s_axi_tx_tvalid     (TX_VALID [1]),        // I
       .s_axi_tx_tready     (TX_READY [1]),        // O
       
       .m_axi_rx_tdata      (RX_DATA  [1]),        // O [0:255]
       .m_axi_rx_tkeep      (),                    // O [0:31]
       .m_axi_rx_tlast      (RX_LAST  [1]),        // O
       .m_axi_rx_tvalid     (RX_VALID [1]),        // O

       // NFC ports
       .s_axi_nfc_tvalid    (NFC_VALID[1]),        // I
       .s_axi_nfc_tdata     (NFC_DATA [1]),        // I [0:15]
       .s_axi_nfc_tready    (NFC_READY[1]),        // O
       
       // UFC ports
       .ufc_tx_req          (UFC_REQ  [1]),        // I
       .ufc_tx_ms           (UFC_MS   [1]),        // I [0:7]
       .ufc_in_progress     (),                    // O
       
       .s_axi_ufc_tx_tdata  (UFC_TX_DATA [1]),     // I [0:255]
       .s_axi_ufc_tx_tvalid (UFC_TX_VALID[1]),     // I
       .s_axi_ufc_tx_tready (UFC_TX_READY[1]),     // O
       .m_axi_ufc_rx_tdata  (UFC_RX_DATA [1]),     // O [0:255]
       .m_axi_ufc_rx_tkeep  (),                    // O [0:31]
       .m_axi_ufc_rx_tlast  (UFC_RX_LAST [1]),     // O
       .m_axi_ufc_rx_tvalid (UFC_RX_VALID[1]),     // O
        
       // DRP: disabled
       .gt0_drpaddr(0), .gt1_drpaddr(0),                            // I [8:0]
       .gt2_drpaddr(0), .gt3_drpaddr(0),                            // I [8:0]
       .gt0_drpdi(0), .gt1_drpdi(0), .gt2_drpdi(0), .gt3_drpdi(0),  // I [15:0]
       .gt0_drprdy(), .gt1_drprdy(), .gt2_drprdy(), .gt3_drprdy(),  // O
       .gt0_drpwe(0), .gt1_drpwe(0), .gt2_drpwe(0), .gt3_drpwe(0),  // I
       .gt0_drpen(0), .gt1_drpen(0), .gt2_drpen(0), .gt3_drpen(0),  // I
       .gt0_drpdo(),  .gt1_drpdo(),  .gt2_drpdo(),  .gt3_drpdo(),   // O [15:0]

       .init_clk            (CLK100),              // I
       .link_reset_out      (),                    // O
       .refclk1_in          (GTREFCLK),            // I
       .user_clk_out        (AURORA_CLK[1]),       // O
       .sync_clk_out        (),                    // O
       .gt_qpllclk_quad1_out(),                    // O
       .gt_qpllrefclk_quad1_out(),                 // O
       .gt_qpllrefclklost_quad1_out(),             // O
       .gt_qplllock_quad1_out(),                   // O
       .gt_rxcdrovrden_in   (),                    // I
       .sys_reset_out       (AURORA_RST[1]),       // O
       .gt_reset_out        (),                    // O
       .gt_powergood        ()                     // O [3:0]
       );


   // ------------------------------------------------------------
   // Status

   assign LED = CH_UP;

   // ------------------------------------------------------------
   // Test stuff

   wire [1:0] GO;

   // Frame generators
   genvar           ch;
   for (ch=0; ch<2; ch=ch+1) begin : fg_gen
      tx_frame_gen4 txg
           ( .CLK   (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO),
             .DATA  (TX_DATA [ch]),
             .LAST  (TX_LAST [ch]),
             .VALID (TX_VALID[ch]),
             .READY (TX_READY[ch]) );
      
      tx_ufc_gen4 ufcg
        ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO),
          .REQ  (UFC_REQ [ch]),
          .MS   (UFC_MS  [ch]),
          .DATA (UFC_TX_DATA [ch]),
          .VALID(UFC_TX_VALID[ch]),
          .READY(UFC_TX_READY[ch]) );
      
      tx_nfc_gen nfcgen
        ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO),
          .DATA (NFC_DATA [ch]),
          .READY(NFC_READY[ch]),
          .VALID(NFC_VALID[ch]) );   
   end // block: fg_gen
   
`ifndef NO_JTAG
   vio_0 vio
      ( .clk(AURORA_CLK[0]),
        .probe_in0 (CH_UP),
        .probe_out0(GO) );

/* -----\/----- EXCLUDED -----\/-----
   for (ch=0; ch<2; ch=ch+1) begin : ila_gen
      ila4_0 ila
           ( .clk(AURORA_CLK[ch]),
             .probe0({TX_DATA [ch], TX_VALID[ch],
                      TX_READY[ch], TX_LAST [ch],
                      RX_DATA [ch], RX_VALID[ch], RX_LAST [ch]}) );
      ila4_0 ila_ufc
           ( .clk(AURORA_CLK[ch]),
             .probe0({UFC_REQ [ch], UFC_MS[ch],
                      UFC_TX_DATA[ch], UFC_TX_READY[ch], UFC_TX_VALID[ch],
                      UFC_RX_DATA[ch], UFC_RX_VALID[ch], UFC_RX_LAST [ch]}) );
   end // ila_gen
 -----/\----- EXCLUDED -----/\----- */


   ila4_0 ila_perf
     ( .clk(AURORA_CLK[0]),
       .probe0({TX_DATA [0], TX_VALID[0],
                TX_READY[0], TX_LAST [0],
                RX_DATA [1], RX_VALID[1], RX_LAST [1]}) );

`else
   assign GO = 2'b11;
`endif
   
   

   
endmodule // kcu1500

`default_nettype wire
