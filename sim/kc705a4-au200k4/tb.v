`timescale 1ns/1ps
`default_nettype none

module tb();
   wire [3:0] KC705_TXP, KC705_TXN,
              AU200_TXP0, AU200_TXN0, AU200_TXP1, AU200_TXN1;
   reg  LINK_UP;

   tb_au200 # (.BondingEnable(1), .BondingCh(4)) au200
     ( .QSFP0_TXP(AU200_TXP0),
       .QSFP0_TXN(AU200_TXN0),
       .QSFP0_RXP(LINK_UP ? KC705_TXP : 4'b0),
       .QSFP0_RXN(LINK_UP ? KC705_TXN : 4'b0),
       .QSFP1_TXP(AU200_TXP1),
       .QSFP1_TXN(AU200_TXN1),
       .QSFP1_RXP(AU200_TXP1),
       .QSFP1_RXN(AU200_TXN1) );
   
   tb_kc705_aurora kc705
     ( .SFP_TXP(KC705_TXP), 
       .SFP_TXN(KC705_TXN),
       .SFP_RXP(LINK_UP ? AU200_TXP0 : 4'b0), 
       .SFP_RXN(LINK_UP ? AU200_TXN0 : 4'b0) );
       
   initial begin
      `include "wave-record.vh"
      LINK_UP <= 1;

      #(80*1000)  LINK_UP <= 0;
      #(   1000)  LINK_UP <= 1;
      #(80*1000)  $finish;
   end

endmodule

`default_nettype wire
