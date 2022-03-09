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
//    tb_au50: Testbench for Xilinx Alveo U50 simulation
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_au50
  (
`ifdef NO_LOOPBACK
   output wire [3:0]     QSFP_TXP, QSFP_TXN,
   input wire [3:0]     QSFP_RXP, QSFP_RXN
`endif
   );

   parameter BondingEnable=0; // Set to 1 to enable
   parameter BondingCh=4;

   parameter real Step100 = 10.0;
   parameter real StepREF = 1000.0/322.265625; // correct freq
   parameter NumCh = 4;

   parameter NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);

   reg            CLK100 = 1;
   reg            CLKREF = 1;
   always # (Step100/2) CLK100 <= ~CLK100;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [3:0]     QSFP_TXP, QSFP_TXN;
   reg [3:0]     QSFP_RXP, QSFP_RXN;

   always @ (*) begin
      QSFP_RXP[0] <= #1.2 QSFP_TXP[0];   QSFP_RXN[0] <= #1.2 QSFP_TXN[0];
      QSFP_RXP[1] <= #3.4 QSFP_TXP[1];   QSFP_RXN[1] <= #3.4 QSFP_TXN[1];
      QSFP_RXP[2] <= #5.6 QSFP_TXP[2];   QSFP_RXN[2] <= #5.6 QSFP_TXN[2];
      QSFP_RXP[3] <= #7.8 QSFP_TXP[3];   QSFP_RXN[3] <= #7.8 QSFP_TXN[3];
   end
`endif
   
   reg            RST;

   au50 #(.BondingEnable(BondingEnable), .BondingCh(BondingCh)) uut
     ( .PCIE_RESET_N(~RST),
       .CMC_CLKP(CLK100), .CMC_CLKN(~CLK100),
       .CLK322P (CLKREF), .CLK322N (~CLKREF),
       .QSFP_RXP(QSFP_RXP), .QSFP_RXN(QSFP_RXN),
       .QSFP_TXP(QSFP_TXP), .QSFP_TXN(QSFP_TXN) );

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
   
   genvar ch;
   for (ch=0; ch<NumChB; ch=ch+1) begin : ch_up_gen
      reg CH_UP_R;
      always @ (posedge uut.AURORA_CLK[ch]) begin
         CH_UP_R <= uut.CH_UP[ch];
         if (~CH_UP_R & uut.CH_UP[ch])  
           $display("%m AU50 channel %2d up at %f", ch, $realtime);

         if (CH_UP_R & ~uut.CH_UP[ch])  
           $display("%m AU50 channel %2d down at %f", ch, $realtime);
      end
   end
   
endmodule // tb

`default_nettype wire
