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
//    tb_kc705_aurora: Testbench for Xilinx KC705 board
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

`ifdef CHBOND_4CH
 `define KC705_AURORA kc705_aurora4
`else
 `define KC705_AURORA kc705_aurora
`endif

module tb_kc705_aurora
  (
`ifdef NO_LOOPBACK
   output wire [3:0] SFP_TXP, SFP_TXN,
   input wire [3:0] SFP_RXP, SFP_RXN
`endif
   );
   
   parameter real Step200 = 5;
   parameter real StepREF = 6.4;
   parameter NumCh = 1;

   reg            CLK200 = 1;
   reg            CLKREF = 1;
   always # (Step200/2) CLK200 <= ~CLK200;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [3:0]     SFP_TXP, SFP_TXN, SFP_RXP, SFP_RXN;

   assign SFP_RXP = SFP_TXP;
   assign SFP_RXN = SFP_TXN;
`endif
   
   reg            RST;

   `KC705_AURORA uut
     ( .RST(RST),
       .CLK200P(CLK200), .CLK200N (~CLK200),
       .CLK156P(CLKREF), .CLK156N(~CLKREF),
`ifdef CHBOND_4CH
       .FMC_RXP(SFP_RXP), .FMC_RXN(SFP_RXN),
       .FMC_TXP(SFP_TXP), .FMC_TXN(SFP_TXN)
`else 
       .SFP_RXP(SFP_RXP), .SFP_RXN(SFP_RXN),
       .SFP_TXP(SFP_TXP), .SFP_TXN(SFP_TXN)
`endif
       );

`ifndef NO_LOOPBACK
   initial begin
      `include "wave-record.vh"
      
      #(300*1000) $finish;
   end
`endif //  `ifndef NO_LOOPBACK

   initial begin
      RST <= 1;
      #(100.1) RST <= 0;
   end
   
   reg CH_UP_R;
   always @ (posedge uut.AURORA_CLK) begin
      CH_UP_R <= uut.CH_UP;
      if (~CH_UP_R & uut.CH_UP)  
        $display("%m KC705 channel up at %f", $realtime);
      
      if (CH_UP_R & ~uut.CH_UP)  
        $display("%m KC705 channel down at %f", $realtime);
   end
   
endmodule // tb

`default_nettype wire
