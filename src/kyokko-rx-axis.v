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
//    kyokko_rx_axis: Data/UFC/NFC receiver and AXIS interface of Kyokko Rx
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_rx_axis
  ( input wire CLK, RST, // works in TXCLK domain
    input wire         RX_READYi, // in RXCLK domain
    input wire [1:0]   RXHDR,
    input wire [63:0]  RXDATA,
    output reg         NFC_PAUSE,
    
    output wire        RXSLIP_LIMIT,
    output wire        M_AXIS_TVALID, M_AXIS_TLAST,
    output wire        M_AXIS_UFC_TVALID, M_AXIS_UFC_TLAST,
    output wire [63:0] M_AXIS_TDATA, M_AXIS_UFC_TDATA );

   wire                RX_IS_CTRL = (RXHDR == 2'b10);
   wire                RX_IS_IDLE = ( RX_IS_CTRL & 
                                     (RXDATA[63:56] == 8'h78 &
                                      RXDATA[51:0] == 0) );

   wire                RX_IS_SEPARATOR = RX_IS_CTRL & (RXDATA[63:56] == 8'h1e);

   // RX_READY synchronizer with reset
   reg                 RX_READYr, RX_READY;
   
   always @ (posedge CLK) begin
      RX_READYr <= RX_READYi;
      RX_READY  <= RST ? 0 : RX_READYr;
   end

   // - - - - - - - - - - - - - - -
   // Natie Flow Control
   wire                RX_IS_NFC = RX_IS_CTRL & (RXDATA[63:56] == 8'haa);
   wire [7:0]          RX_NFC_PAUSE = RXDATA[55:48];
   wire                RX_NFC_XOFF = RXDATA[47];

   reg                 NFC_XOFF_R;
   reg [7:0]           NFC_PAUSE_R;
   
   always @ (posedge CLK) begin
      if (~RX_READY) begin
         NFC_XOFF_R <= 0;
         NFC_PAUSE_R <= 0;
      end else begin
         if (RX_IS_NFC) begin
            NFC_XOFF_R <= ( RX_NFC_XOFF ? 1 : 
                            (~RX_NFC_XOFF & (RX_NFC_PAUSE==0)) ? 0 :
                            NFC_XOFF_R );
            NFC_PAUSE_R <= (RX_NFC_PAUSE != 0) ? RX_NFC_PAUSE+1 : 0;
         end else begin
            NFC_PAUSE_R <= (NFC_PAUSE_R != 0) ? NFC_PAUSE_R-1 : 0;
         end
      end // else: !if(~RX_READY)

      NFC_PAUSE = NFC_XOFF_R | (NFC_PAUSE_R != 0);
   end

   // - - - - - - - - - - - - - - - 
   // User Flow Control
   
   wire                RX_UFC_REQ = (RX_IS_CTRL  &
                                     (RXDATA[63:56] == 8'h2D) &
                                     (RXDATA[47:0] == 0) );
   reg [1:0]           UFC_STAT;
   reg [7:0]           UFC_MS;
   
   // UFC control FSM
   always @ (posedge CLK) begin
      if (~RX_READY) begin
         UFC_STAT <= 'b01;
      end else begin
         case (UFC_STAT)
           'b01: begin // idle
              if (RX_UFC_REQ) begin
                 UFC_STAT <= 'b10;
                 UFC_MS <= (RXDATA[55:48] + 1);
              end
           end

           'b10: begin //receive UFC data
	      if (UFC_MS == 0) UFC_STAT <= 'b01;
	      else  UFC_MS <= (~RX_IS_IDLE) ? UFC_MS -8 :
			      UFC_MS;
           end
         endcase // case (UFC_STAT)
      end
   end // always @ (posedge CLK)

   // - - - - - - - - - - - - - - - 
   // RX byte order ctrl
   wire [63:0] RXDATA2 =
               { RXDATA[ 7: 0], RXDATA[15: 8], RXDATA[23:16], RXDATA[31:24],
                 RXDATA[39:32], RXDATA[47:40], RXDATA[55:48], RXDATA[63:56]};

   // RX output control: TLAST generator
   wire        UFC_MODE  = ~RX_IS_IDLE & UFC_STAT[1];
   wire        RX_IS_DATA = ~UFC_MODE  & ~RX_IS_CTRL;

   reg [63:0]  RXDATA2_R;
   reg         RXDATA2_R_VALID;

   always @ (posedge CLK) begin
      if (~RX_READY) begin
         RXDATA2_R_VALID <= 0;
      end else begin
         if (RX_IS_DATA) RXDATA2_R <= RXDATA2;
         
         RXDATA2_R_VALID <= RX_IS_DATA ? 1 : RX_IS_SEPARATOR ? 0 : RXDATA2_R_VALID;
           
      end
   end

   assign M_AXIS_TVALID = (RXDATA2_R_VALID & RX_IS_DATA) | RX_IS_SEPARATOR;
   assign M_AXIS_TDATA = RXDATA2_R;
   assign M_AXIS_TLAST = RX_READY & RX_IS_SEPARATOR;
   
   assign M_AXIS_UFC_TDATA =   UFC_MODE ? RXDATA2 : 0;
   assign M_AXIS_UFC_TVALID =  UFC_MODE;
   assign M_AXIS_UFC_TLAST = ( UFC_MODE & (UFC_MS == 8) );

endmodule // kyokko_rx_axis

`default_nettype wire
