`timescale 1ns/100ps
`default_nettype none

module tb_de10_agilex #
  (BondingEnable=0, // Set to 1 to enable
   BondingCh=4
   )
   (
`ifdef NO_LOOPBACK
    output wire [3:0] QSFP_TXP, QSFP_TXN,
    input wire [3:0] QSFP_RXP, QSFP_RXN
`endif
    );

   parameter real    StepREF = 1000.0/156.25;

   parameter NumCh = 8;
   parameter NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);

   reg 		     CLKREF = 1;
   always # (StepREF/2) CLKREF <= ~CLKREF;  // 156.25 MHz
   
`ifndef NO_LOOPBACK
   wire [NumCh-1:0] 	     QSFP_TXP, QSFP_TXN;
   reg 	[NumCh-1:0]	     QSFP_RXP, QSFP_RXN;

   generate
      genvar                 ch;
      for (ch=0; ch<NumCh; ch=ch+1) begin : loopback_gen
         always @ (*) QSFP_RXP[ch] <= QSFP_TXP[ch];
      end
   endgenerate
`endif
   
   reg RST;

   de10_agilex #(.BondingEnable(BondingEnable), .BondingCh(BondingCh)) uut
     (.PCIE_RESET_N(~RST),
      .CLK156  (CLKREF  ), 
      .QSFP_RXP(QSFP_RXP), .QSFP_RXN(QSFP_RXN),
      .QSFP_TXP(QSFP_TXP), .QSFP_TXN(QSFP_TXN)
      );

`ifndef NO_LOOPBACK
   initial begin
      `include "wave-record.vh"
      
      #(800*1000) $finish;
   end
`endif
   
   initial begin
      RST <= 1;
      #(100.1) RST <= 0;
   end
   
endmodule // tb_agf014

`default_nettype wire
