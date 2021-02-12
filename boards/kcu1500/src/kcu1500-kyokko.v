
// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> and <tmr@lut.eee.u-ryukyu.ac.jp> wrote this
//    file. As long as you retain this notice you can do whatever you
//    want with this stuff. If we meet some day, and you think this
//    stuff is worth it, you can buy me a beer in return Yasunori
//    Osana and Akinobu Tomori at University of the Ryukyus, Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster toolkit
// Kyokko project: an open Multi-vendor Aurora 64B/66B-compatible link
//
// Modules in this file:
//    kcu1500_kyokko: Kyokko + Transceiver wrapper for KCU1500, 2x QSFP
// ----------------------------------------------------------------------

`default_nettype none

module kcu1500_kyokko # 
  (  parameter NumCh=8, 
     BondingEnable=0, // Set to 1 to enable
     BondingCh=4,
     NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh) ) 
  ( input wire CLK100, RST,
    
    input wire                 QSFP0_REFCLKP, QSFP0_REFCLKN,
    output wire [3:0]          QSFP0_TXP, QSFP0_TXN, QSFP1_TXP, QSFP1_TXN,
    input wire [3:0]           QSFP0_RXP, QSFP0_RXN, QSFP1_RXP, QSFP1_RXN,

    // ------------------------------
    // Aurora compatible interface signals
    
    output wire [NumChB-1:0]   CH_UP, USER_CLK,
    
    // Data channel
    input wire [64*NumCh-1:0]  S_AXI_TX_TDATA,
    input wire [ NumChB-1:0]   S_AXI_TX_TLAST, S_AXI_TX_TVALID,
    output wire [NumChB-1:0]   S_AXI_TX_TREADY,
    
    output wire [64*NumCh-1:0] M_AXI_RX_TDATA,
    output wire [ NumChB-1:0]  M_AXI_RX_TLAST, M_AXI_RX_TVALID,

    // UFC channel
    input wire [NumChB-1:0]    UFC_TX_REQ,
    input wire [8*NumChB-1:0]  UFC_TX_MS,
    
    input wire [64*NumCh-1:0]  S_AXI_UFC_TX_TDATA,
    input wire [NumChB-1:0]    S_AXI_UFC_TX_TVALID,
    output wire [NumChB-1:0]   S_AXI_UFC_TX_TREADY,

    output wire [64*NumCh-1:0] M_AXI_UFC_RX_TDATA,
    output wire [ NumChB-1:0]  M_AXI_UFC_RX_TLAST, M_AXI_UFC_RX_TVALID,
    
    // NFC channel
    input wire [16*NumChB-1:0] S_AXI_NFC_TDATA,
    input wire [NumChB-1:0]    S_AXI_NFC_TVALID,
    output wire [NumChB-1:0]   S_AXI_NFC_TREADY
   );

   // ------------------------------
   // QSFP0/1 bundle

   wire [NumCh-1:0]            QSFP_TXP, QSFP_TXN, QSFP_RXP, QSFP_RXN;

   assign {QSFP1_TXP, QSFP0_TXP} = QSFP_TXP;
   assign {QSFP1_TXN, QSFP0_TXN} = QSFP_TXN;

   assign QSFP_RXP = {QSFP1_RXP, QSFP0_RXP};
   assign QSFP_RXN = {QSFP1_RXN, QSFP0_RXN};
   
   // ------------------------------
   // GTREFCLK buffer and GT_RST
   
   wire                        GTREFCLK;
   IBUFDS_GTE3 refclkbuf
     ( .O(GTREFCLK),      .ODIV2(),                             // O
       .I(QSFP0_REFCLKP),  .IB   (QSFP0_REFCLKN), .CEB(1'b0) );  // I

   wire                        GT_RST;
   gt_rst grst
     ( .CLK(CLK100), .RST(RST), .GT_RST(GT_RST) );

   // ------------------------------
   // Kyokko instances
   
   wire [NumCh-1:0]            TXUSERCLK2, TX_RDY;
   wire [NumCh-1:0]            RXUSERCLK2, RX_RDY;
   wire [NumCh-1:0][63:0]      TXS, RXS;   // packed array: the SV way

   wire [NumCh-1:0][5:0]       TXHDR, RXHDR;

   wire [NumCh-1:0]   RXRST = ~RX_RDY;
   wire [NumCh-1:0]   TXRST = ~TX_RDY;
   
   wire [NumCh-1:0]            RXPATH_RST, RXSLIP,
                               TX_WFR_CB, TX_SEND_CC;

   genvar                      ch, ch2;
   generate
      if (BondingEnable==0) begin : nobond_gen
         assign USER_CLK = TXUSERCLK2;

         for (ch=0; ch<NumCh; ch=ch+1) begin : kyokko_gen
            defparam ky.tx.init.GenInit = 1;
            
            kyokko # (.BondingEnable(0)) ky
              ( .CLK(),  // still not used
                .CLK100(CLK100),
                .RXCLK(RXUSERCLK2[ch]),  .TXCLK(TXUSERCLK2[ch]),
                .RXRST(RXRST[ch]),       .TXRST(TXRST[ch]),
                .CH_UP(CH_UP[ch]),

                .RXHDR(RXHDR[ch][1:0]), .RXS(RXS[ch]),
                .TXHDR(TXHDR[ch][1:0]), .TXS(TXS[ch]),
                .RXSLIP(RXSLIP[ch]),
                .RXPATH_RST(RXPATH_RST[ch]),

                .TX_WFR_CB_I  (1'b0),
                .TX_WFR_CB_O  (),
                .TX_SEND_CC_I (1'b0),
                .TX_SEND_CC_O (),

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
      end else begin : chbond_gen // block: nobond_gen
         for (ch=0; ch<NumCh; ch=ch+BondingCh) begin : kyokko_cb_gen
            localparam chB = ch/BondingCh;
            assign USER_CLK[chB] = TXUSERCLK2[ch];

            wire [BondingCh*2-1:0] TXHDRi, RXHDRi;
            
            for (ch2=0; ch2<BondingCh; ch2=ch2+1) begin : hdr_gen
               assign TXHDR[ch+ch2][5:2] = 4'b0; // unused portion
               assign TXHDR[ch+ch2][1:0] = TXHDRi[ch2*2+1: ch2*2];
               assign RXHDRi[ch2*2+1 : ch2*2] = RXHDR[ch+ch2][1:0];
            end

            kyokko_cb # (.BondingCh(BondingCh) ) kycb
              ( .CLK(),  // still not used
                .CLK100(CLK100),
                .RXCLK(RXUSERCLK2[ch+BondingCh-1:ch]), 
                .TXCLK(TXUSERCLK2[ch+BondingCh-1:ch]),
                .RXRST(RXRST     [ch+BondingCh-1:ch]),
                .TXRST(TXRST     [ch+BondingCh-1:ch]),
                .CH_UP(CH_UP[chB]),

                // FIXME 
                .RXHDR(RXHDRi),   
                .RXS  (RXS   [ch+BondingCh-1:ch]),
                .TXHDR(TXHDRi), 
                .TXS  (TXS   [ch+BondingCh-1:ch]),
                .RXSLIP    (RXSLIP    [ch+BondingCh-1:ch]),
                .RXPATH_RST(RXPATH_RST[ch+BondingCh-1:ch]),
                
                // Data channels
                .M_AXIS_TVALID(M_AXI_RX_TVALID[chB]),
                .M_AXIS_TLAST (M_AXI_RX_TLAST [chB]),
                .M_AXIS_TDATA (M_AXI_RX_TDATA [(ch+BondingCh)*64-1 : ch*64]),
                
                .S_AXIS_TVALID (S_AXI_TX_TVALID[chB]),
                .S_AXIS_TREADY (S_AXI_TX_TREADY[chB]),
                .S_AXIS_TLAST  (S_AXI_TX_TLAST [chB]),
                .S_AXIS_TDATA  (S_AXI_TX_TDATA [(ch+BondingCh)*64-1 : ch*64]),
                
                // UFC channels
                .UFC_REQ           (UFC_TX_REQ [chB]),
                .UFC_MS            (UFC_TX_MS  [chB*8+7 : chB*8]),
                
                .S_AXIS_UFC_TVALID (S_AXI_UFC_TX_TVALID[chB]),
                .S_AXIS_UFC_TREADY (S_AXI_UFC_TX_TREADY[chB]),
                .S_AXIS_UFC_TDATA  (S_AXI_UFC_TX_TDATA [(ch+BondingCh)*64-1 : ch*64]),
                
                .M_AXIS_UFC_TVALID (M_AXI_UFC_RX_TVALID[chB]),
                .M_AXIS_UFC_TLAST  (M_AXI_UFC_RX_TLAST [chB]),
                .M_AXIS_UFC_TDATA  (M_AXI_UFC_RX_TDATA [(ch+BondingCh)*64-1 : ch*64]),
                
                // NFC channels
                .S_AXIS_NFC_TVALID (S_AXI_NFC_TVALID[chB]),
                .S_AXIS_NFC_TREADY (S_AXI_NFC_TREADY[chB]),
                .S_AXIS_NFC_TDATA  (S_AXI_NFC_TDATA [chB*16+15 : chB*16])
                );
          end
      end
   endgenerate
   
   // ------------------------------
   // GT wizard cores

   if (BondingEnable==0) begin : nobond_gt_gen
      wire [NumCh/4-1:0]          QPLL_LOCKED, QPLL_REFCLK, QPLL_CLK;
      for (ch=0; ch<NumCh; ch=ch+1) begin: gtwiz_gen
         localparam qd = ch/4;
         
         if (ch%4 == 0) begin : w_qpll_gen
            gth_w_qpll gth_inst
              ( .gtwiz_userclk_tx_reset_in      (1'b0),              // I
                .gtwiz_userclk_tx_srcclk_out    (),                  // O
                .gtwiz_userclk_tx_usrclk_out    (),                  // O
                .gtwiz_userclk_tx_usrclk2_out   (TXUSERCLK2  [ch]),  // O
                .gtwiz_userclk_tx_active_out    (),                  // O
                .gtwiz_userclk_rx_reset_in      (1'b0),              // I
                .gtwiz_userclk_rx_srcclk_out    (),                  // O
                .gtwiz_userclk_rx_usrclk_out    (),                  // O
                .gtwiz_userclk_rx_usrclk2_out   (RXUSERCLK2  [ch]),  // O
                .gtwiz_userclk_rx_active_out    (),                  // O
                .gtwiz_reset_clk_freerun_in     (CLK100),            // I
                .gtwiz_reset_all_in             (GT_RST),            // I
                .gtwiz_reset_tx_pll_and_datapath_in(1'b0),           // I
                .gtwiz_reset_tx_datapath_in        (1'b0),           // I
                .gtwiz_reset_rx_pll_and_datapath_in(1'b0),           // I
                .gtwiz_reset_rx_datapath_in     (RXPATH_RST  [ch]),  // I
                .gtwiz_reset_rx_cdr_stable_out  (),                  // O
                .gtwiz_reset_tx_done_out        (TX_RDY      [ch]),  // O
                .gtwiz_reset_rx_done_out        (RX_RDY      [ch]),  // O
                .gtwiz_userdata_tx_in           (TXS         [ch]),  // I [63:0]
                .gtwiz_userdata_rx_out          (RXS         [ch]),  // O [63:0]
                .gtrefclk00_in                  (GTREFCLK),          // I
                .qpll0lock_out                  (QPLL_LOCKED [qd]),  // O
                .qpll0outclk_out                (QPLL_CLK    [qd]),  // O
                .qpll0outrefclk_out             (QPLL_REFCLK [qd]),  // O
                .gthrxn_in                      (QSFP_RXN    [ch]),  // I
                .gthrxp_in                      (QSFP_RXP    [ch]),  // I
                .rxgearboxslip_in               (RXSLIP      [ch]),  // I
                .txheader_in                    (TXHDR[ch]),         // I [5:0]
                .txsequence_in                  (7'b0),              // I [6:0]
                .gtpowergood_out                (),                  // O
                .gthtxn_out                     (QSFP_TXN    [ch]),  // O
                .gthtxp_out                     (QSFP_TXP    [ch]),  // O
                .rxdatavalid_out                (),                  // O [1:0]
                .rxheader_out                   (RXHDR[ch]),         // O [5:0]
                .rxheadervalid_out              (),                  // O [1:0]
                .rxpmaresetdone_out             (),                  // O
                .rxprgdivresetdone_out          (),                  // O
                .rxstartofseq_out               (),                  // O [1:0]
                .txpmaresetdone_out             (),                  // O
                .txprgdivresetdone_out          ()                   // O
                );
         end else begin : wo_qpll_gen

            gth_wo_qpll gth_inst
              ( .gtwiz_userclk_tx_reset_in      (1'b0),              // I
                .gtwiz_userclk_tx_srcclk_out    (),                  // O
                .gtwiz_userclk_tx_usrclk_out    (),                  // O
                .gtwiz_userclk_tx_usrclk2_out   (TXUSERCLK2  [ch]),  // O
                .gtwiz_userclk_tx_active_out    (),                  // O
                .gtwiz_userclk_rx_reset_in      (1'b0),              // I
                .gtwiz_userclk_rx_srcclk_out    (),                  // O
                .gtwiz_userclk_rx_usrclk_out    (),                  // O
                .gtwiz_userclk_rx_usrclk2_out   (RXUSERCLK2  [ch]),  // O
                .gtwiz_userclk_rx_active_out    (),                  // O
                .gtwiz_reset_clk_freerun_in     (CLK100),            // I
                .gtwiz_reset_all_in             (GT_RST),            // I
                .gtwiz_reset_tx_pll_and_datapath_in(1'b0),           // I
                .gtwiz_reset_tx_datapath_in        (1'b0),           // I
                .gtwiz_reset_rx_pll_and_datapath_in(1'b0),           // I
                .gtwiz_reset_rx_datapath_in     (RXPATH_RST  [ch]),  // I
                .gtwiz_reset_qpll0lock_in       (QPLL_LOCKED [qd]),  // I
                .gtwiz_reset_rx_cdr_stable_out  (CDR_GOOD    [ch]),  // O
                .gtwiz_reset_tx_done_out        (TX_RDY      [ch]),  // O
                .gtwiz_reset_rx_done_out        (RX_RDY      [ch]),  // O
                .gtwiz_reset_qpll0reset_out     (),                  // O
                .gtwiz_userdata_tx_in           (TXS         [ch]),  // I [63:0]
                .gtwiz_userdata_rx_out          (RXS         [ch]),  // O [63:0]

                .gthrxn_in                      (QSFP_RXN    [ch]),  // I
                .gthrxp_in                      (QSFP_RXP    [ch]),  // I
                .qpll0clk_in                    (QPLL_CLK    [qd]),  // I
                .qpll0refclk_in                 (QPLL_REFCLK [qd]),  // I
                .qpll1clk_in                    (),                  // I
                .qpll1refclk_in                 (),                  // I
                .rxgearboxslip_in               (RXSLIP      [ch]),  // I
                .txheader_in                    (TXHDR[ch]),         // I [5:0]
                .txsequence_in                  (),                  // I [6:0]
                .gtpowergood_out                (),                  // O
                .gthtxn_out                     (QSFP_TXN    [ch]),  // O
                .gthtxp_out                     (QSFP_TXP    [ch]),  // O
                .rxdatavalid_out                (),                  // O [1:0]
                .rxheader_out                   (RXHDR[ch]),         // O [5:0]
                .rxheadervalid_out              (),                  // O [1:0]
                .rxpmaresetdone_out             (),                  // O
                .rxstartofseq_out               (),                  // O [1:0]
                .txpmaresetdone_out             ()                   // O
                );
         end // block: wo_qpll_gen
      end // block: gtwiz_gen
   end else begin : bond_gt_gen // block: nobond_gt_gen
      for (ch=0; ch<NumCh; ch=ch+BondingCh) begin : gth_gen
         localparam chE = ch+BondingCh-1; // End lane # of Channel

         // All lane driven by same clock
         assign TXUSERCLK2[chE:ch+1] = {BondingCh-1{TXUSERCLK2[ch]}};
         assign RXUSERCLK2[chE:ch+1] = {BondingCh-1{RXUSERCLK2[ch]}};

         wire RXPATH_RSTi = |RXPATH_RST[chE:ch];
         wire TX_RDYi, RX_RDYi;
         assign TX_RDY[chE:ch] = {BondingCh{TX_RDYi}};
         assign RX_RDY[chE:ch] = {BondingCh{RX_RDYi}};
         
         gth4 gth_inst
              (
               .gtwiz_userclk_tx_reset_in  (1'b0),                    // I
               .gtwiz_userclk_tx_srcclk_out(),                // O
               .gtwiz_userclk_tx_usrclk_out(),                // O
               .gtwiz_userclk_tx_usrclk2_out(TXUSERCLK2[ch]),  // O
               .gtwiz_userclk_tx_active_out (),                // O
               .gtwiz_userclk_rx_reset_in  (1'b0),                    // I
               .gtwiz_userclk_rx_srcclk_out(),                // O
               .gtwiz_userclk_rx_usrclk_out(),                // O
               .gtwiz_userclk_rx_usrclk2_out(RXUSERCLK2[ch]),    // O
               .gtwiz_userclk_rx_active_out(),                // O
               .gtwiz_reset_clk_freerun_in (CLK100),                  // I
               .gtwiz_reset_all_in         (GT_RST),            // I
               .gtwiz_reset_tx_pll_and_datapath_in(1'b0),  // I
               .gtwiz_reset_tx_datapath_in        (1'b0),                  // I
               .gtwiz_reset_rx_pll_and_datapath_in(1'b0),  // I
               .gtwiz_reset_rx_datapath_in    (RXPATH_RSTi),    // I
               .gtwiz_reset_rx_cdr_stable_out (),            // O
               .gtwiz_reset_tx_done_out(TX_RDYi),                 // O
               .gtwiz_reset_rx_done_out(RX_RDYi) ,                // O
               .gtwiz_userdata_tx_in   (TXS    [chE:ch]),         // I [255:0]
               .gtwiz_userdata_rx_out  (RXS    [chE:ch]),         // O [255:0]
               .gtrefclk00_in          (GTREFCLK),                // I
               .qpll0outclk_out        (),                        // O
               .qpll0outrefclk_out     (),                        // O
               .gthrxn_in              (QSFP_RXN[chE:ch]),        // I[3 : 0]
               .gthrxp_in              (QSFP_RXP[chE:ch]),        // I[3 : 0]
               .rxgearboxslip_in       (RXSLIP  [chE:ch]),        // I[3 : 0]
               .txheader_in            (TXHDR   [chE:ch]),        // I[23 : 0]
               .txsequence_in          (),                        // I[27 : 0]
               .gthtxn_out             (QSFP_TXN[chE:ch]),        // O[3 : 0]
               .gthtxp_out             (QSFP_TXP[chE:ch]),        // O[3 : 0]
               .gtpowergood_out(),                                // O[3 : 0]
               .rxdatavalid_out(),                                // O[7 : 0]
               .rxheader_out           (RXHDR   [chE:ch]),        // O[23 : 0]
               .rxheadervalid_out(),                              // O[7 : 0]
               .rxpmaresetdone_out(),                             // O[3 : 0]
               .rxprgdivresetdone_out(),                       // O[3 : 0]
               .rxstartofseq_out(),                            // O[7 : 0]
               .txpmaresetdone_out(),                          // O[3 : 0]
               .txprgdivresetdone_out()                        // O[3 : 0]
               );
      end // block: gth_gen
   end // block: bond_gt_gen

endmodule // kcu1500_kyokko

`default_nettype wire


