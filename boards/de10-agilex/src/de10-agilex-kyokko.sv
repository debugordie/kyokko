`default_nettype none

module de10_agilex_kyokko # 
  ( parameter NumCh=8,
    BondingEnable = 0, // Set to 1 to enable
    BondingCh = 4,
    ChW = ((BondingEnable==0) ? 64 : BondingCh*64 ),
    NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh) )
  ( input wire CLK156, CLK100, RST,
    
    output wire [NumCh-1:0]           SFP_TXP, SFP_TXN,
    input wire [NumCh-1:0]            SFP_RXP, SFP_RXN,

    // ------------------------------
    // Aurora compatible interface signals
    
    output wire [NumChB-1:0]          CH_UP, USER_CLK,
    
    // Data channel
    input wire [NumChB-1:0][ChW-1:0]  S_AXI_TX_TDATA,
    input wire [ NumChB-1:0]          S_AXI_TX_TLAST, S_AXI_TX_TVALID,
    output wire [NumChB-1:0]          S_AXI_TX_TREADY,
    
    output wire [NumChB-1:0][ChW-1:0] M_AXI_RX_TDATA,
    output wire [NumChB-1:0]          M_AXI_RX_TLAST, M_AXI_RX_TVALID,
    
    // UFC channel
    input wire [NumChB-1:0]           UFC_TX_REQ,
    input wire [NumChB-1:0][7:0]      UFC_TX_MS,
    
    input wire [NumChB-1:0][ChW-1:0]  S_AXI_UFC_TX_TDATA,
    input wire [NumChB-1:0]           S_AXI_UFC_TX_TVALID,
    output wire [NumChB-1:0]          S_AXI_UFC_TX_TREADY,
    
    output wire [NumChB-1:0][ChW-1:0] M_AXI_UFC_RX_TDATA,
    output wire [NumChB-1:0]          M_AXI_UFC_RX_TLAST, M_AXI_UFC_RX_TVALID,
    
    // NFC channel
    input wire [NumChB-1:0][15:0]     S_AXI_NFC_TDATA,
    input wire [NumChB-1:0]           S_AXI_NFC_TVALID,
    output wire [NumChB-1:0]          S_AXI_NFC_TREADY
   );

   wire                        GT_RST;
   gt_rst grst
     ( .CLK(CLK100), .RST(RST), .GT_RST(GT_RST) );

   // ------------------------------
   // Kyokko instances

   wire [NumCh-1:0]            PLL_LOCKED;
   wire [NumCh-1:0]            RX_LOCKED;
   
   wire [NumCh-1:0]            TXUSERCLK2;
   wire [NumCh-1:0]            RXUSERCLK2;
   wire [NumCh-1:0][63:0]      TXS, RXS;
   
   wire [NumCh-1:0][1:0]       TXHDRi, RXHDRi;
   
   wire [NumCh-1:0]            RXRST = ~RX_LOCKED;
   wire [NumCh-1:0]            TXRST = ~PLL_LOCKED;
   
   wire [NumCh-1:0]            RXPATH_RST, RXSLIP;

   
   genvar             ch;
   generate
      if (BondingEnable==0) begin : nobond_gen
         assign USER_CLK = TXUSERCLK2;

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
                  .M_AXIS_TDATA (M_AXI_RX_TDATA [ch]),

                  .S_AXIS_TVALID (S_AXI_TX_TVALID[ch]),
                  .S_AXIS_TREADY (S_AXI_TX_TREADY[ch]),
                  .S_AXIS_TLAST  (S_AXI_TX_TLAST [ch]),
                  .S_AXIS_TDATA  (S_AXI_TX_TDATA [ch]),

                  // UFC channels
                  .UFC_REQ           (UFC_TX_REQ [ch]),
                  .UFC_MS            (UFC_TX_MS  [ch]),

                  .S_AXIS_UFC_TVALID (S_AXI_UFC_TX_TVALID[ch]),
                  .S_AXIS_UFC_TREADY (S_AXI_UFC_TX_TREADY[ch]),
                  .S_AXIS_UFC_TDATA  (S_AXI_UFC_TX_TDATA [ch]),

                  .M_AXIS_UFC_TVALID (M_AXI_UFC_RX_TVALID[ch]),
                  .M_AXIS_UFC_TLAST  (M_AXI_UFC_RX_TLAST [ch]),
                  .M_AXIS_UFC_TDATA  (M_AXI_UFC_RX_TDATA [ch]),

                  // NFC channels
                  .S_AXIS_NFC_TVALID (S_AXI_NFC_TVALID[ch]),
                  .S_AXIS_NFC_TREADY (S_AXI_NFC_TREADY[ch]),
                  .S_AXIS_NFC_TDATA  (S_AXI_NFC_TDATA [ch])
                  );
           end // block: kyokko-gen
      end else begin : chbond_gen // block: nobond_gen
         for (ch=0; ch<NumCh; ch=ch+BondingCh) begin : kyokko_cb_gen
            localparam chB = ch/BondingCh;
            assign USER_CLK[chB] = TXUSERCLK2[ch];
            
            kyokko_cb # ( .BondingCh(BondingCh) ) kycb
              ( .CLK(),  // still not used
                .CLK100(CLK100),
                .RXCLK({BondingCh{RXUSERCLK2[ch]}}), 
                .TXCLK({BondingCh{TXUSERCLK2[ch]}}),
                .RXRST(RXRST[ch +: BondingCh]),
                .TXRST(TXRST[ch +: BondingCh]),
                .CH_UP(CH_UP[chB]),
                
                // FIXME 
                .RXHDR(RXHDRi[ch +: BondingCh]),   
                .RXS  (RXS   [ch +: BondingCh]),
                .TXHDR(TXHDRi[ch +: BondingCh]), 
                .TXS  (TXS   [ch +: BondingCh]),
                .RXSLIP    (RXSLIP    [ch +: BondingCh]),
                .RXPATH_RST(RXPATH_RST[ch +: BondingCh]),
                
                // BondingCh channels
                .M_AXIS_TVALID(M_AXI_RX_TVALID[chB]),
                .M_AXIS_TLAST (M_AXI_RX_TLAST [chB]),
                .M_AXIS_TDATA (M_AXI_RX_TDATA [chB]),
                
                .S_AXIS_TVALID (S_AXI_TX_TVALID[chB]),
                .S_AXIS_TREADY (S_AXI_TX_TREADY[chB]),
                .S_AXIS_TLAST  (S_AXI_TX_TLAST [chB]),
                .S_AXIS_TDATA  (S_AXI_TX_TDATA [chB]),
                
                // UFC channels
                .UFC_REQ           (UFC_TX_REQ [chB]),
                .UFC_MS            (UFC_TX_MS  [chB]),
                
                .S_AXIS_UFC_TVALID (S_AXI_UFC_TX_TVALID[chB]),
                .S_AXIS_UFC_TREADY (S_AXI_UFC_TX_TREADY[chB]),
                .S_AXIS_UFC_TDATA  (S_AXI_UFC_TX_TDATA [chB]),
                
                .M_AXIS_UFC_TVALID (M_AXI_UFC_RX_TVALID[chB]),
                .M_AXIS_UFC_TLAST  (M_AXI_UFC_RX_TLAST [chB]),
                .M_AXIS_UFC_TDATA  (M_AXI_UFC_RX_TDATA [chB]),
                
                // NFC channels
                .S_AXIS_NFC_TVALID (S_AXI_NFC_TVALID[chB]),
                .S_AXIS_NFC_TREADY (S_AXI_NFC_TREADY[chB]),
                .S_AXIS_NFC_TDATA  (S_AXI_NFC_TDATA [chB])
                );
         end // block: kyokko_cb_gen
      end // block: chbond_gen
      
   endgenerate
   
   // ------------------------------
   // GT wizard cores
   
   agilexf_xcvr 
     # ( .BondingEnable(BondingEnable), .BondingCh(BondingCh), .NumCh(NumCh))
   xcv ( .RST(RST | GT_RST), .CLK156(CLK156),
         .CLK100(CLK100),
         .SFP_RXP(SFP_RXP),  .SFP_RXN(SFP_RXN), 
         .SFP_TXP(SFP_TXP),  .SFP_TXN(SFP_TXN),
         
         .TX_DATA  (TXS),     
         .RX_DATA  (RXS),
         .TX_CTRL  (TXHDRi), 
         .RX_CTRL  (RXHDRi),
         .TX_USRCLK(TXUSERCLK2),  
         .RX_USRCLK(RXUSERCLK2),
         .TX_VALID  ({NumCh{1'b1}}),    
         .RX_BITSLIP(RXSLIP),
         
         .RX_LOCKED(RX_LOCKED), .PLL_LOCKED(PLL_LOCKED) );
   
endmodule // agf014_kyokko

`default_nettype wire
     
