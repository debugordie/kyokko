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
//    tb_ku040_kyokko_single: Testbench for KU040 DB with 1x Kyokko on SFP
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_ku040_kyokko_single
  (
`ifdef NO_LOOPBACK
   output wire [1:1]    SFP_TXP, SFP_TXN,
   input wire [1:1]     SFP_RXP, SFP_RXN
`endif
   );
   parameter real       Step250 = 4;
   parameter real StepREF = 6.4;

   reg            CLK250 = 1;
   reg            CLKREF = 1;
   always # (Step250/2) CLK250 <= ~CLK250;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [1:1]     SFP_TXP, SFP_TXN;
   wire [1:1]     SFP_RXP, SFP_RXN;

   assign SFP_RXP = SFP_TXP;
   assign SFP_RXN = SFP_TXN;
`endif
   reg            RST;

   ku040_kyokko_single uut
     ( .RST(RST),
       .CLK250P    (CLK250), .CLK250N    (~CLK250),
       .SFP_REFCLKP(CLKREF), .SFP_REFCLKN(~CLKREF),
       .SFP_RXP(SFP_RXP), .SFP_RXN(SFP_RXN),
       .SFP_TXP(SFP_TXP), .SFP_TXN(SFP_TXN) );

`ifndef NO_LOOPBACK
   initial begin
      `include "wave-record.vh"
      
      #(300*1000) $finish;
   end
`endif

   initial begin
      RST <= 1;
      #(100.1) RST <= 0;
   end
   
   reg CH_UP_R;
   always @ (posedge uut.AURORA_CLK) begin
      CH_UP_R <= uut.CH_UP;
      if (~CH_UP_R & uut.CH_UP)  
        $display("%m KU040 up at %f", $realtime);

      if (CH_UP_R & ~uut.CH_UP)  
        $display("%m KU040 down at %f", $realtime);
   end
   
endmodule // tb
  
`default_nettype wire
