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
//    s10_kyokko: Kyokko + Transceiver wrapper for Stratix10 board
// ----------------------------------------------------------------------

`default_nettype none

module s10_kyokko # 
  ( parameter NumCh=4,
    BondingEnable = 0, // Set to 1 to enable
    BondingCh = 4,
    NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh) )
  ( input wire CLK250, RST,
    
    input wire                 CLK644P,
    output wire [NumCh-1:0]    SFP_TXP, SFP_TXN,
    input wire [NumCh-1:0]     SFP_RXP, SFP_RXN,

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
    input wire [8*NumCh-1:0]   UFC_TX_MS,
    
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

   wire                        GT_RST;
   gt_rst grst
     ( .CLK(CLK250), .RST(RST), .GT_RST(GT_RST) );

   // ------------------------------
   // Kyokko instances

   wire                        PLL_LOCKED;
   wire [NumCh-1:0]            RX_LOCKED;
   
   wire [NumCh-1:0]            TXUSERCLK2;
   wire [NumCh-1:0]            RXUSERCLK2;
   wire [NumCh-1:0][63:0]      TXS, RXS;
   
   wire [NumCh-1:0][1:0]       TXHDRi, RXHDRi;
   
   wire [NumCh-1:0]            RXRST = ~RX_LOCKED;
   wire [NumCh-1:0]            TXRST = ~{NumCh{PLL_LOCKED}};
   
   wire [NumCh-1:0]            RXPATH_RST, RXSLIP;

   assign USER_CLK = TXUSERCLK2;
   
   genvar             ch;
   generate
      if (BondingEnable==0) begin : nobond_gen
         for (ch=0; ch<NumCh; ch=ch+1)
           begin : kyokko_gen
              wire [5:0] RXHDRc = RXHDRi[ch];
              kyokko ky
                ( .CLK(),  // still not used
                  .CLK100(CLK250),
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
      end else begin : kyokko_cb_gen // block: nobond_gen
         kyokko_cb # ( .BondingCh(BondingCh) ) kycb
           ( .CLK(),  // still not used
             .CLK100(CLK250),
             .RXCLK({BondingCh{RXUSERCLK2[0]}}), 
             .TXCLK({BondingCh{TXUSERCLK2[0]}}),
             .RXRST(RXRST),
             .TXRST(TXRST),
             .CH_UP(CH_UP),
             
             // FIXME 
             .RXHDR(RXHDRi),   
             .RXS  (RXS),
             .TXHDR(TXHDRi), 
             .TXS  (TXS),
             .RXSLIP    (RXSLIP    ),
             .RXPATH_RST(RXPATH_RST),
             
             // Data channels
             .M_AXIS_TVALID(M_AXI_RX_TVALID[0]),
             .M_AXIS_TLAST (M_AXI_RX_TLAST [0]),
             .M_AXIS_TDATA (M_AXI_RX_TDATA ),
             
             .S_AXIS_TVALID (S_AXI_TX_TVALID[0]),
             .S_AXIS_TREADY (S_AXI_TX_TREADY[0]),
             .S_AXIS_TLAST  (S_AXI_TX_TLAST [0]),
             .S_AXIS_TDATA  (S_AXI_TX_TDATA ),
             
             // UFC channels
             .UFC_REQ           (UFC_TX_REQ [0]),
             .UFC_MS            (UFC_TX_MS  [7:0]),
             
             .S_AXIS_UFC_TVALID (S_AXI_UFC_TX_TVALID[0]),
             .S_AXIS_UFC_TREADY (S_AXI_UFC_TX_TREADY[0]),
             .S_AXIS_UFC_TDATA  (S_AXI_UFC_TX_TDATA ),
             
             .M_AXIS_UFC_TVALID (M_AXI_UFC_RX_TVALID[0]),
             .M_AXIS_UFC_TLAST  (M_AXI_UFC_RX_TLAST [0]),
             .M_AXIS_UFC_TDATA  (M_AXI_UFC_RX_TDATA ),
             
             // NFC channels
             .S_AXIS_NFC_TVALID (S_AXI_NFC_TVALID[0]),
             .S_AXIS_NFC_TREADY (S_AXI_NFC_TREADY[0]),
             .S_AXIS_NFC_TDATA  (S_AXI_NFC_TDATA [15:0])
             );
      end
   endgenerate
   
   // ------------------------------
   // GT wizard cores

   
/* -----\/----- EXCLUDED -----\/-----
   if (BondingEnable==0) begin : nobond_gt_gen
 -----/\----- EXCLUDED -----/\----- */
      s10_xcvr_4ch # (.BondingEnable(BondingEnable) ) xcv
        ( .RST(RST | GT_RST), .USRCLK(CLK250), .REFCLK644P(CLK644P),
          .SFP_RXP(SFP_RXP),  .SFP_TXP(SFP_TXP),

          .TX_DATA  ({TXS[3], TXS[2], TXS[1], TXS[0]}),     
          .RX_DATA  ({RXS[3], RXS[2], RXS[1], RXS[0]}),
          .TX_CTRL  ({TXHDRi[3], TXHDRi[2], TXHDRi[1], TXHDRi[0]}), 
          .RX_CTRL  ({RXHDRi[3], RXHDRi[2], RXHDRi[1], RXHDRi[0]}),
          .TX_USRCLK(TXUSERCLK2),  
          .RX_USRCLK(RXUSERCLK2),
          .TX_VALID (1'b1),    
          .RX_BITSLIP(RXSLIP),

          .PLL_LOCKED(PLL_LOCKED), .RX_LOCKED(RX_LOCKED) );
/* -----\/----- EXCLUDED -----\/-----
   end else begin : bond_gt_gen // block: nobond_gt_gen
      a10_xcvr_cb4 xcv
        ( .RST(RST | GT_RST), .USRCLK(CLK250), .REFCLK644P(CLK644P),
          .SFP_RXP(SFP_RXP),  .SFP_TXP(SFP_TXP),

          .TX_DATA  ({TXS[3], TXS[2], TXS[1], TXS[0]}),     
          .RX_DATA  ({RXS[3], RXS[2], RXS[1], RXS[0]}),
          .TX_CTRL  ({TXHDRi[3], TXHDRi[2], TXHDRi[1], TXHDRi[0]}), 
          .RX_CTRL  ({RXHDRi[3], RXHDRi[2], RXHDRi[1], RXHDRi[0]}),
          .TX_USRCLK(TXUSERCLK2[0]),  
          .RX_USRCLK(RXUSERCLK2[0]),
          .TX_VALID (1'b1),    
          .RX_BITSLIP(RXSLIP),

          .PLL_LOCKED(PLL_LOCKED), .RX_LOCKED(RX_LOCKED) );
   end
 -----/\----- EXCLUDED -----/\----- */
   
endmodule // s10_kyokko

`default_nettype wire
     
