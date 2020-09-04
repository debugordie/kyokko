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
//    tb_ku040_kyokko: Testbench for KU040 DB with 4x Kyokko on 2xSFP+2xSMA
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_ku040_kyokko
  (
`ifdef NO_LOOPBACK
   output wire [1:0]    SFP_TXP, SFP_TXN, SMA_TXP, SMA_TXN,
   input wire [1:0]     SFP_RXP, SFP_RXN, SMA_RXP, SMA_RXN
`endif
   );
   
   parameter real Step250 = 4;
   parameter real StepREF = 6.4;
   parameter NumCh = 4;

   reg            CLK250 = 1;
   reg            CLKREF = 1;
   always # (Step250/2) CLK250 <= ~CLK250;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [1:0]     SFP_TXP, SFP_TXN, SMA_TXP, SMA_TXN;
   wire [1:0]     SFP_RXP, SFP_RXN, SMA_RXP, SMA_RXN;

   assign SFP_RXP = SFP_TXP;
   assign SFP_RXN = SFP_TXN;
   assign SMA_RXP = SMA_TXP;
   assign SMA_RXN = SMA_TXN;
`endif

   reg            RST;

   ku040 uut
     ( .RST(RST),
       .CLK250P    (CLK250), .CLK250N    (~CLK250),
       .SFP_REFCLKP(CLKREF), .SFP_REFCLKN(~CLKREF),
       .SFP_RXP(SFP_RXP), .SFP_RXN(SFP_RXN),
       .SMA_RXP(SMA_RXP), .SMA_RXN(SMA_RXN),
       .SFP_TXP(SFP_TXP), .SFP_TXN(SFP_TXN),
       .SMA_TXP(SMA_TXP), .SMA_TXN(SMA_TXN) );

`ifndef NO_LOOPBACK
   initial begin
      $shm_open();
      $shm_probe("SA");
      
      #(300*1000) $finish;
   end
`endif //  `ifndef NO_LOOPBACK

   initial  begin
      RST <= 1;
      #(100.1) RST <= 0;
   end
      
   
   genvar ch;
   for (ch=0; ch<NumCh; ch=ch+1) begin : ch_up_gen
      reg CH_UP_R;
      always @ (posedge uut.AURORA_CLK[ch]) begin
         CH_UP_R <= uut.CH_UP[ch];
         if (~CH_UP_R & uut.CH_UP[ch])  
           $display("%m KU040 channel %2d up at %f", ch, $realtime);

         if (CH_UP_R & ~uut.CH_UP[ch])  
           $display("%m KU040 channel %2d down at %f", ch, $realtime);
         
      end
   end
   
endmodule // tb

`default_nettype wire
