`timescale 1ns/1ps
`default_nettype none

module tb();
   wire [3:0] KC705_TXP, KC705_TXN, KCU1500_TXP0, KCU1500_TXN0;
   reg  LINK_UP;

   

   tb_kcu1500 # (.BondingEnable(1), .BondingCh(4)) kcu1500
     ( .QSFP0_TXP(KCU1500_TXP0),
       .QSFP0_TXN(KCU1500_TXN0),
       .QSFP0_RXP(LINK_UP ? KC705_TXP : 4'b0),
       .QSFP0_RXN(LINK_UP ? KC705_TXN : 4'b0),
       .QSFP1_TXP(),
       .QSFP1_TXN(),
       .QSFP1_RXP(4'b0),
       .QSFP1_RXN(4'b0)
       );
   
   tb_kc705_aurora kc705
     ( .SFP_TXP(KC705_TXP), 
       .SFP_TXN(KC705_TXN),
       .SFP_RXP(LINK_UP ? KCU1500_TXP0 : 4'b0), 
       .SFP_RXN(LINK_UP ? KCU1500_TXN0 : 4'b0) );
       
   initial begin
      `include "wave-record.vh"
      LINK_UP <= 1;

      #(300*1000)  LINK_UP <= 0;
      #(    2000)  LINK_UP <= 1;
      #(300*1000)  $finish;
   end

endmodule

`default_nettype wire
