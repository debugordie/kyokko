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
//    byte_reverse8: 64bit byte-lane reverser
// ----------------------------------------------------------------------

`default_nettype none

module byte_reverse8
  ( input wire [63:0] IN,
    output wire [63:0] OUT );

   assign OUT = { IN[ 7: 0], IN[15: 8], 
                  IN[23:16], IN[31:24],
                  IN[39:32], IN[47:40], 
                  IN[55:48], IN[63:56] };

endmodule // byte_reverse8

`default_nettype wire
