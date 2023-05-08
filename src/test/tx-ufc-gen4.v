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
//    tx_ufc_gen4: UFC test frame generator (256bit version)
// ----------------------------------------------------------------------

module tx_ufc_gen4
  ( input wire CLK, RST,
    input wire 	       READY,
    output wire [255:0] DATA,
    output reg 	       REQ, VALID,
    output reg [7:0]   MS );

   reg [63:0]          CNT_REQ;
   reg [31:0]          CNT_DATA;
   reg [3:0] 	       CNT_SEND;

   assign DATA = (VALID & READY) ? {32'hFC11_FC11, CNT_DATA,
                                    32'hFC22_FC22, CNT_DATA,
                                    32'hFC33_FC33, CNT_DATA, 
                                    32'hFC44_FC44, CNT_DATA } : 0;

   wire [7:0] 	       MS_TOGO_PRE, MS_TOGO;
   assign MS_TOGO_PRE = MS + 1;
   assign MS_TOGO = (MS_TOGO_PRE % 32 == 0) ? MS_TOGO_PRE : 
		    MS_TOGO_PRE + 32 - (MS_TOGO_PRE % 32);

   always @ (posedge CLK) begin
      if (RST) begin
	 CNT_REQ <= 64'h0;
	 CNT_DATA <= 32'h1234_5678_0000_0000;
	 REQ <= 0;
	 VALID <= 0;
	 CNT_SEND <= 0;
      end else begin
	 if (~&CNT_REQ[15:0]) CNT_REQ <= CNT_REQ + 1;

	 if (VALID & READY) begin
	    CNT_DATA <= CNT_DATA + 1;
	    CNT_SEND <= CNT_SEND + 1;
	 end

	 if (CNT_SEND == (MS_TOGO/32 - 1)) begin
	    VALID <= 0;
	    CNT_SEND <= 0;	    
	 end
	 
	 case (CNT_REQ[15:0])
	   'h150: MS    <= 63; // was 63
	   
/* -----\/----- EXCLUDED -----\/-----
	   'h200: REQ   <= 1;
	   'h201: REQ   <= 0;
 -----/\----- EXCLUDED -----/\----- */
	   'h316: REQ   <= 1;
	   'h317: REQ   <= 0;
	   
	   'h400: VALID <= 1;

	   'h650: MS    <= 33; // was 63
	   
	   'h700: REQ   <= 1;
	   'h701: REQ   <= 0;
	   
	   'h900: VALID <= 1;
	 endcase // case (CNT_REQ[15:0])
      end
   end

endmodule
