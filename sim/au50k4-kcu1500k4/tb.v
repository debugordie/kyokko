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
   wire [3:0] KCU1500_TXP0, KCU1500_TXN0, KCU1500_TXP0d, KCU1500_TXN0d,
              KCU1500_TXP1, KCU1500_TXN1,
              AU50_TXP, AU50_TXN;
   reg [3:0] LINK_UP;


   wdelay dly15_0p ( .I(KCU1500_TXP0), .O(KCU1500_TXP0d) );
   wdelay dly15_0n ( .I(KCU1500_TXN0), .O(KCU1500_TXN0d) );

   // Use faster clock for AU50
   defparam au50.StepREF = 1000.0/322.4;
   
   tb_au50 # (.BondingEnable(1), .BondingCh(4)) au50
     ( .QSFP_TXP(AU50_TXP),
       .QSFP_TXN(AU50_TXN),
       .QSFP_RXP(LINK_UP & KCU1500_TXP0d),
       .QSFP_RXN(LINK_UP & KCU1500_TXN0d)
       );

   reg [1:0] KCU1500_GO;
   assign kcu1500.uut.GO = KCU1500_GO;
   
   tb_kcu1500  # (.BondingEnable(1), .BondingCh(4)) kcu1500
     ( .QSFP0_TXP(KCU1500_TXP0),
       .QSFP0_TXN(KCU1500_TXN0),
       .QSFP0_RXP(LINK_UP ? AU50_TXP : 0),
       .QSFP0_RXN(LINK_UP ? AU50_TXN : 0),
       .QSFP1_TXP(KCU1500_TXP1),
       .QSFP1_TXN(KCU1500_TXN1),
       .QSFP1_RXP(4'b0),
       .QSFP1_RXN(4'b0)
       );
   
   initial begin
      `include "wave-record.vh"
      LINK_UP <= 4'h0;
      KCU1500_GO <= 2'b11;
      
      #(  5*1000) LINK_UP <= 4'b0001;
      #(    2000) LINK_UP <= 4'b0011;
      #(    2000) LINK_UP <= 4'b0111;
      #(    2000) LINK_UP <= 4'b1111;

      #( 80*1000) KCU1500_GO <= 0;
      #(  2*1000) KCU1500_GO <= 2'b11;

      #( 40*1000) KCU1500_GO <= 0;
      #(  2*1000) KCU1500_GO <= 2'b11;

      #( 80*1000) KCU1500_GO <= 0;
      #(  2*1000) KCU1500_GO <= 2'b11;
      
      #( 40*1000)  LINK_UP <= 0;
//      #(80*1000)  LINK_UP <= 0;
      #(    1000) LINK_UP <= 4'b0001;
      #(    2000) LINK_UP <= 4'b0011;
      #(    2000) LINK_UP <= 4'b0111;
      #(    2000) LINK_UP <= 4'b1111;

      #(80*1000)  $finish;
   end

endmodule

`default_nettype wire
