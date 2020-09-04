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
//    tx_nfc_gen: NFC test frame generator
// ----------------------------------------------------------------------

module tx_nfc_gen
  ( input wire CLK, RST,
    input wire        READY,
    output reg [15:0] DATA,
    output reg        VALID );

   reg [63:0]          CNT;
   
   always @ (posedge CLK) begin
      if (RST) begin
         CNT   <= 0;

	 VALID <= 0;
      end else begin
         CNT <= CNT+1;
         
	 if (VALID & READY) begin
            VALID <= 0;
	 end else begin
            
	 case (CNT)
           // 100: begin // XOFF
           10: begin
              DATA <= 'h1_00;
              VALID <= 1;
           end

         //300: begin // XON
         100: begin
              DATA <= 'h0_00;
              VALID <= 1;
           end

           500: begin // 128 clk
              DATA <= 'h0_80;
              VALID <= 1;
           end
           
	 endcase
         end
      end // else: !if(RST)
   end // always @ (posedge CLK)

endmodule
