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
//    gt_rst: reset control for most FPGAs' gigabit transceivers
// ----------------------------------------------------------------------

`default_nettype none

module gt_rst
  ( input wire CLK, RST,
    output wire GT_RST );

   reg                GT_RSTr = 1;
   reg [7:0]          GT_RST_CNT = 0;
   always @ (posedge CLK) begin
      if (RST) GT_RST_CNT <= 0;
      else GT_RST_CNT <= GT_RST_CNT + ((~&GT_RST_CNT) ? 1 : 0);

      GT_RSTr <= (GT_RST_CNT==0) ? 1 : (GT_RST_CNT==200) ? 0 : GT_RSTr;
   end

   assign GT_RST = GT_RSTr;

endmodule // gt_rst

`default_nettype wire
