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

module kyokko_cb # ( parameter BondingCh=4 )
   ( input wire                     CLK, CLK100,
     input wire [BondingCh-1:0]     RXCLK, TXCLK,
     input wire [BondingCh-1:0]     RXRST, TXRST,
     output wire 		    CH_UP,

    // Rx signals
     input wire [BondingCh* 2-1:0]  RXHDR,
     input wire [BondingCh*64-1:0]  RXS,
     output wire [BondingCh -1:0]   RXSLIP, RXPATH_RST,

    // Tx signals
     output wire [BondingCh* 2-1:0] TXHDR,
     output wire [BondingCh*64-1:0] TXS,

    // AXIS data
     input wire 		    S_AXIS_TVALID, S_AXIS_TLAST,
     input wire [BondingCh*64-1:0]  S_AXIS_TDATA,
     output wire 		    S_AXIS_TREADY,

     output wire 		    M_AXIS_TVALID, M_AXIS_TLAST,
     output wire [BondingCh*64-1:0] M_AXIS_TDATA,

    // UFC signals
     input wire 		    UFC_REQ,
     input wire [7:0] 		    UFC_MS,

     input wire 		    S_AXIS_UFC_TVALID,
     input wire [BondingCh*64-1:0]  S_AXIS_UFC_TDATA,
     output wire 		    S_AXIS_UFC_TREADY,

     output wire 		    M_AXIS_UFC_TVALID, M_AXIS_UFC_TLAST,
     output wire [BondingCh*64-1:0] M_AXIS_UFC_TDATA,

    // NFC signals
     input wire 		    S_AXIS_NFC_TVALID,
     output wire 		    S_AXIS_NFC_TREADY,
     input wire [15:0] 		    S_AXIS_NFC_TDATA
     );

   wire [BondingCh-1:0]             LANE_UP, TX_WFR_CB, TX_SEND_CC, RX_ERR;


   // Channel Bonding signals
   wire [BondingCh-1:0] 	    RX_IS_CB, DATA_IS_VALID, FIFO_RE;
   wire [4:0] 			    CB_STAT;
   wire [BondingCh-1:0] 	    RX_STAT_TX_CB;
   wire [BondingCh-1:0]             UFC_MODE;

   wire                             CB_TIMEOUT;

   // Data channel
   wire [BondingCh-1:0]             M_AXIS_TVALIDi,  M_AXIS_TLASTi,
                                    S_AXIS_TVALIDi,  S_AXIS_TLASTi,
                                    S_AXIS_TREADYi;

   assign M_AXIS_TVALID = M_AXIS_TVALIDi[BondingCh-1];
   assign M_AXIS_TLAST  = M_AXIS_TLASTi [BondingCh-1];

   assign S_AXIS_TVALIDi = { BondingCh{S_AXIS_TVALID} };
   assign S_AXIS_TREADY  = &S_AXIS_TREADYi;
   assign S_AXIS_TLASTi  = { S_AXIS_TLAST,  {BondingCh-1{1'b0}} };

   // UFC channel
   wire [BondingCh-1:0]             S_AXIS_UFC_TVALIDi, S_AXIS_UFC_TREADYi,
                                    M_AXIS_UFC_TVALIDi, M_AXIS_UFC_TLASTi;

   assign M_AXIS_UFC_TVALID = M_AXIS_UFC_TVALIDi[BondingCh-1];
   assign M_AXIS_UFC_TLAST  = M_AXIS_UFC_TLASTi [BondingCh-1];

   assign S_AXIS_UFC_TVALIDi = { BondingCh{S_AXIS_UFC_TVALID} };
   assign S_AXIS_UFC_TREADY  = &S_AXIS_UFC_TREADYi;


   // NFC channel
   wire [BondingCh-1:0]             S_AXIS_NFC_TREADYi;            
   assign S_AXIS_NFC_TREADY  = &S_AXIS_NFC_TREADYi;
   
   // Channel bonding & FIFO Synchronous readout control
   wire  CB_RST = ~(|RX_STAT_TX_CB);
   kyokko_rx_cb # (.BondingCh(BondingCh)) cb_init
     ( .CLK           (TXCLK[0]),
       .RST           (CB_RST),
       .RX_IS_CB      (RX_IS_CB),
       .DATA_IS_VALIDi(DATA_IS_VALID),
       .CB_STAT       (CB_STAT),
       .FIFO_RE       (FIFO_RE),
       .TIMEOUT       (CB_TIMEOUT)
       );

   // Rx reset on Rx error while link is UP
   wire RX_ERR_ANY = |RX_ERR;

   // Kyokko lane instances
   genvar ch;
   
   generate
      for (ch=0; ch<BondingCh; ch=ch+1)
        begin : kyokko_gen
           defparam ky.tx.init.GenInit = (ch==0) ? 1 : 0;

           wire RXPATH_RSTi;
           assign RXPATH_RST[ch] = RXPATH_RSTi | CB_TIMEOUT;

           kyokko # (.BondingEnable(1), .BondingCh(BondingCh), .ChNo(ch)) ky
             ( .CLK(),  // still not used
               .CLK100(CLK100),
               .RXCLK(RXCLK[ch]),              .TXCLK(TXCLK[ch]),
               .RXRST(RXRST[ch] | RX_ERR_ANY),
               .TXRST(TXRST[ch]),
               .CH_UP(LANE_UP   [ch]),

               .RXHDR(RXHDR[ch*2+1 : ch*2]),   .RXS(RXS[ch*64+63 : ch*64]),
               .TXHDR(TXHDR[ch*2+1 : ch*2]),   .TXS(TXS[ch*64+63 : ch*64]),
               .RXSLIP    (RXSLIP     [ch]),
               .RXPATH_RST(RXPATH_RSTi),
               .RX_ERR    (RX_ERR     [ch]),

               .TX_WFR_CB_I  (TX_WFR_CB [0]),
               .TX_WFR_CB_O  (TX_WFR_CB [ch]),
               .TX_SEND_CC_I (TX_SEND_CC[0]),
               .TX_SEND_CC_O (TX_SEND_CC[ch]),

	       .RX_IS_CB     (RX_IS_CB[ch]),
	       .DATA_IS_VALID(DATA_IS_VALID[ch]),
	       .CB_STAT      (CB_STAT),
	       .FIFO_RE      (FIFO_RE[ch]),
	       .RX_STAT_TX_CB(RX_STAT_TX_CB[ch]),
	       .CB_READY     (|CB_STAT[4:3]),
               .CB_ENABLE    (&RX_STAT_TX_CB),

               .UFC_MODE_O(UFC_MODE[ch]),
               .UFC_MODE_I(|UFC_MODE),

               .FIFO_EMPTY (),

               // Data channel
               .M_AXIS_TVALID (M_AXIS_TVALIDi[ch]),
               .M_AXIS_TLAST  (M_AXIS_TLASTi [ch]),
               .M_AXIS_TDATA  (M_AXIS_TDATA  [ch*64+63 : ch*64]),

               .S_AXIS_TVALID (S_AXIS_TVALIDi[ch]),
               .S_AXIS_TREADY (S_AXIS_TREADYi[ch]),
               .S_AXIS_TLAST  (S_AXIS_TLASTi [ch]),
               .S_AXIS_TDATA  (S_AXIS_TDATA  [ch*64+63 : ch*64]),

               // UFC channels
               .UFC_REQ           (UFC_REQ),
               .UFC_MS            (UFC_MS),

               .S_AXIS_UFC_TVALID (S_AXIS_UFC_TVALIDi[ch]),
               .S_AXIS_UFC_TREADY (S_AXIS_UFC_TREADYi[ch]),
               .S_AXIS_UFC_TDATA  (S_AXIS_UFC_TDATA  [ch*64+63 : ch*64]),

               .M_AXIS_UFC_TVALID (M_AXIS_UFC_TVALIDi[ch]),
               .M_AXIS_UFC_TLAST  (M_AXIS_UFC_TLASTi [ch]),
               .M_AXIS_UFC_TDATA  (M_AXIS_UFC_TDATA  [ch*64+63 : ch*64]),

               // NFC channels
               .S_AXIS_NFC_TVALID (S_AXIS_NFC_TVALID),
               .S_AXIS_NFC_TREADY (S_AXIS_NFC_TREADYi[ch]),
               .S_AXIS_NFC_TDATA  (S_AXIS_NFC_TDATA )
               );
        end // block: kyokko-gen
   endgenerate

   assign CH_UP = &LANE_UP;



endmodule

`default_nettype wire
