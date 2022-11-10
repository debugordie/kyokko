`timescale 1ns/1ps
`default_nettype none

module tb();
   wire [3:0] KC705_TXP,   KC705_TXN,   KC705_RXP,   KC705_RXN;
   wire [1:0][3:0] KCU1500_TXP, KCU1500_TXN, KCU1500_RXP, KCU1500_RXN;

   wire [3:0][3:0] DE10_TXP, DE10_TXN, DE10_RXP, DE10_RXN;
   
   
   reg  LINK_UP;

   tb_kcu1500 # (.BondingEnable(1), .BondingCh(4)) kcu1500
     ( .QSFP0_TXP(KCU1500_TXP[0]), .QSFP0_TXN(KCU1500_TXN[0]),
       .QSFP0_RXP(KCU1500_RXP[0]), .QSFP0_RXN(KCU1500_RXP[0]),
       .QSFP1_TXP(KCU1500_TXP[1]), .QSFP1_TXN(KCU1500_TXN[1]),
       .QSFP1_RXP(KCU1500_RXP[1]), .QSFP1_RXN(KCU1500_RXN[1]) );
   
   tb_kc705_aurora kc705
     ( .SFP_TXP(KC705_TXP), .SFP_TXN(KC705_TXN),
       .SFP_RXP(KC705_RXP), .SFP_RXN(KC705_RXN) );

   tb_de10pro_b # (.BondingEnable(1) ) de10pro_b
     ( .QSFP_TXP(DE10_TXP), .QSFP_RXP(DE10_RXP) );

   assign DE10_TXN = ~DE10_TXP;

   assign DE10_RXP = { DE10_TXP[3], KC705_TXP, KCU1500_TXP };
   assign { KC705_RXP, KCU1500_RXP } = LINK_UP ?  DE10_TXP[2:0] : 'b0;
   assign { KC705_RXN, KCU1500_RXN } = LINK_UP ? ~DE10_TXP[2:0] : 'b0;
   
   initial begin
      `include "wave-record.vh"
      LINK_UP <= 1;
      #(400*1000) LINK_UP <= 0;
      #(   1000)  LINK_UP <= 1;
      #(400*1000)  $finish;
   end

endmodule

`default_nettype wire
