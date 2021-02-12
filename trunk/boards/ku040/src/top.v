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
//    ku040: Avnet KU040 DB top-level module, 4x Kyokko on 2xSFP + 2xSMA
// ----------------------------------------------------------------------

`default_nettype none

module ku040
  ( input wire RST,
    input wire        CLK250P, CLK250N,
    input wire        SFP_REFCLKP, SFP_REFCLKN,

    input wire [1:0]  SFP_RXP, SFP_RXN, SMA_RXP, SMA_RXN,
    output wire [1:0] SFP_TXP, SFP_TXN, SMA_TXP, SMA_TXN,
    
    output wire [7:0] LED
   );

   parameter NumCh = 4;

   wire               CLK100, DCM_LOCKED;
   clk_250_100 dcm
     ( .clk_in1_p(CLK250P), .clk_in1_n(CLK250N),
       .clk100(CLK100),
       .reset(RST), .locked(DCM_LOCKED) );

   // ------------------------------------------------------------
   // Kyokko signals

   wire [NumCh-1:0]   CH_UP, AURORA_CLK;
   
   // Data channel
   wire [63:0]        S_AXI_TX_TDATA [NumCh-1:0],
                      M_AXI_RX_TDATA [NumCh-1:0];
   wire [NumCh-1:0]   S_AXI_TX_TLAST, S_AXI_TX_TVALID, S_AXI_TX_TREADY,
                      M_AXI_RX_TLAST, M_AXI_RX_TVALID;
   
   // UFC channel
   wire [NumCh-1:0]   UFC_TX_REQ;
   wire [7:0]         UFC_TX_MS [NumCh-1:0];
    
   wire [63:0]        S_AXI_UFC_TX_TDATA [NumCh-1:0],
                      M_AXI_UFC_RX_TDATA [NumCh-1:0];
   wire [NumCh-1:0]   S_AXI_UFC_TX_TVALID, S_AXI_UFC_TX_TREADY,
                      M_AXI_UFC_RX_TLAST,  M_AXI_UFC_RX_TVALID;
    
   // NFC channel
   wire [15:0]        S_AXI_NFC_TDATA [NumCh-1:0];
   wire [NumCh-1:0]   S_AXI_NFC_TVALID, S_AXI_NFC_TREADY;

   // ------------------------------------------------------------
   // Signal bundles

   wire [NumCh*64-1:0] TX_DATA, RX_DATA, UFC_TX_DATA, UFC_RX_DATA;
   wire [NumCh*16-1:0] NFC_TX_DATA;
   wire [NumCh* 8-1:0] UFC_MS;

   genvar              ch;
   for (ch=0; ch<NumCh; ch=ch+1) begin : kyokko_bundle_gen
      assign TX_DATA     [ch*64+63:ch*64] = S_AXI_TX_TDATA     [ch];
      assign UFC_TX_DATA [ch*64+63:ch*64] = S_AXI_UFC_TX_TDATA [ch];
      assign NFC_TX_DATA [ch*16+15:ch*16] = S_AXI_NFC_TDATA    [ch];
      assign UFC_MS      [ch* 8+ 7: ch*8] = UFC_TX_MS          [ch];

      assign M_AXI_RX_TDATA     [ch] = RX_DATA     [ch*64+63:ch*64];
      assign M_AXI_UFC_RX_TDATA [ch] = UFC_RX_DATA [ch*64+63:ch*64];
   end // kyokko_bundle_gen

   // ------------------------------------------------------------
   // Kyokko instance

   ku040_kyokko ky
     ( .CLK100(CLK100), .RST(~DCM_LOCKED),
       .SFP_REFCLKP(SFP_REFCLKP), .SFP_REFCLKN(SFP_REFCLKN),

       .SFP_TXP(SFP_TXP), .SFP_TXN(SFP_TXN),
       .SFP_RXP(SFP_RXP), .SFP_RXN(SFP_RXN),
       .SMA_TXP(SMA_TXP), .SMA_TXN(SMA_TXN),
       .SMA_RXP(SMA_RXP), .SMA_RXN(SMA_RXN),

       .CH_UP   (CH_UP),
       .USER_CLK(AURORA_CLK),

       // Data channel
       .S_AXI_TX_TDATA     (TX_DATA),             // I [64*NumCh-1:0]  
       .S_AXI_TX_TLAST     (S_AXI_TX_TLAST ),     // I [NumCh-1:0]    
       .S_AXI_TX_TVALID    (S_AXI_TX_TVALID),     // I [NumCh-1:0]     
       .S_AXI_TX_TREADY    (S_AXI_TX_TREADY),     // O [NumCh-1:0]    
     
       .M_AXI_RX_TDATA     (RX_DATA),             // O [64*NumCh-1:0] 
       .M_AXI_RX_TLAST     (M_AXI_RX_TLAST ),     // O [NumCh-1:0]   
       .M_AXI_RX_TVALID    (M_AXI_RX_TVALID),     // O [NumCh-1:0]    
     
       // UFC channel
       .UFC_TX_REQ         (UFC_TX_REQ),          // I [NumCh-1:0]     
       .UFC_TX_MS          (UFC_MS),              // O [8*NumCh-1:0] 
     
       .S_AXI_UFC_TX_TDATA (UFC_TX_DATA),         // I [64*NumCh-1:0]  
       .S_AXI_UFC_TX_TVALID(S_AXI_UFC_TX_TVALID), // I [NumCh-1:0]     
       .S_AXI_UFC_TX_TREADY(S_AXI_UFC_TX_TREADY), // O [NumCh-1:0]    
     
       .M_AXI_UFC_RX_TDATA (UFC_RX_DATA),         // O [64*NumCh-1:0] 
       .M_AXI_UFC_RX_TLAST (M_AXI_UFC_RX_TLAST ), // O [NumCh-1:0]   
       .M_AXI_UFC_RX_TVALID(M_AXI_UFC_RX_TVALID), // O [NumCh-1:0]       

       // NFC channel
       .S_AXI_NFC_TDATA    (NFC_TX_DATA),         // I [16*NumCh-1:0]  
       .S_AXI_NFC_TVALID   (S_AXI_NFC_TVALID),    // I [NumCh-1:0]     
       .S_AXI_NFC_TREADY   (S_AXI_NFC_TREADY)     // O [NumCh-1:0]    
       );

   // ------------------------------------------------------------
   // Status

   assign LED = CH_UP;

   // ------------------------------------------------------------
   // Test stuff

   wire [NumCh-1:0] GO;

   // Frame generators
   for (ch=0; ch<NumCh; ch=ch+1) begin : txgen_gen
      tx_frame_gen txg
           ( .CLK   (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
             .DATA  (S_AXI_TX_TDATA [ch]),
             .LAST  (S_AXI_TX_TLAST [ch]), 
             .VALID (S_AXI_TX_TVALID[ch]),
             .READY (S_AXI_TX_TREADY[ch]) );
      
      tx_ufc_gen ufcg
        ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
          .REQ  (UFC_TX_REQ [ch]),
          .MS   (UFC_TX_MS  [ch]),
          .DATA (S_AXI_UFC_TX_TDATA [ch]),
          .VALID(S_AXI_UFC_TX_TVALID[ch]),
          .READY(S_AXI_UFC_TX_TREADY[ch]) );
      
      tx_nfc_gen nfcgen
        ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
          .DATA (S_AXI_NFC_TDATA [ch]), 
          .READY(S_AXI_NFC_TREADY[ch]), 
          .VALID(S_AXI_NFC_TVALID[ch]) );
   end // txgen_gen
   
`ifndef NO_JTAG
   vio_0 vio
      ( .clk(AURORA_CLK[0]),
        .probe_in0 (CH_UP),
        .probe_out0(GO) );

   for (ch=0; ch<NumCh; ch=ch+1) begin : ila_gen
      ila_0 ila
           ( .clk(AURORA_CLK[ch]),
             .probe0({S_AXI_TX_TDATA [ch], S_AXI_TX_TVALID[ch],
                      S_AXI_TX_TREADY[ch], S_AXI_TX_TLAST [ch],
                      M_AXI_RX_TDATA [ch], 
                      M_AXI_RX_TVALID[ch], M_AXI_RX_TLAST [ch]}) );
   end // ila_gen
`else
   assign GO = {NumCh{1'b1}};
`endif
   
endmodule // ku040

`default_nettype wire
