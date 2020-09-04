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
//    tb_c10gx: Testbench for Intel Cyclone 10 GX Dev kit simulation
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_c10gx
  (
`ifdef NO_LOOPBACK
   output wire [1:0]    SFP_TXP,
   input wire [1:0]     SFP_RXP
`endif
   );
   
   parameter real Step100 = 10;
   parameter real StepREF = 1000.0/644.53125;
   parameter NumCh = 2;

   reg            CLK100 = 1;
   reg            CLKREF = 1;
   always # (Step100/2) CLK100 <= ~CLK100;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [1:0]     SFP_TXP, SFP_RXP;

   assign SFP_RXP = SFP_TXP;
`endif

   reg            RST;

   c10gx uut
     ( .RST_N(~RST),
       .USRCLK (CLK100),
       .REFCLK644P(CLKREF),
       .SFP_RXP(SFP_RXP),
       .SFP_TXP(SFP_TXP) );

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
           $display("%m C10GX channel %2d up at %f", ch, $realtime);

         if (CH_UP_R & ~uut.CH_UP[ch])  
           $display("%m C10GX channel %2d down at %f", ch, $realtime);
         
      end
   end
   
endmodule // tb

`default_nettype wire
