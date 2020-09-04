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
//    kyokko_tx_data: Data channel transimission in Kyokko Tx subsystem
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_tx_data
  ( input wire CLK, 

    input wire         S_AXIS_TVALID, S_AXIS_TLAST,
    output wire        S_AXIS_TREADY,
    input wire [63:0]  S_AXIS_TDATA,

    input wire         LINK_UP, HOLD, CC,
    output wire        ACTIVE,
    output wire [63:0] DATA
   );

   assign ACTIVE = (S_AXIS_TREADY & S_AXIS_TVALID);

   // Separator reservation FSM
   reg         TX_SEP_RESV;
   always @ (posedge CLK) begin
      if (~LINK_UP) begin
         TX_SEP_RESV <= 0;
      end else begin
         TX_SEP_RESV <= (S_AXIS_TREADY & S_AXIS_TLAST) ? 1 :
                        (~CC & ~HOLD)                  ? 0 : TX_SEP_RESV;
      end
   end

   wire SEND_SEP = TX_SEP_RESV & ~CC;

   assign S_AXIS_TREADY = ( LINK_UP &  // Link is up
                            ~CC     &  // Not sending CC
                            ~HOLD  );  // Not sending UFC/NFC

   // Tx data
   wire [63:0]     S_AXIS_TDATA_REV;
   byte_reverse8 rev_data ( .IN(S_AXIS_TDATA), .OUT(S_AXIS_TDATA_REV) );

   assign DATA =  ( SEND_SEP ? {16'h1e00, 48'h0} : // Sep
	            ACTIVE   ? S_AXIS_TDATA_REV :
	            {16'h7810, 48'h0} ); // Idle
   
   
endmodule // kyokko_tx_data

`default_nettype wire
