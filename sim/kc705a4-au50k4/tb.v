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
   wire [3:0] KC705_TXP, KC705_TXN, KC705_TXPd, KC705_TXNd,
              AU50_TXP0, AU50_TXN0;
   reg  LINK_UP;

   wdelay dly705_0p ( .I(KC705_TXP), .O(KC705_TXPd) );
   wdelay dly705_0n ( .I(KC705_TXN), .O(KC705_TXNd) );

   // Use faster clock for AU50
   defparam au50.StepREF = 1000.0/322.4;

   tb_au50 # (.BondingEnable(1), .BondingCh(4)) au50
     ( .QSFP_TXP(AU50_TXP0),
       .QSFP_TXN(AU50_TXN0),
       .QSFP_RXP(LINK_UP ? KC705_TXPd : 4'b0),
       .QSFP_RXN(LINK_UP ? KC705_TXNd : 4'b0)
       );
   
   tb_kc705_aurora kc705
     ( .SFP_TXP(KC705_TXP), 
       .SFP_TXN(KC705_TXN),
       .SFP_RXP(LINK_UP ? AU50_TXP0 : 4'b0), 
       .SFP_RXN(LINK_UP ? AU50_TXN0 : 4'b0) );
       
   initial begin
      `include "wave-record.vh"
      LINK_UP <= 1;

      #(80*1000)  LINK_UP <= 0;
      #(   1000)  LINK_UP <= 1;
      #(80*1000)  $finish;
   end

endmodule

`default_nettype wire
