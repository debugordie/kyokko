// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana at University of the Ryukyus,
//    Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster toolkit
// Kyokko project: an open Multi-vendor Aurora 64B/66B-compatible link
//
// Modules in this file:
//    teng_sc:   64b66b scrambler for 10GbE and Aurora (1+x^19+x^58)
//    teng_desc: and its descrambler
// ----------------------------------------------------------------------


`default_nettype none

module teng_sc
  ( input wire CLK, RST,
    input wire [65:128]  D,
    output wire [ 0:63] S );

   wire [1:128]          Sc; // S combinational
   reg [0:63]           Sr = 0; // S register

   assign Sc[ 1: 64] = S[ 0:63];
   assign Sc[65:128] = D[65:128] ^ Sc[26:89] ^ Sc[7:70];
   
   always @ (posedge CLK) begin
      if (RST) Sr <= 0;
      else     Sr <= Sc[65:128];
   end
   
   assign S = Sr;

endmodule // teng_sc
   
module teng_desc
  ( input wire CLK, RST,
    input wire [65:128]  S,
    output reg [0:63] D );

   // S[16:31] = scrambled input
   // S[ 1:15] = previous scrambled input = Sr[1:15]

   reg [1:64]           Sr;
   wire [1:128]         Sc;

   always @ (posedge CLK)
     if (RST) Sr <= 0;
     else     Sr[1:64] <= S[65:128];
   
   assign Sc[ 1: 64] = Sr[1:64];
   assign Sc[65:128] = S[65:128];
   
   always @ (posedge CLK)
     D[0:63] <= Sc[26:89] ^ Sc[7:70] ^ Sc[65:128];

endmodule // teng_desc
  
`default_nettype wire
