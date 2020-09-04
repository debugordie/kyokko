`timescale 1ns/1ps
`default_nettype none

module tb();
   wire [3:0] KCU1500_TXP0, KCU1500_TXN0, KCU1500_TXP1, KCU1500_TXN1, 
              AU50_TXP, AU50_TXN, HAWKEYE_TXP;
   reg  LINK_UP;

   tb_kcu1500 kcu1500
     ( .QSFP0_TXP(KCU1500_TXP0), 
       .QSFP0_TXN(KCU1500_TXN0),
       .QSFP0_RXP(LINK_UP ? AU50_TXP : 4'b0), 
       .QSFP0_RXN(LINK_UP ? AU50_TXN : 4'b0),
       .QSFP1_TXP(KCU1500_TXP1), 
       .QSFP1_TXN(KCU1500_TXN1),
       .QSFP1_RXP(LINK_UP ?  HAWKEYE_TXP : 4'b0), 
       .QSFP1_RXN(LINK_UP ? ~HAWKEYE_TXP : 4'b0)
       );

   tb_au50 au50
     ( .QSFP_TXP(AU50_TXP), 
       .QSFP_TXN(AU50_TXN),
       .QSFP_RXP(LINK_UP ? KCU1500_TXP0 : 4'b0), 
       .QSFP_RXN(LINK_UP ? KCU1500_TXN0 : 4'b0) );

   tb_hawkeye hawkeye
     ( .SFP_TXP(HAWKEYE_TXP),
       .SFP_RXP(LINK_UP ? KCU1500_TXP1 : 4'b0) );

   initial begin
      $shm_open();
      $shm_probe("SA");
      LINK_UP <= 1;

      #(300*1000)  LINK_UP <= 0;
      #(    1000)  LINK_UP <= 1;
      #(300*1000)  $finish;
   end

endmodule

`default_nettype wire
