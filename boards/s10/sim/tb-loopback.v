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
//    tb_s10: Simulation testbench for Stratix10 QSFP board
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_s10 #
  ( BondingEnable=0, // Set to 1 to enable
    BondingCh=4
    )
  (
`ifdef NO_LOOPBACK
   output wire [3:0]    SFP_TXP,
   input wire [3:0]     SFP_RXP
`endif
   );
   
   parameter real Step250 = 4;
   parameter real StepREF = 1000.0/644.53125;
   parameter NumCh = 4;

   parameter NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);

   reg            CLK250 = 1;
   reg            CLKREF = 1;
   always # (Step250/2) CLK250 <= ~CLK250;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [3:0]     SFP_TXP;
   reg [3:0] SFP_RXP;

   always @ (*) begin
     SFP_RXP[0] <= #1.2 SFP_TXP[0];
     SFP_RXP[1] <= #1.2 SFP_TXP[1];
     SFP_RXP[2] <= #1.2 SFP_TXP[2];
     SFP_RXP[3] <= #1.2 SFP_TXP[3];
   end
`endif

   reg            RST;

   s10 #(.BondingEnable(BondingEnable), .BondingCh(BondingCh)) uut
     ( .PCIE_RESET_N(~RST),
       .CLK250 (CLK250),
       .CLK644P(CLKREF),
       .SFP_RXP(SFP_RXP),
       .SFP_TXP(SFP_TXP) );

`ifndef NO_LOOPBACK
   initial begin
      `include "wave-record.vh"
      
      #(800*1000) $finish;
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
           $display("%m S10 channel %2d up at %f", ch, $realtime);

         if (CH_UP_R & ~uut.CH_UP[ch])  
           $display("%m S10 channel %2d down at %f", ch, $realtime);
      end
   end
   
endmodule // tb

`default_nettype wire
