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
//    tb_de10pro_b: Simulation testbench for DE10-Pro Rev.B board
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module tb_de10pro_b #
  ( BondingEnable=0, // Set to 1 to enable
    BondingCh=4
    )
   (
`ifdef NO_LOOPBACK
    output wire [3:0][3:0]    QSFP_TXP,
    input wire [3:0][3:0]     QSFP_RXP
`endif
    );
   
   parameter real             Step100 = 10.0;
   parameter real             StepREF = 1000.0/644.53125;
   parameter                  NumCh = 16;

   parameter                  NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);

   reg                        CLK100 = 1;
   reg                        CLKREF = 1;
   always # (Step100/2) CLK100 <= ~CLK100;
   always # (StepREF/2) CLKREF <= ~CLKREF;

`ifndef NO_LOOPBACK
   wire [3:0][3:0]            QSFP_TXP;
   reg [3:0][3:0]             QSFP_RXP;

   always @ (*) begin
      QSFP_RXP[0] <= #1.2 QSFP_TXP[0];
      QSFP_RXP[1] <= #1.2 QSFP_TXP[1];
      QSFP_RXP[2] <= #1.2 QSFP_TXP[2];
      QSFP_RXP[3] <= #1.2 QSFP_TXP[3];
   end
`endif

   reg            RST;

   de10pro_b #(.BondingEnable(BondingEnable), .BondingCh(BondingCh)) uut
     ( .PCIE_PERST_N(~RST),
       .CLK100 (CLK100),
       .QSFP_REFCLKP({4{CLKREF}}),
       .QSFP_RXP(QSFP_RXP),
       .QSFP_TXP(QSFP_TXP) );

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
   
   genvar ch, lane;
   generate
      if (BondingEnable==0) begin : nobond_chup
         for (ch=0; ch<NumCh; ch=ch+1) begin : ch_up_gen
            reg CH_UP_R;
            always @ (posedge uut.AURORA_CLK[ch/4]) begin
               CH_UP_R <= uut.CH_UP[ch/4][ch%4];
               if (~CH_UP_R & uut.CH_UP[ch/4][ch%4])  
                 $display("%m S10 channel %2d up at %f", ch, $realtime);

               if (CH_UP_R & ~uut.CH_UP[ch/4][ch%4])  
                 $display("%m S10 channel %2d down at %f", ch, $realtime);
            end
         end // block: ch_up_gen
      end else begin : bond_chup
         for (ch=0; ch<NumChB; ch=ch+1) begin : ch_up_gen
            reg CH_UP_R;
            always @ (posedge uut.AURORA_CLK[ch]) begin
               CH_UP_R <= uut.CH_UP[ch][0];
               if (~CH_UP_R & uut.CH_UP[ch][0])  
                 $display("%m S10 channel %2d up at %f", ch, $realtime);

               if (CH_UP_R & ~uut.CH_UP[ch][0])  
                 $display("%m S10 channel %2d down at %f", ch, $realtime);
            end
         end // block: ch_up_gen
         
      end // else: !if(BondingEnable==0)
   endgenerate

endmodule // tb

`default_nettype wire
