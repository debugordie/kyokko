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
//    kc705_aurora: Top-level module for Xilinx KC705 board, Aurora on 1x SFP
// ----------------------------------------------------------------------

`default_nettype none

module kc705_aurora
  ( input wire RST, // CPU Reset button, active high
    input wire        CLK200P, CLK200N,
    input wire        CLK156P, CLK156N,
  
    output wire       SFP_TXP, SFP_TXN,
    input wire        SFP_RXP, SFP_RXN,

    output wire [7:0] LED
    );

   // ------------------------------------------------------------
   // Clock buffers and DCM
   
   wire               GTREFCLK156;
   IBUFDS clk156_buf ( .I(CLK156P), .IB(CLK156N), .O(GTREFCLK156) );

   wire               CLK100, CLK50;
   wire               DCM_LOCKED;

   clk_200_100_50 dcm
     ( .clk100   (CLK100),  .clk50    (CLK50),
       .reset    (RST),     .locked   (DCM_LOCKED),
       .clk_in1_p(CLK200P), .clk_in1_n(CLK200N));

   // ------------------------------------------------------------
   // Aurora boot
   
   wire               RESET_PB, PMA_INIT;
   k7_aurora_boot ab
     ( .CLK50     (CLK50),
       .CLK100    (CLK100),
       .DCM_LOCKED(DCM_LOCKED),

       .RESET_PB  (RESET_PB),
       .PMA_INIT  (PMA_INIT) );

   // ------------------------------------------------------------
   // Aurora signals and core

   wire               CH_UP, LANE_UP;
   wire               AURORA_CLK, AURORA_RST;

   wire [63:0]        TX_DATA, RX_DATA;
   wire               TX_READY, TX_VALID, TX_LAST,  RX_LAST, RX_VALID;   

   wire [63:0]        UFC_TX_DATA, UFC_RX_DATA;
   wire               UFC_REQ, UFC_TX_VALID, UFC_TX_READY;
   wire               UFC_RX_VALID, UFC_RX_LAST;
   wire [7:0]         UFC_MS;

   wire [15:0]        NFC_DATA;
   wire               NFC_VALID, NFC_READY;

   aurora_sfp au_sfp
     ( // MGT Ports
       .rxp(SFP_RXP),  .rxn(SFP_RXN),
       .txp(SFP_TXP),  .txn(SFP_TXN),

       .reset_pb           (RESET_PB),             // I
       .pma_init           (PMA_INIT),             // I
       .power_down         (1'b0),                 // I
       .loopback           (3'b000),               // I [2:0]
       .hard_err           (),                     // O
       .soft_err           (),                     // O
       .channel_up         (CH_UP),                // O
       .lane_up            (LANE_UP),              // O
       .tx_out_clk         (),                     // O
       .gt_pll_lock        (),                     // O
       .mmcm_not_locked_out(),                     // O

       // TX/RX AXIS ports
       .s_axi_tx_tdata      (TX_DATA),             // I [0:63]
       .s_axi_tx_tkeep      (8'hff),               // I [0: 7]
       .s_axi_tx_tlast      (TX_LAST),             // I
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
       .drp_clk_in          (CLK100),              // I
       .drpaddr_in          (9'b0),                // I [8:0]
       .drpdi_in            (16'b0),               // I [15:0]
       .qpll_drpaddr_in     (8'b0),                // I [7:0]
       .qpll_drpdi_in       (16'b0),               // I [15:0]
       .drprdy_out          (),                    // O
       .drpen_in            (1'b0),                // I
       .drpwe_in            (1'b0),                // I
       .qpll_drprdy_out     (),                    // O
       .qpll_drpen_in       (1'b0),                // I
       .qpll_drpwe_in       (1'b0),                // I
       .drpdo_out           (),                    // O [15:0]
       .qpll_drpdo_out      (),                    // O [15:0]

       .link_reset_out      (),                    // O
       .refclk1_in          (GTREFCLK156),         // I
       .user_clk_out        (AURORA_CLK),          // O
       .sync_clk_out        (),                    // O
       .init_clk            (CLK50),               // I
       .gt_qpllclk_quad3_out    (),                // O
       .gt_qpllrefclk_quad3_out (),                // O
       .gt_qpllrefclklost_out   (),                // O
       .gt_qplllock_out     (),                    // O
       .gt_rxcdrovrden_in   (),                    // I
       .sys_reset_out       (AURORA_RST),          // O
       .gt_reset_out        ()                     // O
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
   
endmodule // kc705

`default_nettype wire
