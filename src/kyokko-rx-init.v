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
//    kyokko_rx_init: Kyokko Rx, Link initialization control
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_rx_init
  ( input wire CLK, RST,
    input wire [1:0]  RXHDR,
    input wire [63:0] RXDATA,
    input wire        CB_READY,
    output reg [3:0]  RX_STAT,
    output wire       RXSLIP,
    output reg        RXSLIP_LIMIT,
    output wire       LINK_ERR_O);

   wire               RX_STAT_NOLOCK = RX_STAT[0];
   wire               RX_LOCKED      = RX_STAT[1];

   wire               RXHDR_ERR = (RXHDR==2'b11) | (RXHDR==2'b00);
   
   // Lane Initialization (SP011 4.2.1)
   reg [5:0]          RXSLIP_TIMER;
   wire               RXSLIP_TIMER_FULL = (RXSLIP_TIMER==32);
   //  assign               RXSLIP = RX_STAT_NOLOCK & RXSLIP_TIMER_FULL;
   assign             RXSLIP = RX_STAT_NOLOCK & ( RXSLIP_TIMER_FULL |
                                                     (RXSLIP_TIMER==31) | 
                                                     (RXSLIP_TIMER==30) );

   reg [7:0]          RXSLIP_CNT; // to limit # of RXSLIP
   // reg             RXSLIP_LIMIT;
   
   wire               RX_NR_DETECTED;
   assign RX_NR_DETECTED = ( (RXDATA[63:56] == 8'h78) &
                             ( (RXDATA[55:48] == 8'b0010_0000) |   // NR
                               (RXDATA[55:48] == 8'b0011_0000) |   // NR+SA
                               (RXDATA[55:48] == 8'b0100_0000) ) & // NR+CB
                             (RXDATA[47:0] == 0) &
                             (RXHDR == 2'b10 ) );
   // Wait 4 remote count
   reg [9:0]          W4R_CNT, W4R_RXCNT;
   
   // Other control signals
   wire               RX_IS_CTRL = (RXHDR == 2'b10);
   wire               RX_IS_IDLE = ( RX_IS_CTRL & 
                                     (RXDATA[63:56] == 8'h78 &
                                      RXDATA[51:0] == 0) );
   wire               RX_IS_CC = RX_IS_IDLE & RXDATA[55]; // Clock comp
   wire               RX_IS_CB = RX_IS_IDLE & RXDATA[54]; // Ch bond
   wire               RX_IS_NR = RX_IS_IDLE & RXDATA[53]; // Not ready
   wire               RX_IS_SA = RX_IS_IDLE & RXDATA[52]; // Strict align
   wire               RX_IS_SEPARATOR = RX_IS_CTRL & (RXDATA[63:56] == 8'h1e);

   // Main Rx FSM
   always @ (posedge CLK) begin
      if (RST) begin // RST driven Transceiver Rx ready
         RX_STAT <= 1;
         RXSLIP_TIMER <= 0;
         RXSLIP_CNT   <= 0;
         RXSLIP_LIMIT <= 0;
      end else begin
         case (RX_STAT)
           'b0001: begin // NOLOCK: Lane Initialization
              // Slip once in 32clk
              // RXSLIP_TIMER <= RXSLIP_TIMER_FULL ? 0 : RXSLIP_TIMER+1;

              // Longer RXSLIP interval is better for Intel FPGAs
              RXSLIP_TIMER <= RXSLIP_TIMER + 1;

              // Max RXSLIP check: expect Rx path reset from top module
              if (RXSLIP_TIMER_FULL) RXSLIP_CNT <= RXSLIP_CNT + 1;
              if (RXSLIP_CNT==128)   RXSLIP_LIMIT <= 1;
              
              if (RX_NR_DETECTED) begin
                 RX_STAT <= 'b0010;
                 W4R_CNT <= 0;
                 RXSLIP_CNT <= 0;
              end
           end

           'b0010: begin // LOCKED, Channel bonding? (send CB/NR+SA)
              if (RXHDR_ERR) begin
                 RX_STAT <= 'b0001;
                 RXSLIP_CNT <= 0;
                 RXSLIP_TIMER <= 0;
                 RXSLIP_LIMIT <= 0;
              end else begin
                 if ((~(RX_IS_CC | RX_IS_CB | RX_IS_NR) | W4R_CNT ==400) & CB_READY) begin
                    RX_STAT <= 'b0100;
                    W4R_CNT <= 0;
                    W4R_RXCNT <= 0;
                 end else begin
                    RX_STAT <= RX_STAT;
                    if ((RX_IS_CB | RX_IS_CC) & CB_READY) 
                      W4R_CNT <= W4R_CNT + 1;
                 end
              end
           end 
	   
           'b0100: begin // Wait for remote: transmit & receive at least 64 idles (send CB/SA)
              if (~RX_IS_IDLE) RX_STAT <= 'b1000;
              else begin
                 W4R_CNT <= W4R_CNT + ((W4R_CNT==128) ? 0 : 1);
                 if (~RX_IS_NR & RX_IS_IDLE) 
                   W4R_RXCNT <= W4R_RXCNT + ((W4R_RXCNT==64) ? 0 : 1);
                 if (W4R_CNT == 128 & W4R_RXCNT==64) RX_STAT <= 'b1000;
              end
           end

           'b1000: begin // Channel Ready = Link is up
              if (RXHDR_ERR | RX_IS_NR) begin
                 RX_STAT <= 'b0001;
                 RXSLIP_CNT <= 0;
                 RXSLIP_TIMER <= 0;
                 RXSLIP_LIMIT <= 0;
              end else begin
                RX_STAT <= RX_STAT;
              end
           end

           default: begin
              RX_STAT <= 'b0001;  end
         endcase
      end
   end // always @ (posedge CLK)

   // Link error notifier: asserts for 15clk
   
   wire LINK_ERR = RX_STAT[3] & (RXHDR_ERR | RX_IS_NR);
   reg [3:0] LINK_ERR_TIMER;

   always @ (posedge CLK) begin
      if (RST) begin
         LINK_ERR_TIMER <= 0;
      end else begin
         if (LINK_ERR) LINK_ERR_TIMER <= 1;
         else LINK_ERR_TIMER <= (LINK_ERR_TIMER==0) ? 0 : LINK_ERR_TIMER+1;
      end
   end

   assign LINK_ERR_O = (LINK_ERR_TIMER != 0);

endmodule // kyokko_rx_init

`default_nettype none
