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
//    ku040_kyokko: Kyokko + Transceiver wrapper for Kyokko, 2xSFP + 2xSMA
// ----------------------------------------------------------------------

`default_nettype none

module ku040_kyokko # ( parameter NumCh=4 )
  ( input wire CLK100, RST,
    
    input wire                 SFP_REFCLKP, SFP_REFCLKN,
    output wire [1:0]          SFP_TXP, SFP_TXN,
    input wire [1:0]           SFP_RXP, SFP_RXN,
    output wire [1:0]          SMA_TXP, SMA_TXN,
    input wire [1:0]           SMA_RXP, SMA_RXN,

    // ------------------------------
    // Aurora compatible interface signals
    
    output wire [NumCh-1:0]    CH_UP, USER_CLK,
    
    // Data channel
    input wire [64*NumCh-1:0]  S_AXI_TX_TDATA,
    input wire [ NumCh-1:0]    S_AXI_TX_TLAST, S_AXI_TX_TVALID,
    output wire [NumCh-1:0]    S_AXI_TX_TREADY,
    
    output wire [64*NumCh-1:0] M_AXI_RX_TDATA,
    output wire [ NumCh-1:0]   M_AXI_RX_TLAST, M_AXI_RX_TVALID,

    // UFC channel
    input wire [NumCh-1:0]     UFC_TX_REQ,
    output wire [8*NumCh-1:0]  UFC_TX_MS,
    
    input wire [64*NumCh-1:0]  S_AXI_UFC_TX_TDATA,
    input wire [NumCh-1:0]     S_AXI_UFC_TX_TVALID,
    output wire [NumCh-1:0]    S_AXI_UFC_TX_TREADY,

    output wire [64*NumCh-1:0] M_AXI_UFC_RX_TDATA,
    output wire [ NumCh-1:0]   M_AXI_UFC_RX_TLAST, M_AXI_UFC_RX_TVALID,
    
    // NFC channel
    input wire [16*NumCh-1:0]  S_AXI_NFC_TDATA,
    input wire [NumCh-1:0]     S_AXI_NFC_TVALID,
    output wire [NumCh-1:0]    S_AXI_NFC_TREADY
    
   );

   // ------------------------------
   // SMA/SFP bundle: QSFP[3:0] = {SMA1, SMA0, SFP1, SFP0}

   wire [NumCh-1:0]            QSFP_TXP, QSFP_TXN, QSFP_RXP, QSFP_RXN;

   assign {SMA_TXP, SFP_TXP} = QSFP_TXP;
   assign {SMA_TXN, SFP_TXN} = QSFP_TXN;

   assign QSFP_RXP = {SMA_RXP, SFP_RXP};
   assign QSFP_RXN = {SMA_RXN, SFP_RXN};

   // ------------------------------
   // GTREFCLK buffer and GT_RST
   
   wire                        GTREFCLK;
   IBUFDS_GTE3 refclkbuf
     ( .O(GTREFCLK),     .ODIV2(),                             // O
       .I(SFP_REFCLKP),  .IB   (SFP_REFCLKN), .CEB(1'b0) );  // I

   wire                        GT_RST;
   gt_rst grst
     ( .CLK(CLK100), .RST(RST), .GT_RST(GT_RST) );

   // ------------------------------
   // Kyokko instances
   
   wire [NumCh-1:0]            TXUSERCLK2, TX_RDY;
   wire [NumCh-1:0]            RXUSERCLK2, RX_RDY;
   wire [63:0]        TXS [NumCh-1:0],
                      RXS [NumCh-1:0];

   wire [1:0]         TXHDRi [NumCh-1:0];
   wire [5:0]         RXHDRi [NumCh-1:0];

   wire [NumCh-1:0]   RXRST = ~RX_RDY;
   wire [NumCh-1:0]   TXRST = ~TX_RDY;
   
   wire [NumCh-1:0]            RXPATH_RST, RXSLIP;

   assign USER_CLK = TXUSERCLK2;

   genvar             ch;
   generate
      for (ch=0; ch<NumCh; ch=ch+1)
        begin : kyokko_gen
           wire [5:0] RXHDRc = RXHDRi[ch];
           kyokko ky
             ( .CLK(),  // still not used
               .CLK100(CLK100),
               .RXCLK(RXUSERCLK2[ch]),  .TXCLK(TXUSERCLK2[ch]),
               .RXRST(RXRST[ch]),       .TXRST(TXRST[ch]),
               .CH_UP(CH_UP[ch]),

               .RXHDR(RXHDRc[1:0]),   .RXS(RXS[ch]),
               .TXHDR(TXHDRi[ch]),        .TXS(TXS[ch]),
               .RXSLIP(RXSLIP[ch]),
               .RXPATH_RST(RXPATH_RST[ch]),

               // Data channels
               .M_AXIS_TVALID(M_AXI_RX_TVALID[ch]),
               .M_AXIS_TLAST (M_AXI_RX_TLAST [ch]),
               .M_AXIS_TDATA (M_AXI_RX_TDATA [ch*64+63 : ch*64]),

               .S_AXIS_TVALID (S_AXI_TX_TVALID[ch]),
               .S_AXIS_TREADY (S_AXI_TX_TREADY[ch]),
               .S_AXIS_TLAST  (S_AXI_TX_TLAST [ch]),
               .S_AXIS_TDATA  (S_AXI_TX_TDATA [ch*64+63 : ch*64]),

               // UFC channels
               .UFC_REQ           (UFC_TX_REQ [ch]),
               .UFC_MS            (UFC_TX_MS  [ch*8+7 : ch*8]),

               .S_AXIS_UFC_TVALID (S_AXI_UFC_TX_TVALID[ch]),
               .S_AXIS_UFC_TREADY (S_AXI_UFC_TX_TREADY[ch]),
               .S_AXIS_UFC_TDATA  (S_AXI_UFC_TX_TDATA [ch*64+63 : ch*64]),

               .M_AXIS_UFC_TVALID (M_AXI_UFC_RX_TVALID[ch]),
               .M_AXIS_UFC_TLAST  (M_AXI_UFC_RX_TLAST [ch]),
               .M_AXIS_UFC_TDATA  (M_AXI_UFC_RX_TDATA [ch*64+63 : ch*64]),

               // NFC channels
               .S_AXIS_NFC_TVALID (S_AXI_NFC_TVALID[ch]),
               .S_AXIS_NFC_TREADY (S_AXI_NFC_TREADY[ch]),
               .S_AXIS_NFC_TDATA  (S_AXI_NFC_TDATA [ch*16+15 : ch*16])
               );
        end // block: kyokko-gen
   endgenerate
   
   // ------------------------------
   // GT wizard cores

   wire [NumCh/4-1:0]          QPLL_LOCKED, QPLL_REFCLK, QPLL_CLK;

     for (ch=0; ch<NumCh; ch=ch+1) begin: gtwiz_gen
      localparam qd = ch/4;

      if (ch%4 == 0) begin : w_qpll_gen

         gth_w_qpll gth_inst
           ( .gtwiz_userclk_tx_reset_in         (1'b0),              // I
             .gtwiz_userclk_tx_srcclk_out       (),                  // O
             .gtwiz_userclk_tx_usrclk_out       (),                  // O
             .gtwiz_userclk_tx_usrclk2_out      (TXUSERCLK2  [ch]),  // O
             .gtwiz_userclk_tx_active_out       (),                  // O
             .gtwiz_userclk_rx_reset_in         (1'b0),              // I
             .gtwiz_userclk_rx_srcclk_out       (),                  // O
             .gtwiz_userclk_rx_usrclk_out       (),                  // O
             .gtwiz_userclk_rx_usrclk2_out      (RXUSERCLK2  [ch]),  // O
             .gtwiz_userclk_rx_active_out       (),                  // O
             .gtwiz_reset_clk_freerun_in        (CLK100),            // I
             .gtwiz_reset_all_in                (GT_RST),            // I
             .gtwiz_reset_tx_pll_and_datapath_in(1'b0),              // I
             .gtwiz_reset_tx_datapath_in        (1'b0),              // I
             .gtwiz_reset_rx_pll_and_datapath_in(1'b0),              // I
             .gtwiz_reset_rx_datapath_in        (RXPATH_RST  [ch]),  // I
             .gtwiz_reset_rx_cdr_stable_out     (),                  // O
             .gtwiz_reset_tx_done_out           (TX_RDY      [ch]),  // O
             .gtwiz_reset_rx_done_out           (RX_RDY      [ch]),  // O
             .gtwiz_userdata_tx_in              (TXS         [ch]),  // I [63:0]
             .gtwiz_userdata_rx_out             (RXS         [ch]),  // O [63:0]
             .gtrefclk00_in                     (GTREFCLK),          // I
             .qpll0lock_out                     (QPLL_LOCKED [qd]),  // O
             .qpll0outclk_out                   (QPLL_CLK    [qd]),  // O
             .qpll0outrefclk_out                (QPLL_REFCLK [qd]),  // O
             .gthrxn_in                         (QSFP_RXN    [ch]),  // I
             .gthrxp_in                         (QSFP_RXP    [ch]),  // I
             .rxgearboxslip_in                  (RXSLIP      [ch]),  // I
             .txheader_in                       ({4'b0,TXHDRi[ch]}), // I [5:0]
             .txsequence_in                     (7'b0),              // I [6:0]
             .gtpowergood_out                   (),                  // O
             .gthtxn_out                        (QSFP_TXN    [ch]),  // O
             .gthtxp_out                        (QSFP_TXP    [ch]),  // O
             .rxdatavalid_out                   (),                  // O [1:0]
             .rxheader_out                      (RXHDRi[ch]),        // O [5:0]
             .rxheadervalid_out                 (),                  // O [1:0]
             .rxpmaresetdone_out                (),                  // O
             .rxprgdivresetdone_out             (),                  // O
             .rxstartofseq_out                  (),                  // O [1:0]
             .txpmaresetdone_out                (),                  // O
             .txprgdivresetdone_out             ()                   // O
             );
     end else begin : wo_qpll_gen

         gth_wo_qpll gth_inst
           ( .gtwiz_userclk_tx_reset_in         (1'b0),              // I
             .gtwiz_userclk_tx_srcclk_out       (),                  // O
             .gtwiz_userclk_tx_usrclk_out       (),                  // O
             .gtwiz_userclk_tx_usrclk2_out      (TXUSERCLK2  [ch]),  // O
             .gtwiz_userclk_tx_active_out       (),                  // O
             .gtwiz_userclk_rx_reset_in         (1'b0),              // I
             .gtwiz_userclk_rx_srcclk_out       (),                  // O
             .gtwiz_userclk_rx_usrclk_out       (),                  // O
             .gtwiz_userclk_rx_usrclk2_out      (RXUSERCLK2  [ch]),  // O
             .gtwiz_userclk_rx_active_out       (),                  // O
             .gtwiz_reset_clk_freerun_in        (CLK100),            // I
             .gtwiz_reset_all_in                (GT_RST),            // I
             .gtwiz_reset_tx_pll_and_datapath_in(1'b0),              // I
             .gtwiz_reset_tx_datapath_in        (1'b0),              // I
             .gtwiz_reset_rx_pll_and_datapath_in(1'b0),              // I
             .gtwiz_reset_rx_datapath_in        (RXPATH_RST  [ch]),  // I
             .gtwiz_reset_qpll0lock_in          (QPLL_LOCKED [qd]),  // I
             .gtwiz_reset_rx_cdr_stable_out     (),                  // O
             .gtwiz_reset_tx_done_out           (TX_RDY      [ch]),  // O
             .gtwiz_reset_rx_done_out           (RX_RDY      [ch]),  // O
             .gtwiz_reset_qpll0reset_out        (),                  // O
             .gtwiz_userdata_tx_in              (TXS         [ch]),  // I [63:0]
             .gtwiz_userdata_rx_out             (RXS         [ch]),  // O [63:0]
             .gthrxn_in                         (QSFP_RXN    [ch]),  // I
             .gthrxp_in                         (QSFP_RXP    [ch]),  // I
             .qpll0clk_in                       (QPLL_CLK    [qd]),  // I
             .qpll0refclk_in                    (QPLL_REFCLK [qd]),  // I
             .qpll1clk_in                       (),                  // I
             .qpll1refclk_in                    (),                  // I
             .rxgearboxslip_in                  (RXSLIP      [ch]),  // I
             .txheader_in                       ({4'b0,TXHDRi[ch]}), // I [5:0]
             .txsequence_in                     (),                  // I [6:0]
             .gtpowergood_out                   (),                  // O
             .gthtxn_out                        (QSFP_TXN    [ch]),  // O
             .gthtxp_out                        (QSFP_TXP    [ch]),  // O
             .rxdatavalid_out                   (),                  // O [1:0]
             .rxheader_out                      (RXHDRi      [ch]),  // O [5:0]
             .rxheadervalid_out                 (),                  // O [1:0]
             .rxpmaresetdone_out                (),                  // O
             .rxstartofseq_out                  (),                  // O [1:0]
             .txpmaresetdone_out                ()                   // O
             );
      end // block: wo_qpll_gen
   end // block: gtwiz_gen
   
endmodule // ku040_kyokko

`default_nettype wire
     
