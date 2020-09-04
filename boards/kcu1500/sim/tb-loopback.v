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
//    tb_kcu1500: Testbench for Xilinx KCU1500 board
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_kcu1500 
  (
`ifdef NO_LOOPBACK
   output wire [3:0]     QSFP0_TXP, QSFP0_TXN, QSFP1_TXP, QSFP1_TXN,
   input wire [3:0]     QSFP0_RXP, QSFP0_RXN, QSFP1_RXP, QSFP1_RXN
`endif
   );
   parameter real Step300 = 10.0/3.0;
   parameter real StepREF = 6.4;
   parameter NumCh = 8;

   reg            CLK300 = 1;
   reg            CLKREF = 1;
   always # (Step300/2) CLK300 <= ~CLK300;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [3:0]     QSFP0_TXP, QSFP0_TXN, QSFP1_TXP, QSFP1_TXN;
   wire [3:0]     QSFP0_RXP, QSFP0_RXN, QSFP1_RXP, QSFP1_RXN;

   assign QSFP0_RXP = QSFP0_TXP;
   assign QSFP0_RXN = QSFP0_TXN;
   assign QSFP1_RXP = QSFP1_TXP;
   assign QSFP1_RXN = QSFP1_TXN;
`endif
   
   reg            RST;

   kcu1500 uut
     ( .RST_N(~RST),
       .CLK300P    (CLK300), .CLK300N    (~CLK300),
       .QSFP0_REFCLKP(CLKREF), .QSFP0_REFCLKN(~CLKREF),
       .QSFP0_RXP(QSFP0_RXP), .QSFP0_RXN(QSFP0_RXN),
       .QSFP1_RXP(QSFP1_RXP), .QSFP1_RXN(QSFP1_RXN),
       .QSFP0_TXP(QSFP0_TXP), .QSFP0_TXN(QSFP0_TXN),
       .QSFP1_TXP(QSFP1_TXP), .QSFP1_TXN(QSFP1_TXN) );

`ifndef NO_LOOPBACK    
   initial begin
      $shm_open();
      $shm_probe("SA");
      
      #(300*1000) $finish;
   end
`endif //  `ifndef NO_LOOPBACK

   initial begin
      RST <= 1;
      #(100.1) RST <= 0;
   end
   
   genvar ch;
   for (ch=0; ch<NumCh; ch=ch+1) begin : ch_up_gen
      reg CH_UP_R;
      always @ (posedge uut.AURORA_CLK[ch]) begin
         CH_UP_R <= uut.CH_UP[ch];
         if (~CH_UP_R & uut.CH_UP[ch])  
           $display("%m KCU1500 channel %2d up at %f", ch, $realtime);

         if (CH_UP_R & ~uut.CH_UP[ch])  
           $display("%m KCU1500 channel %2d down at %f", ch, $realtime);
      end
   end
   
endmodule // tb

`default_nettype wire
