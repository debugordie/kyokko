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
//    kyokko_rx_ctrl: Kyokko Rx subsystem
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_rx_ctrl # ( parameter BondingEnable = 0, BondingCh = 1 )
  (  input wire CLK, RST, TXCLK, TXRST,
     input wire [63:0]  RXS,
     input wire [1:0]   RXHDRi,
     input wire         FIFO_RE,
     input wire         CB_FINISH,
     output wire [3:0]  RX_STAT,
     output wire        RXSLIP,
     output wire        RXSLIP_LIMIT,
     output wire        RXCB,
     output wire        NFC_PAUSE,
     output wire        UFC_MODE_O,
     input wire         UFC_MODE_I,
     output wire        M_AXIS_TVALID, M_AXIS_TLAST,
     output wire        M_AXIS_UFC_TVALID, M_AXIS_UFC_TLAST,
     output wire [63:0] M_AXIS_TDATA, M_AXIS_UFC_TDATA );

   wire [63:0]          RXDATA;
   
   teng_desc desc
     ( .CLK(CLK),  .RST(RST), 
       .S  (RXS),  .D  (RXDATA ) );

   reg [1:0]          RXHDR;
   always @ (posedge CLK) RXHDR <= RXHDRi[1:0];

   kyokko_rx_init rxinit
     ( .CLK(CLK),  .RST(RST),
       .RXHDR   (RXHDR),
       .RXDATA  (RXDATA),
       .RX_STAT (RX_STAT),
       .RXSLIP  (RXSLIP),
       .RXSLIP_LIMIT(RXSLIP_LIMIT),
       .CB_FINISH(CB_FINISH) );
   
   wire [1:0]         RXHDRt;
   wire [63:0]        RXDATAt;
   wire               RXVALIDt;

   wire FIFO_WE = (~RX_STAT[0] &
		   ((RXHDR == 2'b10) &
		    (RXDATA[63:56] == 8'h78 &
		     RXDATA[51:0] == 0) &
		    RXDATA[55]) );

   fifo_66x512_async rxfifo
     ( .rst(RST),                 // I
       .wr_clk(CLK),              // I
       .rd_clk(TXCLK),            // I
       .din  ({RXHDR, RXDATA}),   // I [65:0]
       .wr_en(~RX_STAT[0]),       // I
       .rd_en(FIFO_RE),           // I
       .dout({RXHDRt, RXDATAt}),  // O [65:0]
       .full(),                   // O
       .empty(),                  // O
       .valid(RXVALIDt)           // O
      );

   assign RXCB = ((RXHDRt == 2'b10) &
		  (RXDATAt[63:56] == 8'h78 &
		   RXDATAt[51:0] == 0) &
		  RXDATAt[54] );
  
   wire [63:0]        IDLE_SA = {8'h78, 8'b0001_0000, 48'h0 };
   wire [1:0]         HDR_HDR = 2'b10;
   
   kyokko_rx_axis # (.BondingEnable(BondingEnable), .BondingCh(BondingCh)) 
   rxaxis
     ( .CLK (TXCLK),
       .RST (TXRST),
       .RX_READYi (RX_STAT[3]),
       .RXHDR  (RXVALIDt ? RXHDRt  : HDR_HDR),
       .RXDATA (RXVALIDt ? RXDATAt : IDLE_SA),
       .NFC_PAUSE         (NFC_PAUSE),
       .UFC_MODE_O        (UFC_MODE_O),
       .UFC_MODE_I        (UFC_MODE_I),
       .M_AXIS_TVALID     (M_AXIS_TVALID), 
       .M_AXIS_TLAST      (M_AXIS_TLAST ),
       .M_AXIS_TDATA      (M_AXIS_TDATA ), 
       .M_AXIS_UFC_TVALID (M_AXIS_UFC_TVALID), 
       .M_AXIS_UFC_TLAST  (M_AXIS_UFC_TLAST),
       .M_AXIS_UFC_TDATA  (M_AXIS_UFC_TDATA)
      );

endmodule // kyokko_rx_ctrl

`default_nettype wire
