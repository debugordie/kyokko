// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> and <tmr@lut.eee.u-ryukyu.ac.jp> wrote this
//    file. As long as you retain this notice you can do whatever you
//    want with this stuff. If we meet some day, and you think this
//    stuff is worth it, you can buy me a beer in return Yasunori
//    Osana and Akinobu Tomori at University of the Ryukyus, Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster toolkit
// Kyokko project: an open Multi-vendor Aurora 64B/66B-compatible link
//
// Modules in this file:
//    tx_frame_gen: Test dataframe generator
// ----------------------------------------------------------------------

module tx_frame_gen
  ( input wire CLK, RST,
    output wire [63:0] DATA,
    output reg        LAST, VALID,
    input wire         READY );

   reg [63:0]          CNT;

   assign DATA = VALID ? CNT : 0;

   always @ (posedge CLK) begin
      if (RST) begin
         CNT <= 64'h1234_5678_9abc_0000;
         VALID <= 0;
         LAST <= 0;
      end else begin
         if (READY & ~&CNT) CNT <= CNT+1;

         case (CNT[15:0])
           'h0ff: begin VALID <= 1; LAST <= 1; end // 100
           'h100: begin VALID <= 0; LAST <= 0; end

           'h1ff: begin VALID <= 1; end  // 200 - 310
           'h30f: begin LAST  <= 1; end
           'h310: begin VALID <= 0; LAST <= 0; end

           'h3ff: begin VALID <= 1; end // 400 - 4ff +
           'h4ff: begin VALID <= 0; end
           'h5ff: begin VALID <= 1; end // 600 - 7ff
           'h7fe: begin LAST  <= 1; end
           'h7ff: begin VALID <= 0; LAST <= 0; end

         endcase
      end
   end

endmodule // tx_frame_gen

