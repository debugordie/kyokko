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
//    kyokko_tx_init: Link initialization control in Kyokko Tx subsystem
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_tx_init
  ( input wire CLK, RST, RXRST,
    input wire [3:0]   RX_STAT,
    output reg [3:0]   RX_STAT_TX,

    output reg         TX_SEND_CC,
    output wire [63:0] TXDATA );

   parameter SendCC_Rate = 4840;

   // ------------------------------------------------------------
   // RX stat synchronizer

   reg [3:0] RX_STAT_TXi;
   reg       RXRST_TXi, RXRST_TX;

   always @ (posedge CLK) begin 
      // needs RST because RX_STAT may be 'bxxx before RX_RST
      RXRST_TXi <= RXRST; RXRST_TX <= RXRST_TXi;
      
      if (RST | RXRST_TX) begin
         RX_STAT_TX  <= 3'b001;
         RX_STAT_TXi <= 3'b001;
      end else begin
         RX_STAT_TXi <= RX_STAT; RX_STAT_TX <= RX_STAT_TXi; end
   end

   // ------------------------------------------------------------
   // Wait for remote FSM to transmit CB block
   reg [3:0] TX_WFR_CNT;
   wire TX_WFR_CB = (TX_WFR_CNT==9);

   always @ (posedge CLK) begin
      if (RST) TX_WFR_CNT <= 0;
      else if (|RX_STAT_TX[2:1]) 
        TX_WFR_CNT <= (TX_WFR_CB ? 0 : TX_WFR_CNT + 1);  end

   // ------------------------------------------------------------
   // Ready state FSM to transmit CC block (4840 data blk + 7 CC blk)
   
   reg [12:0] TX_CC_CNT; // up to 8192 clk

   always @ (posedge CLK) begin
      if (~RX_STAT_TX[3]) begin // not in Ready state
         TX_SEND_CC <= 1;
         TX_CC_CNT  <= 0;
      end else begin
         if (TX_SEND_CC) begin
            if (TX_CC_CNT==6) begin
               TX_CC_CNT  <= 0;
               TX_SEND_CC <= 0;
            end else TX_CC_CNT <= TX_CC_CNT+1;
         end else begin
            if (TX_CC_CNT == SendCC_Rate-1) begin
               TX_CC_CNT  <= 0;
               TX_SEND_CC <= 1;
            end else TX_CC_CNT <= TX_CC_CNT + 1;
         end
      end
   end

   // ------------------------------------------------------------

   assign TXDATA = RX_STAT_TX[0] ? {  16'h7830, 48'h0} :             // NR+SA
                   RX_STAT_TX[1] ? ( TX_WFR_CB ? {16'h7840, 48'h0} : // CB
                                     {16'h7830, 48'h0} ) :           // NR+SA
                   // {16'h7810, 48'h0} ) : // SA
                   RX_STAT_TX[2] ? ( TX_WFR_CB ? {16'h7840, 48'h0} : // CB
                                     {16'h7810, 48'h0} ) : // SA
                   {16'h7810, 48'h0}; // Idle in RX_STAT[3], but not used
endmodule // kyokko_tx_init

`default_nettype wire
