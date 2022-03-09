`timescale 1ns/1ps
`default_nettype none

module wdelay(input wire [3:0] I, 
              output reg [3:0] O);
   parameter real Dly0 = 0.1;
   parameter real Dly1 = 0.1;
   parameter real Dly2 = 8.1;
   parameter real Dly3 = 19.4;
   
   always @ (I) begin
      O[0] <= #Dly0 I[0];
      O[1] <= #Dly1 I[1];
      O[2] <= #Dly2 I[2];
      O[3] <= #Dly3 I[3];
   end
endmodule // wdelay

module tb();
   wire [3:0] AU50_TXP, AU50_TXN, AU50_TXPd, AU50_TXNd, HAWKEYE_TXP;
   reg  LINK_UP;

   wdelay dly15_0p ( .I(AU50_TXP), .O(AU50_TXPd) );
   wdelay dly15_0n ( .I(AU50_TXN), .O(AU50_TXNd) );

   // Use faster clock
   // defparam au50.StepREF = 1000.0/322.4;
   defparam hawkeye.StepREF = 1000.0/644.8;

   tb_au50 # (.BondingEnable(1), .BondingCh(4)) au50
     ( .QSFP_TXP(AU50_TXP), 
       .QSFP_TXN(AU50_TXN),
       .QSFP_RXP(LINK_UP ?  HAWKEYE_TXP : 4'b0), 
       .QSFP_RXN(LINK_UP ? ~HAWKEYE_TXP : 4'b0) );

   tb_hawkeye # (.BondingEnable(1), .BondingCh(4)) hawkeye
     ( .SFP_TXP(HAWKEYE_TXP),
       .SFP_RXP(LINK_UP ? AU50_TXPd : 4'b0) );

   initial begin
      `include "wave-record.vh"
      LINK_UP <= 1;

      #(300*1000)  LINK_UP <= 0;
      #(    1000)  LINK_UP <= 1;
      #(300*1000)  $finish;
   end

endmodule

`default_nettype wire
