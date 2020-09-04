`timescale 1ns/1ps
`default_nettype none

module tb();
   wire KC705_TXP, KC705_TXN, KU040_TXP, KU040_TXN;
   wire [2:0] C10GX_TXP, C10GX_RXP;
   reg  LINK_UP;

   tb_kc705_aurora kc705
     ( .SFP_TXP(KC705_TXP), 
       .SFP_TXN(KC705_TXN),
       .SFP_RXP(LINK_UP ?  C10GX_TXP[0] : 0), 
       .SFP_RXN(LINK_UP ? ~C10GX_TXP[0] : 0) );

   tb_ku040_kyokko_single ku040
     ( .SFP_TXP(KU040_TXP), 
       .SFP_TXN(KU040_TXN),
       .SFP_RXP(LINK_UP ?  C10GX_TXP[1] : 0), 
       .SFP_RXN(LINK_UP ? ~C10GX_TXP[1] : 0) );

   tb_c10gx c10gx
     ( .SFP_TXP(C10GX_TXP),
       .SFP_RXP(LINK_UP ? {KU040_TXP, KC705_TXP} : 0) );
       
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
