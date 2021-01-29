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
//    kyokko_tx_ctrl: Kyokko Tx subsystem
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_tx_ctrl
  ( input wire CLK,
    input wire         TXRST, RXRST,
    input wire [3:0]   RX_STAT,
    output wire [63:0] TXS,
    output reg [1:0]   TXHDRi,
    output wire        TX_READY,

    input wire         TX_WFR_CB_I, TX_SEND_CC_I,
    output wire        TX_WFR_CB_O, TX_SEND_CC_O,
    output wire        RX_STAT_TX_CB,
    
    input wire         UFC_REQ,
    input wire [7:0]   UFC_MS,

    input wire         NFC_PAUSE, 
    
    input wire         S_AXIS_TVALID, S_AXIS_TLAST,
    output wire        S_AXIS_TREADY,
    input wire [63:0]  S_AXIS_TDATA,

    input wire         S_AXIS_UFC_TVALID,
    output wire        S_AXIS_UFC_TREADY,
    input wire [63:0]  S_AXIS_UFC_TDATA,

    input wire         S_AXIS_NFC_TVALID,
    output wire        S_AXIS_NFC_TREADY,
    input wire [15:0]  S_AXIS_NFC_TDATA
   );

   parameter BondingEnable = 0;  // Set to 1 to enable

   wire [63:0]       TXDATA;

   wire [3:0]        RX_STAT_TX; // RX_STAT in TX clock domain
   assign            RX_STAT_TX_CB = |RX_STAT_TX[3:1];
   wire [63:0]       TXDATA_INIT;

   kyokko_tx_init # (.BondingEnable(BondingEnable)) init
     ( .CLK(CLK), .RST(TXRST), .RXRST(RXRST),
       .RX_STAT     (RX_STAT),      .RX_STAT_TX  (RX_STAT_TX),
       .TX_WFR_CB_I (TX_WFR_CB_I),  .TX_WFR_CB_O (TX_WFR_CB_O),
       .TX_SEND_CC_I(TX_SEND_CC_I), .TX_SEND_CC_O(TX_SEND_CC_O),
       .TXDATA      (TXDATA_INIT) );

   wire              LINK_UP = RX_STAT_TX[3];

   wire              TX_SEND_CC = ( (BondingEnable==1) ? TX_SEND_CC_I :
                                    TX_SEND_CC_O );
   
   // ------------------------------------------------------------
   // AXIS stuff
   
   wire      DATA_HOLD; // Hold data/separator tx because of FC messages
   wire      NFC_ACTIVE, UFC_ACTIVE;

   wire      UFC_HOLD = NFC_PAUSE| NFC_ACTIVE;
   assign    DATA_HOLD = UFC_ACTIVE | UFC_HOLD;

   // - - - - - - - - - - - 
   // Tx AXIS interface

   wire      TX_SEND_DATA;
   wire [63:0] TXDATA_DATA, TXDATA_NFC, TXDATA_UFC;
               
   kyokko_tx_data tx_data
     ( .CLK(CLK),
       .S_AXIS_TVALID(S_AXIS_TVALID),
       .S_AXIS_TLAST (S_AXIS_TLAST),
       .S_AXIS_TREADY(S_AXIS_TREADY),
       .S_AXIS_TDATA (S_AXIS_TDATA),

       .LINK_UP(LINK_UP),
       .HOLD   (DATA_HOLD),
       .CC     (TX_SEND_CC),
       .ACTIVE (TX_SEND_DATA),
       .DATA   (TXDATA_DATA) );

   kyokko_tx_nfc tx_nfc
     ( .CLK(CLK),
       .S_AXIS_NFC_TVALID(S_AXIS_NFC_TVALID),
       .S_AXIS_NFC_TREADY(S_AXIS_NFC_TREADY),
       .S_AXIS_NFC_TDATA (S_AXIS_NFC_TDATA),

       .LINK_UP(LINK_UP),
       .CC     (TX_SEND_CC),
       .ACTIVE (NFC_ACTIVE),
       .DATA   (TXDATA_NFC) );
   
   wire        TX_SEND_UFCMSG;
   kyokko_tx_ufc tx_ufc
     ( .CLK(CLK),
       .UFC_REQ (UFC_REQ),
       .UFC_MS  (UFC_MS),
       .S_AXIS_UFC_TVALID(S_AXIS_UFC_TVALID),
       .S_AXIS_UFC_TREADY(S_AXIS_UFC_TREADY),
       .S_AXIS_UFC_TDATA (S_AXIS_UFC_TDATA),

       .LINK_UP  (LINK_UP),
       .HOLD     (NFC_PAUSE | NFC_ACTIVE),
       .CC       (TX_SEND_CC),
       .ACTIVE   (UFC_ACTIVE),
       .MSG_VALID(TX_SEND_UFCMSG),
       .DATA     (TXDATA_UFC) );
   

   // ------------------------------------------------------------
   // Tx header / data generator
   
   wire [1:0]      TXHDR = (TX_SEND_DATA | TX_SEND_UFCMSG) ? 2'b01 : 2'b10;

   wire [1:0]      FC = { NFC_ACTIVE, UFC_ACTIVE };
   assign TXDATA = ~LINK_UP ? TXDATA_INIT :
                   ( TX_SEND_CC  ? {16'h7880, 48'h0} : // CC
	             ( (FC[1]== 'b1 ) ? TXDATA_NFC :
                       (FC   ==2'b01) ? TXDATA_UFC : TXDATA_DATA ) );

   // Scrambler delay compensation for header
   always @ (posedge CLK) TXHDRi <= TXHDR;

   teng_sc sc
     ( .CLK(CLK), .RST(TXRST),
       .D  (TXDATA),     .S  (TXS) );

   // Tx channel ready
   assign TX_READY = LINK_UP;
endmodule // kyokko_tx_ctrl

`default_nettype wire
