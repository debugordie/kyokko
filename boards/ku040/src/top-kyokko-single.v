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
//    ku040: Avnet KU040 DB top-level module, 1x kyokko on SFP[1] or SFP2
//    Mostly used for Kyokko core development and simulation
// ----------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module ku040_kyokko_single
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

   wire               GTREFCLK;
   IBUFDS_GTE3 refclkbuf
     ( .O(GTREFCLK),     .ODIV2(),                           // O
       .I(SFP_REFCLKP),  .IB   (SFP_REFCLKN), .CEB(1'b0) );  // I

   wire               GT_RST;
   gt_rst grst
     ( .CLK(CLK100), .RST(RST), .GT_RST(GT_RST) );
   
   
   // ------------------------------------------------------------
   // Kyokko signals

   wire               CH_UP, AURORA_CLK;
   
   // Data channel
   wire [63:0]        S_AXI_TX_TDATA,
                      M_AXI_RX_TDATA;
   wire               S_AXI_TX_TLAST, S_AXI_TX_TVALID, S_AXI_TX_TREADY,
                      M_AXI_RX_TLAST, M_AXI_RX_TVALID;
   
   // UFC channel
   wire               UFC_TX_REQ;
   wire [7:0]         UFC_TX_MS;
   
   wire [63:0]        S_AXI_UFC_TX_TDATA,
                      M_AXI_UFC_RX_TDATA;
   wire               S_AXI_UFC_TX_TVALID, S_AXI_UFC_TX_TREADY,
                      M_AXI_UFC_RX_TLAST,  M_AXI_UFC_RX_TVALID;
   
   // NFC channel
   wire [15:0]        S_AXI_NFC_TDATA;
   wire               S_AXI_NFC_TVALID, S_AXI_NFC_TREADY;

   // ------------------------------------------------------------
   // Kyokko instance

   wire               TXUSERCLK2, TX_RDY;
   wire               RXUSERCLK2, RX_RDY;
   wire [63:0]        TXS, RXS;
   
   wire [1:0]         TXHDRi;
   wire [5:0]         RXHDRi;
   
   wire               RXRST = ~RX_RDY;
   wire               TXRST = ~TX_RDY;
   
   wire               RXPATH_RST, RXSLIP;

   assign             AURORA_CLK = TXUSERCLK2;

   
   wire [5:0]         RXHDRc = RXHDRi;
   kyokko ky
     ( .CLK(),  // still not used
       .CLK100(CLK100),
       .RXCLK(RXUSERCLK2),  .TXCLK(TXUSERCLK2),
       .RXRST(RXRST),       .TXRST(TXRST),
       .CH_UP(CH_UP),

       .RXHDR(RXHDRc[1:0]),   .RXS(RXS),
       .TXHDR(TXHDRi),        .TXS(TXS),
       .RXSLIP(RXSLIP),
       .RXPATH_RST(RXPATH_RST),

       // Data channels
       .M_AXIS_TVALID (M_AXI_RX_TVALID),
       .M_AXIS_TLAST  (M_AXI_RX_TLAST ),
       .M_AXIS_TDATA  (M_AXI_RX_TDATA ),

       .S_AXIS_TVALID (S_AXI_TX_TVALID),
       .S_AXIS_TREADY (S_AXI_TX_TREADY),
       .S_AXIS_TLAST  (S_AXI_TX_TLAST ),
       .S_AXIS_TDATA  (S_AXI_TX_TDATA ),

       // UFC channels
       .UFC_REQ           (UFC_TX_REQ ),
       .UFC_MS            (UFC_TX_MS  ),

       .S_AXIS_UFC_TVALID (S_AXI_UFC_TX_TVALID),
       .S_AXIS_UFC_TREADY (S_AXI_UFC_TX_TREADY),
       .S_AXIS_UFC_TDATA  (S_AXI_UFC_TX_TDATA ),

       .M_AXIS_UFC_TVALID (M_AXI_UFC_RX_TVALID),
       .M_AXIS_UFC_TLAST  (M_AXI_UFC_RX_TLAST ),
       .M_AXIS_UFC_TDATA  (M_AXI_UFC_RX_TDATA ),

       // NFC channels
       .S_AXIS_NFC_TVALID (S_AXI_NFC_TVALID),
       .S_AXIS_NFC_TREADY (S_AXI_NFC_TREADY),
       .S_AXIS_NFC_TDATA  (S_AXI_NFC_TDATA )
       );

   
   gth_w_qpll gth_inst
     ( .gtwiz_userclk_tx_reset_in         (1'b0),              // I
       .gtwiz_userclk_tx_srcclk_out       (),                  // O
       .gtwiz_userclk_tx_usrclk_out       (),                  // O
       .gtwiz_userclk_tx_usrclk2_out      (TXUSERCLK2  ),  // O
       .gtwiz_userclk_tx_active_out       (),                  // O
       .gtwiz_userclk_rx_reset_in         (1'b0),              // I
       .gtwiz_userclk_rx_srcclk_out       (),                  // O
       .gtwiz_userclk_rx_usrclk_out       (),                  // O
       .gtwiz_userclk_rx_usrclk2_out      (RXUSERCLK2  ),  // O
       .gtwiz_userclk_rx_active_out       (),                  // O
       .gtwiz_reset_clk_freerun_in        (CLK100),            // I
       .gtwiz_reset_all_in                (GT_RST),            // I
       .gtwiz_reset_tx_pll_and_datapath_in(1'b0),              // I
       .gtwiz_reset_tx_datapath_in        (1'b0),              // I
       .gtwiz_reset_rx_pll_and_datapath_in(1'b0),              // I
       .gtwiz_reset_rx_datapath_in        (RXPATH_RST  ),  // I
       .gtwiz_reset_rx_cdr_stable_out     (),                  // O
       .gtwiz_reset_tx_done_out           (TX_RDY      ),  // O
       .gtwiz_reset_rx_done_out           (RX_RDY      ),  // O
       .gtwiz_userdata_tx_in              (TXS         ),  // I [63:0]
       .gtwiz_userdata_rx_out             (RXS         ),  // O [63:0]
       .gtrefclk00_in                     (GTREFCLK),          // I
       .qpll0lock_out                     (),  // O
       .qpll0outclk_out                   (),  // O
       .qpll0outrefclk_out                (),  // O
       .gthrxn_in                         (SFP_RXN    ),  // I
       .gthrxp_in                         (SFP_RXP    ),  // I
       .rxgearboxslip_in                  (RXSLIP      ),  // I
       .txheader_in                       ({4'b0,TXHDRi}), // I [5:0]
       .txsequence_in                     (7'b0),              // I [6:0]
       .gtpowergood_out                   (),                  // O
       .gthtxn_out                        (SFP_TXN    ),  // O
       .gthtxp_out                        (SFP_TXP    ),  // O
       .rxdatavalid_out                   (),                  // O [1:0]
       .rxheader_out                      (RXHDRi),        // O [5:0]
       .rxheadervalid_out                 (),                  // O [1:0]
       .rxpmaresetdone_out                (),                  // O
       .rxprgdivresetdone_out             (),                  // O
       .rxstartofseq_out                  (),                  // O [1:0]
       .txpmaresetdone_out                (),                  // O
       .txprgdivresetdone_out             ()                   // O
       );
   

   // ------------------------------------------------------------
   // Status

   assign LED = CH_UP;

   // ------------------------------------------------------------
   // Test stuff

   wire               GO;

   tx_frame_gen txg
     ( .CLK   (AURORA_CLK), .RST(~CH_UP | ~GO),
       .DATA  (S_AXI_TX_TDATA ),
       .LAST  (S_AXI_TX_TLAST ), 
       .VALID (S_AXI_TX_TVALID),
       .READY (S_AXI_TX_TREADY) );
   
   tx_ufc_gen ufcg
     ( .CLK  (AURORA_CLK), .RST(~CH_UP | ~GO),
       .REQ  (UFC_TX_REQ ),
       .MS   (UFC_TX_MS  ),
       .DATA (S_AXI_UFC_TX_TDATA ),
       .VALID(S_AXI_UFC_TX_TVALID),
       .READY(S_AXI_UFC_TX_TREADY) );
   
   tx_nfc_gen nfcgen
     ( .CLK  (AURORA_CLK), .RST(~CH_UP | ~GO),
       .DATA (S_AXI_NFC_TDATA ), 
       .READY(S_AXI_NFC_TREADY), 
       .VALID(S_AXI_NFC_TVALID) );
   
`ifndef NO_JTAG
   vio_0 vio
     ( .clk(AURORA_CLK),
       .probe_in0 (CH_UP),
       .probe_out0(GO) );

   ila_0 ila
     ( .clk(AURORA_CLK),
       .probe0({S_AXI_TX_TDATA , S_AXI_TX_TVALID,
                S_AXI_TX_TREADY, S_AXI_TX_TLAST ,
                M_AXI_RX_TDATA , 
                M_AXI_RX_TVALID, M_AXI_RX_TLAST }) );
`else
   assign GO = 1'b1;
`endif

   
endmodule // ku040_aurora

`default_nettype wire
