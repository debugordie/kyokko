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
//    s10: Top-level module for Stratix 10 board with 1 QSFP port
// ----------------------------------------------------------------------

`default_nettype none

module s10 # 
  ( parameter NumCh = 4,
    BondingEnable = 0,  // Set to 1 to enable
    BondingCh = 4 )
   ( input wire        PCIE_RESET_N,
    input wire              CLK250, // 250MHz
    input wire              CLK644P,
    input wire [NumCh-1:0]  QSFP_RXP,
    output wire [NumCh-1:0] QSFP_TXP
     );

   parameter NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);
   parameter BusW = (BondingEnable==0) ? 64 : 64*BondingCh;
   
   // ------------------------------------------------------------
   // Configuration-to-reset or PCIe reset
   
   reg [9:0]                 RST_CNT = 0;
   wire                      RST_FULL = &RST_CNT;
   reg                       RST;

   always @ (posedge CLK250) begin
      if (~PCIE_RESET_N) begin
         RST_CNT <= 0;
      end else begin
         if (~RST_FULL) RST_CNT <= RST_CNT + 1;
         else RST_CNT <= RST_CNT;
      end
      
      RST <= ~&RST_FULL;
   end

   // ------------------------------------------------------------
   // Kyokko signals

   wire [NumChB-1:0]   CH_UP, AURORA_CLK;
   
   // Data channel
   wire [NumChB-1:0] [BusW-1:0] S_AXI_TX_TDATA, M_AXI_RX_TDATA;
   wire [NumChB-1:0]            S_AXI_TX_TLAST, S_AXI_TX_TVALID, 
                                S_AXI_TX_TREADY,
                                M_AXI_RX_TLAST, M_AXI_RX_TVALID;
   
   // UFC channel
   wire [NumChB-1:0]            UFC_TX_REQ;
   wire [NumChB-1:0] [7:0]      UFC_TX_MS;
   
   wire [NumChB-1:0] [BusW-1:0] S_AXI_UFC_TX_TDATA, M_AXI_UFC_RX_TDATA;
   wire [NumChB-1:0]            S_AXI_UFC_TX_TVALID, S_AXI_UFC_TX_TREADY,
                                M_AXI_UFC_RX_TLAST,  M_AXI_UFC_RX_TVALID;
   
   // NFC channel
   wire [NumChB-1:0] [15:0]     S_AXI_NFC_TDATA;
   wire [NumChB-1:0]            S_AXI_NFC_TVALID, S_AXI_NFC_TREADY;

   // ------------------------------------------------------------
   // Signal bundles

   wire [NumCh*64-1:0]      TX_DATA, RX_DATA, UFC_TX_DATA, UFC_RX_DATA;
   wire [NumChB*16-1:0]      NFC_TX_DATA;
   wire [NumChB* 8-1:0]      UFC_MS;

   assign TX_DATA     = S_AXI_TX_TDATA     [NumChB-1:0];
   assign UFC_TX_DATA = S_AXI_UFC_TX_TDATA [NumChB-1:0];
   assign NFC_TX_DATA = S_AXI_NFC_TDATA    [NumChB-1:0];
   assign UFC_MS      = UFC_TX_MS          [NumChB-1:0];
   
   assign M_AXI_RX_TDATA     [NumChB-1:0] = RX_DATA;
   assign M_AXI_UFC_RX_TDATA [NumChB-1:0] = UFC_RX_DATA;
   
   // ------------------------------------------------------------
   // Kyokko instance

   s10_kyokko #(.BondingEnable(BondingEnable), .BondingCh(BondingCh) ) ky
     ( .CLK250(CLK250), .RST(RST),
       .CLK644P(CLK644P),

       .SFP_TXP(QSFP_TXP),
       .SFP_RXP(QSFP_RXP),

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

   // No LED

   // ------------------------------------------------------------
   // Test stuff

   wire [NumChB-1:0]         GO;

   // Frame generators
   genvar                    ch;
   generate
      if (BondingEnable==0) begin : nobond_tp_gen
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
         end // block: txgen_gen
      end else begin : bond_tp_gen // block: nobond_tp_gen
         for (ch=0; ch<NumChB; ch=ch+1) begin : txgen_gen
            tx_frame_gen4 txg4
                 ( .CLK   (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                   .DATA  (S_AXI_TX_TDATA [ch]),
                   .LAST  (S_AXI_TX_TLAST [ch]), 
                   .VALID (S_AXI_TX_TVALID[ch]),
                   .READY (S_AXI_TX_TREADY[ch]) );

            tx_ufc_gen4 ufcg4
              ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                .REQ  (UFC_TX_REQ [ch]),
                .MS   (UFC_TX_MS  [ch]),
                .DATA (S_AXI_UFC_TX_TDATA [ch]),
                .VALID(S_AXI_UFC_TX_TVALID[ch]),
                .READY(S_AXI_UFC_TX_TREADY[ch]) );

	    // still no NFC
            tx_nfc_gen nfcgen
              ( .CLK  (AURORA_CLK[ch]), .RST(~CH_UP[ch] | ~GO[ch]),
                .DATA (S_AXI_NFC_TDATA [ch]), 
                .READY(S_AXI_NFC_TREADY[ch]), 
                .VALID(S_AXI_NFC_TVALID[ch]) );
         end // block: txgen_gen
      end // block: bond_tp_gen
   endgenerate
   
`ifndef NO_JTAG
   vio vio_inst
     ( .probe (CH_UP),
       .source(GO) );
   generate
      if (BondingEnable==0) begin : nobond_ila_gen
         for (ch=0; ch<NumCh; ch=ch+1) begin : ila_gen
            ila ila_inst
                 ( .acq_clk(AURORA_CLK[ch]),
                   .acq_data_in({S_AXI_TX_TDATA [ch], S_AXI_TX_TVALID[ch],
                                 S_AXI_TX_TREADY[ch], S_AXI_TX_TLAST [ch],
                                 M_AXI_RX_TDATA [ch], 
                                 M_AXI_RX_TVALID[ch], M_AXI_RX_TLAST [ch]}),
                   .acq_trigger_in(M_AXI_RX_TVALID[ch]) );
         end
      end // ila_gen
   endgenerate
`else
   assign GO = {NumCh{1'b1}};
`endif

endmodule // s10

`default_nettype wire
