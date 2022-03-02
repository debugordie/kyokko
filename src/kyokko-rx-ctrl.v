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
     input wire [63:0] 	RXS,
     input wire [1:0] 	RXHDRi,
     input wire 	FIFO_RE,
     input wire [4:0] 	CB_STAT,
     input wire 	CB_ENABLE, 
     input wire 	CB_READY,
     output wire [3:0] 	RX_STAT,
     output wire 	RX_ERR, 
     output wire 	RXSLIP,
     output wire 	RXSLIP_LIMIT,
     output wire 	RX_IS_CB,
     output wire 	DATA_IS_VALID,
     output wire 	NFC_PAUSE,
     output wire 	UFC_MODE_O,
     input wire 	UFC_MODE_I,
     output wire 	FIFO_EMPTY,
     output wire 	M_AXIS_TVALID, M_AXIS_TLAST,
     output wire 	M_AXIS_UFC_TVALID, M_AXIS_UFC_TLAST,
     output wire [63:0] M_AXIS_TDATA, M_AXIS_UFC_TDATA );

   wire [63:0]          RXDATA;
   
   teng_desc desc
     ( .CLK(CLK),  .RST(RST), 
       .S  (RXS),  .D  (RXDATA ) );

   reg [1:0]          RXHDR;
   always @ (posedge CLK) RXHDR <= RXHDRi[1:0];

   
   // CB status synchronizer
   reg [4:0] 	      CB_STAT_RX, CB_STATi;
   reg                CB_READY_R, CB_READYi;
   always @ (posedge CLK) begin
      CB_STATi <= CB_STAT; CB_STAT_RX <= CB_STATi;      
      CB_READYi <= CB_READY_R; CB_READY_R <= CB_READY; end

   kyokko_rx_init rxinit
     ( .CLK(CLK),  .RST(RST),
       .RXHDR       (RXHDR),
       .RXDATA      (RXDATA),
       .CB_READY    (CB_READYi),
       .RX_STAT     (RX_STAT),
       .RXSLIP      (RXSLIP),
       .RXSLIP_LIMIT(RXSLIP_LIMIT),
       .LINK_ERR_O  (RX_ERR) );
   
   wire [1:0]         RXHDRt;
   wire [63:0]        RXDATAt;
   wire               RXVALIDt;

   wire 	      WE_NML = ( ~RX_STAT[0] &
                                 CB_ENABLE & 
	                         ~((RXHDR == 2'b10) &
	                           (RXDATA[63:56] == 8'h78) & 
		                   RXDATA[55]) );

   wire 	      WE_CB = ( ~RX_STAT[0] &
				CB_ENABLE &
				(RXHDR == 2'b10) &
				((RXDATA[63:56] == 8'h78) &
                                 (RXDATA[51:0] == 0) &
				 RXDATA[54]) );

   wire 	      FIFO_WE = CB_STAT_RX[1] ? WE_CB : WE_NML;
   
   /*
   wire               FIFO_WE = ( ~RX_STAT[0] &
				  CB_ENABLE & 
				  ~((RXHDR == 2'b10) &
				    (RXDATA[63:56] == 8'h78) & 
				    RXDATA[55]) );
    */

   wire               FIFO_REi = (BondingEnable==1) ? FIFO_RE : 1;
   
   fifo_66x512_async rxfifo
     ( .rst(RST),                 // I
       .wr_clk(CLK),              // I
       .rd_clk(TXCLK),            // I
       .din  ({RXHDR, RXDATA}),   // I [65:0]
       .wr_en(FIFO_WE),           // I
       .rd_en(FIFO_REi),          // I
       .dout({RXHDRt, RXDATAt}),  // O [65:0]
       .full(),                   // O
       .empty(FIFO_EMPTY),        // O
       .valid(RXVALIDt)           // O
      );

   wire 	      RX_IS_CTRL = (RXHDRt == 2'b10);
   wire 	      RX_IS_IDLE = (RXVALIDt &
				    RX_IS_CTRL &
				    (RXDATAt[63:56] == 8'h78 &
				     RXDATAt[51:0] == 0) );
   wire 	      RX_IS_SA = RXVALIDt & RX_IS_IDLE & RXDATAt[52];
   assign             RX_IS_CB = RXVALIDt & RX_IS_IDLE & RXDATAt[54];
   
   assign DATA_IS_VALID = (RX_IS_IDLE | RX_IS_SA | RX_IS_CB);
  
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
