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
//    rxpath_rst: Transceiver Rx path reset control while link initialization
// ----------------------------------------------------------------------

`default_nettype none

module rxpath_rst
  ( input wire CLK, RST,
    input wire  RXSLIP_LIMIT,
    output wire RXPATH_RST
    );

   reg RXSLIP_LIMITs, RXSLIP_LIMITi; // synchronizer
   reg RXSLIP_LIMITr; // posedge detector
   reg [3:0] RXPATH_RST_CNT = 0;

   assign      RXPATH_RST = (RXPATH_RST_CNT != 0);
   
   always @ (posedge CLK) begin
      if (RST) begin
         RXSLIP_LIMITi <= 0;
         RXSLIP_LIMITs <= 0;
         RXPATH_RST_CNT <= 0;
      end else begin
         RXSLIP_LIMITi <= RXSLIP_LIMIT; 
         RXSLIP_LIMITs <= RXSLIP_LIMITi;
         RXSLIP_LIMITr <= RXSLIP_LIMITs;

         RXPATH_RST_CNT <= (~RXSLIP_LIMITr & RXSLIP_LIMITs) ? 1 :
                           (RXPATH_RST_CNT==0) ? 0 :
                           RXPATH_RST_CNT + 1;
      end
   end

   
endmodule

`default_nettype wire

