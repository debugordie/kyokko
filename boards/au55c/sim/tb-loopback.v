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
//    tb_vu35p: Testbench for VU35P board simulation
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_vu35p #
  ( BondingEnable=0, // Set to 1 to enable
    BondingCh=4
    )
  (
`ifdef NO_LOOPBACK
   output wire [3:0]    QSFP0_TXP, QSFP0_TXN, QSFP1_TXP, QSFP1_TXN,
   input wire [3:0]     QSFP0_RXP, QSFP0_RXN, QSFP1_RXP, QSFP1_RXN
`endif
   );
   parameter real Step100 = 10.0;
   parameter real StepREF = 1000.0/161.1328125;
   parameter NumCh = 8;

   parameter NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);

   reg            CLK100 = 1;
   reg            CLKREF = 1;
   always # (Step100/2) CLK100 <= ~CLK100;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [3:0]     QSFP0_TXP, QSFP0_TXN, QSFP1_TXP, QSFP1_TXN;
   wire [3:0]     QSFP0_RXP, QSFP0_RXN, QSFP1_RXP, QSFP1_RXN;

   assign QSFP0_RXP = QSFP0_TXP;    assign QSFP1_RXP = QSFP1_TXP; 
   assign QSFP0_RXN = QSFP0_TXN;    assign QSFP1_RXN = QSFP1_TXN;
`endif
   
   reg            RST;

   vu35p #(.BondingEnable(BondingEnable), .BondingCh(BondingCh)) uut
     ( .PCIE_RESET_N(~RST),
       .SLR0_CLK100P(CLK100), .SLR0_CLK100N(~CLK100),
       .SLR1_CLK100P(CLK100), .SLR1_CLK100N(~CLK100),
       .CLK161P (CLKREF), .CLK161N (~CLKREF),
       .QSFP0_RXP(QSFP0_RXP), .QSFP0_RXN(QSFP0_RXN),
       .QSFP0_TXP(QSFP0_TXP), .QSFP0_TXN(QSFP0_TXN),
       .QSFP1_RXP(QSFP1_RXP), .QSFP1_RXN(QSFP1_RXN),
       .QSFP1_TXP(QSFP1_TXP), .QSFP1_TXN(QSFP1_TXN) );

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
           $display("%m VU35P channel %2d up at %f", ch, $realtime);

         if (CH_UP_R & ~uut.CH_UP[ch])  
           $display("%m VU35P channel %2d down at %f", ch, $realtime);
      end
   end
   
endmodule // tb

`default_nettype wire
