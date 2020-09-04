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
//    kyokko_tx_nfc: NFC transmission control in Kyokko Tx subsystem
// ----------------------------------------------------------------------

`default_nettype  none

module kyokko_tx_nfc
  ( input wire CLK,
    input wire         S_AXIS_NFC_TVALID,
    output wire        S_AXIS_NFC_TREADY,
    input wire [15:0]  S_AXIS_NFC_TDATA,
    
    input wire         LINK_UP, CC,
    output wire        ACTIVE,
    output wire [63:0] DATA );

   reg [2:0]           STAT; // idle -> capture -> pending/xmit
   assign S_AXIS_NFC_TREADY = STAT[1];

   reg [15:0]          NFC_R;
   assign DATA = {8'haa, NFC_R[7:0], NFC_R[8], 7'h0, 40'h0};
   assign ACTIVE = STAT[2] & ~CC;
   
   always @ (posedge CLK) begin
      if (~LINK_UP) begin
         STAT <= 'b001;
      end else begin
         case (STAT)
           'b001: begin // Idle: READY is low
              if (S_AXIS_NFC_TVALID) STAT <= 'b010; 
           end

           'b010: begin // Capture: READY is high
              if (S_AXIS_NFC_TVALID) begin
                 STAT  <= 'b100; 
                 NFC_R <= S_AXIS_NFC_TDATA;
              end
           end

           'b100: begin // Transmit when possible
              if (~CC) STAT <= 'b001;
           end
           
           default:
             STAT <= 'b001; // just for failsafe
         endcase // case (STAT)
      end

   end

endmodule // kyokko_tx_nfc
    
`default_nettype wire
