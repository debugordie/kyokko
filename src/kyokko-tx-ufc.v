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
//    kyokko_tx_nfc: UFC transmission control in Kyokko Tx subsystem
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_tx_ufc # (parameter BondingEnable = 0, BondingCh = 1, ChNo = 0)
  ( input wire CLK,

    input wire         UFC_REQ,
    input wire [7:0]   UFC_MS,

    input wire         S_AXIS_UFC_TVALID,
    output wire        S_AXIS_UFC_TREADY,
    input wire [63:0]  S_AXIS_UFC_TDATA,

    input wire         LINK_UP, HOLD, CC,
    output wire        ACTIVE, MSG_VALID,
    output wire [63:0] DATA
    );

   localparam NoUFCHeader = (BondingEnable==1) & (ChNo != BondingCh-1);
   
   reg [7:0]           MS_R;
   reg [2:0]           STAT;
   
   assign ACTIVE = ~STAT[0];
   
   assign S_AXIS_UFC_TREADY = ( STAT[2] &  // UFC is ready
                                ~HOLD &    // Not sending/in NFC
                                ~CC  );    // Not sending CC

   // If have valid UFC message block
   assign MSG_VALID = (S_AXIS_UFC_TREADY & S_AXIS_UFC_TVALID);

   always @ (posedge CLK) begin
      if (~LINK_UP) begin
	 STAT <= 'b001;
	 MS_R <= 0;
      end else begin
	 case (STAT)
	   'b001: begin // idle
	      if (UFC_REQ) begin
		 MS_R <= UFC_MS + 1;
		 STAT <= 'b010;
	      end
	   end
	   
	   'b010: begin // send req
              if (~CC) STAT <= 'b100;
	   end

	   'b100: begin
              if (~CC) begin
                 if (MS_R == 8) 
		   STAT <= 'b001;
                 else
                   MS_R <= (MSG_VALID) ? MS_R - 8 : MS_R;
              end
	   end
	 endcase // case (STAT)
      end
   end // always @ (posedge CLK)


   wire [63:0]     S_AXIS_UFC_TDATA_REV;
   byte_reverse8 rev_ufc ( .IN(S_AXIS_UFC_TDATA), .OUT(S_AXIS_UFC_TDATA_REV) );

   wire [63:0] UFC_HEADER =( NoUFCHeader ? {16'h7810, 48'h0} : // Idle
                             {8'h2D, UFC_MS, 48'h0} ); // UFC header
   
   assign DATA = ( STAT[1] ? UFC_HEADER :             // UFC header or Idle
                   MSG_VALID ? S_AXIS_UFC_TDATA_REV : // UFC message
		   {16'h7810, 48'h0} ); // Idle

   
endmodule // kyokko_tx_ufc


`default_nettype wire
