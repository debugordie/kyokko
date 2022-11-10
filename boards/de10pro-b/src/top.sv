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
//    de10pro_b: Top-level module for DE10Pro Rev.B board with 4x QSFP
// ----------------------------------------------------------------------

`default_nettype none

module de10pro_b #
  ( parameter NumCh = 16,
    BondingEnable = 0, // Set to 1 to enable
    BondingCh = 4 )
   ( input wire             PCIE_PERST_N, // PCIe reset
     input wire             CLK100,

     output wire [1:0]      SI5340_RST_N, SI5340_OE_N,
     output wire [3:0]      LED_N,

     input wire [3:0]       QSFP_REFCLKP,
     output wire [3:0][3:0] QSFP_TXP,
     input wire [3:0][3:0]  QSFP_RXP );

   parameter NumChB = ((BondingEnable==0) ? NumCh : NumCh/BondingCh);
   parameter ChW = (BondingEnable==0) ? 4 : 1;
   parameter BusW = (BondingEnable==0) ? 64 : 64*BondingCh;

   // ------------------------------------------------------------
   // LED polarity and clock generator enable

   wire [3:0] LED;
   assign LED_N = ~LED;

   assign SI5340_RST_N = 2'b11;
   assign SI5340_OE_N  = 2'b00;

   // ------------------------------------------------------------
   // Configuration-to-reset or PCIe reset

   wire       RST_REL_N;
   rst_rel rrel ( .ninit_done (RST_REL_N) );

   reg [9:0]                 RST_CNT = 0;
   wire                      RST_FULL = &RST_CNT;
   reg                       RST;

   always @ (posedge CLK100) begin
      if (~PCIE_PERST_N | RST_REL_N) begin
         RST_CNT <= 0;
      end else begin
         if (~RST_FULL) RST_CNT <= RST_CNT + 1;
         else RST_CNT <= RST_CNT;
      end

      RST <= ~&RST_FULL;
   end   

   // ------------------------------------------------------------
   // Kyokko signals

   wire [3:0][ChW-1:0]   CH_UP, AURORA_CLK;
   
   // Data channel
   wire [3:0][ChW-1:0][BusW-1:0] S_AXI_TX_TDATA, M_AXI_RX_TDATA;
   wire [3:0][ChW-1:0]           S_AXI_TX_TLAST, S_AXI_TX_TVALID,
                                    S_AXI_TX_TREADY,
                                    M_AXI_RX_TLAST, M_AXI_RX_TVALID;

   // UFC channel
   wire [3:0][ChW-1:0]           UFC_TX_REQ;
   wire [3:0][ChW-1:0][7:0]      UFC_TX_MS;
   
   wire [3:0][ChW-1:0][BusW-1:0] S_AXI_UFC_TX_TDATA, M_AXI_UFC_RX_TDATA;
   wire [3:0][ChW-1:0]           S_AXI_UFC_TX_TVALID, S_AXI_UFC_TX_TREADY,
                                    M_AXI_UFC_RX_TLAST,  M_AXI_UFC_RX_TVALID;

   // NFC channel
   wire [3:0][ChW-1:0][15:0]     S_AXI_NFC_TDATA;
   wire [3:0][ChW-1:0]           S_AXI_NFC_TVALID, S_AXI_NFC_TREADY;


   // ------------------------------------------------------------
   // Kyokko instance

   genvar                           ch;
   generate
      for (ch=0; ch<4; ch=ch+1) begin : qsfp_gen
   
         s10_kyokko #(.BondingEnable(BondingEnable), .BondingCh(BondingCh) ) ky
              ( .CLK250(CLK100), .RST(RST),
                .CLK644P(QSFP_REFCLKP[ch]),
                
                .SFP_TXP(QSFP_TXP [ch]),
                .SFP_RXP(QSFP_RXP [ch]),
                
                .CH_UP   (CH_UP      [ch]),
                .USER_CLK(AURORA_CLK [ch]),
                
                // Data channel
                .S_AXI_TX_TDATA     (S_AXI_TX_TDATA [ch]),   // I [64*NumCh]
                .S_AXI_TX_TLAST     (S_AXI_TX_TLAST [ch]),   // I [NumCh]
                .S_AXI_TX_TVALID    (S_AXI_TX_TVALID[ch]),   // I [NumCh]
                .S_AXI_TX_TREADY    (S_AXI_TX_TREADY[ch]),   // O [NumCh]

                .M_AXI_RX_TDATA     (M_AXI_RX_TDATA [ch]),   // O [64*NumCh]
                .M_AXI_RX_TLAST     (M_AXI_RX_TLAST [ch]),   // O [NumCh]
                .M_AXI_RX_TVALID    (M_AXI_RX_TVALID[ch]),   // O [NumCh]

                // UFC channel
                .UFC_TX_REQ         (UFC_TX_REQ     [ch]),   // I [NumCh]
                .UFC_TX_MS          (UFC_TX_MS      [ch]),   // O [8*NumCh]

                .S_AXI_UFC_TX_TDATA (S_AXI_UFC_TX_TDATA [ch]), // I [64*NumCh]
                .S_AXI_UFC_TX_TVALID(S_AXI_UFC_TX_TVALID[ch]), // I [NumCh]
                .S_AXI_UFC_TX_TREADY(S_AXI_UFC_TX_TREADY[ch]), // O [NumCh]

                .M_AXI_UFC_RX_TDATA (M_AXI_UFC_RX_TDATA [ch]), // O [64*NumCh]
                .M_AXI_UFC_RX_TLAST (M_AXI_UFC_RX_TLAST [ch]), // O [NumCh]
                .M_AXI_UFC_RX_TVALID(M_AXI_UFC_RX_TVALID[ch]), // O [NumCh]

                // NFC channel
                .S_AXI_NFC_TDATA    (S_AXI_NFC_TDATA [ch]),    // I [16*NumCh]
                .S_AXI_NFC_TVALID   (S_AXI_NFC_TVALID[ch]),    // I [NumCh]
                .S_AXI_NFC_TREADY   (S_AXI_NFC_TREADY[ch])     // O [NumCh]
                );
      end // block: qsfp_gen
   endgenerate
   

   assign LED = { |CH_UP[3], |CH_UP[2], |CH_UP[1], |CH_UP[0] };

   
   // ------------------------------------------------------------
   // Test stuff

   wire [NumChB-1:0] GO;

   // Frame generators
   generate
      if (BondingEnable==0) begin : nobond_tp_gen
         for (ch=0; ch<NumCh; ch=ch+1) begin : txgen_gen
            tx_frame_gen txg
                 ( .CLK   (AURORA_CLK[ch/4][ch%4]),
                   .RST   (~CH_UP    [ch/4][ch%4] | ~GO[ch/4]),
                   .DATA  (S_AXI_TX_TDATA [ch/4][ch%4]),
                   .LAST  (S_AXI_TX_TLAST [ch/4][ch%4]),
                   .VALID (S_AXI_TX_TVALID[ch/4][ch%4]),
                   .READY (S_AXI_TX_TREADY[ch/4][ch%4]) );

            tx_ufc_gen ufcg
              ( .CLK  (AURORA_CLK [ch/4][ch%4]), 
                .RST  (~&CH_UP    [ch/4][ch%4] | ~GO[ch]),
                .REQ  (UFC_TX_REQ [ch/4][ch%4]),
                .MS   (UFC_TX_MS  [ch/4][ch%4]),
                .DATA (S_AXI_UFC_TX_TDATA [ch/4][ch%4]),
                .VALID(S_AXI_UFC_TX_TVALID[ch/4][ch%4]),
                .READY(S_AXI_UFC_TX_TREADY[ch/4][ch%4]) );

            tx_nfc_gen nfcgen
              ( .CLK  (AURORA_CLK[ch/4][ch%4] ),
                .RST  (~&CH_UP   [ch/4][ch%4] | ~GO[ch]),
                .DATA (S_AXI_NFC_TDATA [ch/4][ch%4]),
                .READY(S_AXI_NFC_TREADY[ch/4][ch%4]),
                .VALID(S_AXI_NFC_TVALID[ch/4][ch%4]) );
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
      for (ch=0; ch<NumChB; ch=ch+1) begin : ila_gen
         if (BondingEnable==0) begin : nobond_ila_gen
            ila ila_data
              ( .acq_clk(AURORA_CLK[ch/4][ch%4]),
                .acq_data_in({S_AXI_TX_TDATA [ch/4][ch%4],
                              S_AXI_TX_TVALID[ch/4][ch%4],
                              S_AXI_TX_TREADY[ch/4][ch%4],
                              S_AXI_TX_TLAST [ch/4][ch%4],
                              M_AXI_RX_TDATA [ch/4][ch%4],
                              M_AXI_RX_TVALID[ch/4][ch%4],
                              M_AXI_RX_TLAST [ch/4][ch%4]}),
                .acq_trigger_in(M_AXI_RX_TVALID[ch/4][ch%4]) );
         end else begin : bond_ila_gen
            ila ila_data
              ( .acq_clk(AURORA_CLK[ch]),
                .acq_data_in({S_AXI_TX_TDATA [ch], S_AXI_TX_TVALID[ch],
                              S_AXI_TX_TREADY[ch], S_AXI_TX_TLAST [ch],
                              M_AXI_RX_TDATA [ch],
                              M_AXI_RX_TVALID[ch], M_AXI_RX_TLAST [ch]}),
                .acq_trigger_in(M_AXI_RX_TVALID[ch]) );

            ila ila_ufc
              ( .acq_clk(AURORA_CLK[ch]),
                .acq_data_in({S_AXI_UFC_TX_TDATA [ch], S_AXI_UFC_TX_TVALID[ch],
                              S_AXI_UFC_TX_TREADY[ch],
                              M_AXI_UFC_RX_TDATA [ch],
                              M_AXI_UFC_RX_TVALID[ch], 
                              M_AXI_UFC_RX_TLAST [ch]}),
                .acq_trigger_in(M_AXI_UFC_RX_TVALID[ch]));
         end // block: bond_ila_gen
      end // ila_gen

   endgenerate
   
`else
   assign GO = {NumCh{1'b1}};
`endif
   
endmodule // de10pro_b

`default_nettype wire
 
