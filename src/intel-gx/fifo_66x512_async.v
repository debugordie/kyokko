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
//    fifo_66x512_async: Xilinx compatible async FIFO, 66-bit x 512 words
// ----------------------------------------------------------------------

`default_nettype none

module fifo_66x512_async
  ( input wire         rst,
    input wire         wr_clk, rd_clk,
    input wire         rd_en, wr_en,
    output wire [65:0] dout,
    input wire [65:0]  din,
    output wire        empty,
    output wire        full,
    output wire        prog_full,
    output wire        valid
   );


   dcfifo #
     ( .lpm_width(66),
       .lpm_widthu(9),
       .lpm_numwords(512),
       .delay_rdusedw(1),
       .delay_wrusedw(1),
       .rdsync_delaypipe(0),
       .wrsync_delaypipe(0),
       .lpm_showahead("OFF"),
       .underflow_checking("ON"),
       .overflow_checking("ON"),
       .read_aclr_synch("OFF"),
       .write_aclr_synch("OFF"),
       .use_eab("ON"),
       .add_ram_output_register("OFF") )
   fifo
     ( .data   (din), 
       .rdclk  (rd_clk), 
       .wrclk  (wr_clk), 
       .aclr   (rst), 
       .rdreq  (rd_en), 
       .wrreq  (wr_en),
       .rdfull (), 
       .wrfull (full), 
       .rdempty(empty), 
       .wrempty(), 
       .rdusedw(), 
       .wrusedw(), 
       .q      (dout)
       );

   reg                 VALIDi;
   always @ (posedge rd_clk) VALIDi <= ~empty & rd_en;
   assign valid = VALIDi;

endmodule // fifo_64x512_afull

`default_nettype wire
