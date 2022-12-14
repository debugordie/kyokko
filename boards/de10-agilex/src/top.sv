
`default_nettype none

module de10_agilex #
  ( parameter BondingEnable = 0, // Set to 1 to enable
    BondingCh = 4 )
   ( input wire PCIE_RESET_N,
     input wire             CLK100,
     input wire [1:0]       QSFPDD_REFCLK, // 156 MHz
     input wire [1:0][7:0]  QSFPDD_RXP, QSFPDD_RXN,
     output wire [1:0][7:0] QSFPDD_TXP, QSFPDD_TXN
     );

   localparam               NumCh=16; // Dual QSFP-DD
   localparam NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);
   localparam BusW = (BondingEnable==0) ? 64 : 64*BondingCh;

   localparam NumChC = NumChB/2; // Channels per QSFP-DD Connector
   
   // ------------------------------------------------------------
   // Configuration-to-reset or PCIe reset
   
   reg [9:0]                 RST_CNT = 0;
   wire                      RST_FULL = &RST_CNT;
   reg                       RST;

   always @ (posedge CLK100) begin
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
   // Kyokko instance

   genvar                       c;
   generate
      for (c=0; c<2; c++) begin : ddcage_gen
   
   de10_agilex_kyokko 
             #(.BondingEnable(BondingEnable), .BondingCh(BondingCh) ) ky
     ( .CLK156(QSFPDD_REFCLK[c]), .RST(RST),

       .SFP_TXP(QSFPDD_TXP[c]), .SFP_TXN(QSFPDD_TXN[c]),
       .SFP_RXP(QSFPDD_RXP[c]), .SFP_RXN(QSFPDD_RXN[c]),

       .CH_UP   (CH_UP     [c*NumChC +: NumChC]),
       .USER_CLK(AURORA_CLK[c*NumChC +: NumChC]),

       // Data channel
       .S_AXI_TX_TDATA     (S_AXI_TX_TDATA [c*NumChC +: NumChC]), // I
       .S_AXI_TX_TLAST     (S_AXI_TX_TLAST [c*NumChC +: NumChC]), // I 
       .S_AXI_TX_TVALID    (S_AXI_TX_TVALID[c*NumChC +: NumChC]), // I 
       .S_AXI_TX_TREADY    (S_AXI_TX_TREADY[c*NumChC +: NumChC]), // O 
      
       .M_AXI_RX_TDATA     (M_AXI_RX_TDATA [c*NumChC +: NumChC]), // O [63:0] 
       .M_AXI_RX_TLAST     (M_AXI_RX_TLAST [c*NumChC +: NumChC]), // O 
       .M_AXI_RX_TVALID    (M_AXI_RX_TVALID[c*NumChC +: NumChC]), // O 
      
       // UFC channel
       .UFC_TX_REQ         (UFC_TX_REQ     [c*NumChC +: NumChC]), // I
       .UFC_TX_MS          (UFC_TX_MS      [c*NumChC +: NumChC]), // O [7:0]
      
       .S_AXI_UFC_TX_TDATA (S_AXI_UFC_TX_TDATA [c*NumChC +: NumChC]),  // I [63:0]  
       .S_AXI_UFC_TX_TVALID(S_AXI_UFC_TX_TVALID[c*NumChC +: NumChC]), // I
       .S_AXI_UFC_TX_TREADY(S_AXI_UFC_TX_TREADY[c*NumChC +: NumChC]), // O
      
       .M_AXI_UFC_RX_TDATA (M_AXI_UFC_RX_TDATA [c*NumChC +: NumChC]),  // O [63:0]
       .M_AXI_UFC_RX_TLAST (M_AXI_UFC_RX_TLAST [c*NumChC +: NumChC]), // O 
       .M_AXI_UFC_RX_TVALID(M_AXI_UFC_RX_TVALID[c*NumChC +: NumChC]), // O 

       // NFC channel
       .S_AXI_NFC_TDATA    (S_AXI_NFC_TDATA [c*NumChC +: NumChC]),     // I [5:0]
       .S_AXI_NFC_TVALID   (S_AXI_NFC_TVALID[c*NumChC +: NumChC]),    // I
       .S_AXI_NFC_TREADY   (S_AXI_NFC_TREADY[c*NumChC +: NumChC])     // O
       );

      end // block: ddcage_gen
   endgenerate

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

endmodule // agf014

`default_nettype wire
