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
//    kyokko: NFC transmission control in Kyokko Tx subsystem
// ----------------------------------------------------------------------

`default_nettype none

module kyokko # ( parameter BondingEnable = 0, BondingCh = 1, ChNo = 0 )
  ( input wire         CLK,   CLK100,
    input wire         RXCLK, TXCLK,
    input wire         RXRST, TXRST,
    output wire        CH_UP,

    // Rx signals
    input wire [1:0]   RXHDR,
    input wire [63:0]  RXS,
    output wire        RXSLIP, RXPATH_RST,

    // Tx signals
    output wire [1:0]  TXHDR,
    output wire [63:0] TXS,

    // CB/CC sync
    input wire         TX_WFR_CB_I, TX_SEND_CC_I,
    output wire        TX_WFR_CB_O, TX_SEND_CC_O,
    
    // CB signal
    output wire        RXCB,
    input wire         FIFO_RE,
    output wire        RX_STAT_TX_CB,
    input wire         CB_FINISH,
    output wire        UFC_MODE_O,
    input wire         UFC_MODE_I,
    
    // AXIS data
    input wire         S_AXIS_TVALID, S_AXIS_TLAST,
    input wire [63:0]  S_AXIS_TDATA,
    output wire        S_AXIS_TREADY,

    output wire        M_AXIS_TVALID, M_AXIS_TLAST,
    output wire [63:0] M_AXIS_TDATA,

    // UFC signals
    input wire         UFC_REQ,
    input wire [7:0]   UFC_MS,

    input wire         S_AXIS_UFC_TVALID,
    input wire [63:0]  S_AXIS_UFC_TDATA,
    output wire        S_AXIS_UFC_TREADY,
    
    output wire        M_AXIS_UFC_TVALID, M_AXIS_UFC_TLAST,
    output wire [63:0] M_AXIS_UFC_TDATA,

    // NFC signals
    input wire         S_AXIS_NFC_TVALID,
    output wire        S_AXIS_NFC_TREADY,
    input wire [15:0]  S_AXIS_NFC_TDATA
   );

   wire [3:0]          RX_STAT;
   wire                RXSLIP_LIMIT;
   wire                NFC_PAUSE;
   
   kyokko_rx_ctrl # (.BondingEnable(BondingEnable), .BondingCh(BondingCh)) rx
     ( .CLK(RXCLK),   .RST(RXRST),
       .TXCLK(TXCLK), .TXRST(TXRST),
       .RXS(RXS), .RXHDRi(RXHDR),
       .FIFO_RE(FIFO_RE),
       .RX_STAT(RX_STAT),
       .RXSLIP (RXSLIP),
       .RXSLIP_LIMIT (RXSLIP_LIMIT),
       .RXCB(RXCB), .CB_FINISH(CB_FINISH),
       .NFC_PAUSE    (NFC_PAUSE),
       .UFC_MODE_O   (UFC_MODE_O),
       .UFC_MODE_I   (UFC_MODE_I),
       
       .M_AXIS_TVALID(M_AXIS_TVALID),
       .M_AXIS_TLAST (M_AXIS_TLAST ),
       .M_AXIS_TDATA (M_AXIS_TDATA ),
       
       .M_AXIS_UFC_TVALID(M_AXIS_UFC_TVALID),
       .M_AXIS_UFC_TLAST (M_AXIS_UFC_TLAST),
       .M_AXIS_UFC_TDATA (M_AXIS_UFC_TDATA) );

   rxpath_rst rxrst
     ( .CLK(CLK100), .RST(RXRST), 
       .RXSLIP_LIMIT(RXSLIP_LIMIT), .RXPATH_RST(RXPATH_RST) );
   
   kyokko_tx_ctrl # (.BondingEnable(BondingEnable), .BondingCh(BondingCh), 
                     .ChNo(ChNo) ) tx
     ( .CLK(TXCLK), 
       .TXRST(TXRST), 
       .RXRST(RXRST),
       .RX_STAT(RX_STAT),
       .TXHDRi(TXHDR),
       .TXS  (TXS),
       .TX_READY(CH_UP),

       .TX_WFR_CB_I (TX_WFR_CB_I),
       .TX_WFR_CB_O (TX_WFR_CB_O),
       .TX_SEND_CC_I(TX_SEND_CC_I),
       .TX_SEND_CC_O(TX_SEND_CC_O),
       .RX_STAT_TX_CB(RX_STAT_TX_CB),
       
       // UFC Rx
       .NFC_PAUSE(NFC_PAUSE),

       // Data Tx
       .S_AXIS_TVALID(S_AXIS_TVALID),
       .S_AXIS_TREADY(S_AXIS_TREADY),
       .S_AXIS_TLAST (S_AXIS_TLAST),
       .S_AXIS_TDATA (S_AXIS_TDATA),

       // UFC Tx
       .UFC_REQ(UFC_REQ),
       .UFC_MS(UFC_MS),
       .S_AXIS_UFC_TVALID(S_AXIS_UFC_TVALID),
       .S_AXIS_UFC_TREADY(S_AXIS_UFC_TREADY),
       .S_AXIS_UFC_TDATA (S_AXIS_UFC_TDATA),

       // NFC Tx
       .S_AXIS_NFC_TVALID(S_AXIS_NFC_TVALID),
       .S_AXIS_NFC_TREADY(S_AXIS_NFC_TREADY),
       .S_AXIS_NFC_TDATA (S_AXIS_NFC_TDATA)
       );
   
endmodule // kyokko

`default_nettype wire
