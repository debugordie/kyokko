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
//    kcu1500: Top-level module for Xilinx KCU1500 board
// ----------------------------------------------------------------------

`default_nettype none

module kcu1500 #
  ( BondingEnable=0, // Set to 1 to enable
    BondingCh=4 )
   ( input wire RST_N,
     input wire        CLK300P, CLK300N,
     input wire        QSFP0_REFCLKP, QSFP0_REFCLKN,
     
     input wire [3:0]  QSFP0_RXP, QSFP0_RXN, QSFP1_RXP, QSFP1_RXN,
     output wire [3:0] QSFP0_TXP, QSFP0_TXN, QSFP1_TXP, QSFP1_TXN,
    
     output wire [7:0] LED
     );
   
   parameter NumCh = 8;
   parameter NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);

   parameter BusW = (BondingEnable==0) ? 64 : 64*BondingCh;
   
   wire               CLK100, DCM_LOCKED, RST;
   assign RST = ~RST_N;

   clk_300_100 dcm
     ( .clk_in1_p(CLK300P), .clk_in1_n(CLK300N),
       .clk100(CLK100),
       .reset(RST),         .locked(DCM_LOCKED) );

   // ------------------------------------------------------------
   // Kyokko signals

   wire [NumChB-1:0]   CH_UP, AURORA_CLK;
   
   // Data channel
   wire [NumChB-1:0] [BusW-1:0] S_AXI_TX_TDATA, M_AXI_RX_TDATA;
   wire [NumChB-1:0]            S_AXI_TX_TLAST, S_AXI_TX_TVALID, 
                                S_AXI_TX_TREADY,
                                M_AXI_RX_TLAST, M_AXI_RX_TVALID;
   
   // UFC channel
   wire [NumChB-1:0]            UFC_TX_REQ;
   wire [NumChB-1:0] [7:0]      UFC_TX_MS;
   
   wire [NumChB-1:0] [BusW-1:0] S_AXI_UFC_TX_TDATA, M_AXI_UFC_RX_TDATA;
   wire [NumChB-1:0]            S_AXI_UFC_TX_TVALID, S_AXI_UFC_TX_TREADY,
                                M_AXI_UFC_RX_TLAST,  M_AXI_UFC_RX_TVALID;
    
   // NFC channel
   wire [NumChB-1:0] [15:0]                  S_AXI_NFC_TDATA;
   wire [NumChB-1:0]            S_AXI_NFC_TVALID, S_AXI_NFC_TREADY;

   // ------------------------------------------------------------
   // Signal bundles

   wire [NumCh*64-1:0] TX_DATA, RX_DATA, UFC_TX_DATA, UFC_RX_DATA;
   wire [NumChB*16-1:0] NFC_TX_DATA;
   wire [NumChB* 8-1:0] UFC_MS;

   assign TX_DATA     = S_AXI_TX_TDATA     [NumChB-1:0];
   assign UFC_TX_DATA = S_AXI_UFC_TX_TDATA [NumChB-1:0];
   assign NFC_TX_DATA = S_AXI_NFC_TDATA    [NumChB-1:0];
   assign UFC_MS      = UFC_TX_MS          [NumChB-1:0];
   
   assign M_AXI_RX_TDATA    [NumChB-1:0] = RX_DATA;
   assign M_AXI_UFC_RX_TDATA[NumChB-1:0] = UFC_RX_DATA;
 
   // ------------------------------------------------------------
   // Kyokko instance

   kcu1500_kyokko #(.BondingEnable(BondingEnable), .BondingCh(BondingCh) ) ky
     ( .CLK100(CLK100), .RST(~DCM_LOCKED),
       .QSFP0_REFCLKP(QSFP0_REFCLKP), .QSFP0_REFCLKN(QSFP0_REFCLKN),

       .QSFP0_TXP(QSFP0_TXP), .QSFP0_TXN(QSFP0_TXN),
       .QSFP0_RXP(QSFP0_RXP), .QSFP0_RXN(QSFP0_RXN),
       .QSFP1_TXP(QSFP1_TXP), .QSFP1_TXN(QSFP1_TXN),
       .QSFP1_RXP(QSFP1_RXP), .QSFP1_RXN(QSFP1_RXN),

       .CH_UP   (CH_UP),
       .USER_CLK(AURORA_CLK),

       // Data channel
       .S_AXI_TX_TDATA     (TX_DATA),             // I [64*NumCh-1:0]  
       .S_AXI_TX_TLAST     (S_AXI_TX_TLAST ),     // I [NumCh-1:0]    
       .S_AXI_TX_TVALID    (S_AXI_TX_TVALID),     // I [NumCh-1:0]     
       .S_AXI_TX_TREADY    (S_AXI_TX_TREADY),     // O [NumCh-1:0]    
     
       .M_AXI_RX_TDATA     (RX_DATA),             // O [64*NumCh-1:0] 
       .M_AXI_RX_TLAST     (M_AXI_RX_TLAST ),     // O [NumCh-1:0]   
       .M_AXI_RX_TVALID    (M_AXI_RX_TVALID),     // O [NumCh-1:0]    
     
       // UFC channel
       .UFC_TX_REQ         (UFC_TX_REQ),          // I [NumCh-1:0]     
       .UFC_TX_MS          (UFC_MS),              // O [8*NumCh-1:0] 
     
       .S_AXI_UFC_TX_TDATA (UFC_TX_DATA),         // I [64*NumCh-1:0]  
       .S_AXI_UFC_TX_TVALID(S_AXI_UFC_TX_TVALID), // I [NumCh-1:0]     
       .S_AXI_UFC_TX_TREADY(S_AXI_UFC_TX_TREADY), // O [NumCh-1:0]    
     
       .M_AXI_UFC_RX_TDATA (UFC_RX_DATA),         // O [64*NumCh-1:0] 
       .M_AXI_UFC_RX_TLAST (M_AXI_UFC_RX_TLAST ), // O [NumCh-1:0]   
       .M_AXI_UFC_RX_TVALID(M_AXI_UFC_RX_TVALID), // O [NumCh-1:0]       

       // NFC channel
       .S_AXI_NFC_TDATA    (NFC_TX_DATA),         // I [16*NumCh-1:0]  
       .S_AXI_NFC_TVALID   (S_AXI_NFC_TVALID),    // I [NumCh-1:0]     
       .S_AXI_NFC_TREADY   (S_AXI_NFC_TREADY)     // O [NumCh-1:0]    
       );

   // ------------------------------------------------------------
   // Status

   assign LED = CH_UP;

   // ------------------------------------------------------------
   // Test stuff

   wire [NumCh-1:0] GO;

   // Frame generators
   genvar              ch;
   generate
      if (BondingEnable==0) begin : nobond_tp_gen
         for (ch=0; ch<NumCh; ch=ch+1) begin : txgen_gen
            tx_frame_gen txg
                 ( .CLK   (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                   .DATA  (S_AXI_TX_TDATA [ch]),
                   .LAST  (S_AXI_TX_TLAST [ch]), 
                   .VALID (S_AXI_TX_TVALID[ch]),
                   .READY (S_AXI_TX_TREADY[ch]) );
            
            tx_ufc_gen ufcg
              ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                .REQ  (UFC_TX_REQ [ch]),
                .MS   (UFC_TX_MS  [ch]),
                .DATA (S_AXI_UFC_TX_TDATA [ch]),
                .VALID(S_AXI_UFC_TX_TVALID[ch]),
                .READY(S_AXI_UFC_TX_TREADY[ch]) );
            
            tx_nfc_gen nfcgen
              ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                .DATA (S_AXI_NFC_TDATA [ch]), 
                .READY(S_AXI_NFC_TREADY[ch]), 
                .VALID(S_AXI_NFC_TVALID[ch]) );
         end // txgen_gen
      end // block: framegen_gen
      else begin : bond_tp_gen
         for (ch=0; ch<NumChB; ch=ch+1) begin : txgen_gen
	    tx_frame_gen4 txg4
                 ( .CLK   (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                   .DATA  (S_AXI_TX_TDATA [ch]),
                   .LAST  (S_AXI_TX_TLAST [ch]), 
                   .VALID (S_AXI_TX_TVALID[ch]),
                   .READY (S_AXI_TX_TREADY[ch]) );

            tx_ufc_gen4 ufcg4
              ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                .REQ  (UFC_TX_REQ [ch]),
                .MS   (UFC_TX_MS  [ch]),
                .DATA (S_AXI_UFC_TX_TDATA [ch]),
                .VALID(S_AXI_UFC_TX_TVALID[ch]),
                .READY(S_AXI_UFC_TX_TREADY[ch]) );

	    // still no NFC
            assign S_AXI_NFC_TVALID[ch] = 0;
         end
      end
   endgenerate
   
`ifndef NO_JTAG
   vio_0 vio
      ( .clk(AURORA_CLK[0]),
        .probe_in0 (CH_UP),
        .probe_out0(GO) );

   generate
      for (ch=0; ch<NumChB; ch=ch+1) begin : ila_gen
         if (BondingEnable==0) begin : nobond_ila_gen
            ila_0 ila
              ( .clk(AURORA_CLK[ch]),
                .probe0({S_AXI_TX_TDATA [ch], S_AXI_TX_TVALID[ch],
                         S_AXI_TX_TREADY[ch], S_AXI_TX_TLAST [ch],
                         M_AXI_RX_TDATA [ch], 
                         M_AXI_RX_TVALID[ch], M_AXI_RX_TLAST [ch]}) );
         end else begin : bond_ila_gen
            ila4_0 ila
              ( .clk(AURORA_CLK[ch]),
                .probe0({S_AXI_TX_TDATA [ch], S_AXI_TX_TVALID[ch],
                         S_AXI_TX_TREADY[ch], S_AXI_TX_TLAST [ch],
                         M_AXI_RX_TDATA [ch], 
                         M_AXI_RX_TVALID[ch], M_AXI_RX_TLAST [ch]}) );

            ila4_0 ila_ufc
              ( .clk(AURORA_CLK[ch]),
                .probe0({S_AXI_UFC_TX_TDATA [ch], S_AXI_UFC_TX_TVALID[ch],
                         S_AXI_UFC_TX_TREADY[ch], 
                         M_AXI_UFC_RX_TDATA [ch], 
                         M_AXI_UFC_RX_TVALID[ch], M_AXI_UFC_RX_TLAST [ch]}) );
         end // block: bond_ila_gen
      end // ila_gen

   endgenerate

   ila4_0 ila
     ( .clk(AURORA_CLK[0]),
       .probe0
       ({ ky.chbond_gen.kyokko_cb_gen[0].kycb.cb_init.RXCB,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.cb_init.CB_STAT,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.cb_init.FIFO_RE,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.CB_RST,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.RX_ERR_ANY,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[0].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[1].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[2].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[3].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[0].ky.rx.RXDATAt, //263
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[1].ky.rx.RXDATAt, //199
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[2].ky.rx.RXDATAt, //135
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[3].ky.rx.RXDATAt, // 71
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[0].ky.rx.RXHDRt, // 7:6
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[1].ky.rx.RXHDRt, // 5:4
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[2].ky.rx.RXHDRt, // 3:2
          ky.chbond_gen.kyokko_cb_gen[0].kycb.kyokko_gen[3].ky.rx.RXHDRt, // 1:0
/* -----\/----- EXCLUDED -----\/-----
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[0].ky.rx.RXDATAt[63:48],
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[1].ky.rx.RXDATAt[63:48],
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[2].ky.rx.RXDATAt[63:48],
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[3].ky.rx.RXDATAt[63:48],
 -----/\----- EXCLUDED -----/\----- */
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[0].ky.tx.TXDATA[63:48],
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[1].ky.tx.TXDATA[63:48],
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[2].ky.tx.TXDATA[63:48],
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[3].ky.tx.TXDATA[63:48],
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[0].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[1].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[2].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[3].ky.tx.RX_STAT_TX,
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[0].ky.tx.TXHDR, // 7:6
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[1].ky.tx.TXHDR, // 5:4
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[2].ky.tx.TXHDR, // 3:2
          ky.chbond_gen.kyokko_cb_gen[4].kycb.kyokko_gen[3].ky.tx.TXHDR // 1:0
          }) );

`else
   assign GO = {NumCh{1'b1}};
`endif

   
endmodule // kcu1500

`default_nettype wire
