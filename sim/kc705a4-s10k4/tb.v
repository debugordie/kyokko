`timescale 1ns/100fs
`default_nettype none

module tb();
   wire [3:0] KC705_TXP, KC705_TXN, S10_TXP;
   reg  LINK_UP;

   tb_s10 # (.BondingEnable(1), .BondingCh(4)) s10
     ( .QSFP_TXP(S10_TXP),
       .QSFP_RXP(LINK_UP ? KC705_TXP : 4'b0) );
   
   tb_kc705_aurora kc705
     ( .SFP_TXP(KC705_TXP), 
       .SFP_TXN(KC705_TXN),
       .SFP_RXP(LINK_UP ?  S10_TXP : 4'b0), 
       .SFP_RXN(LINK_UP ? ~S10_TXP : 4'b0) );
       
   initial begin
      `include "wave-record.vh"
      LINK_UP <= 1;

      #(600*1000)  LINK_UP <= 0;
      #(    1000)  LINK_UP <= 1;
      #(80*1000)  $finish;
   end

endmodule

`default_nettype wire
