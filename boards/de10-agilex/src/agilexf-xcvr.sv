`default_nettype none

module agilexf_xcvr # ( parameter NumCh=8, BondingEnable=0, BondingCh=4)
  (input wire  RST,
   input wire                    CLK156, // 156.25 MHz refclk
   input wire                    CLK100, // used with platform designer PHY
   input wire [NumCh-1:0]        SFP_RXP, SFP_RXN,
   output wire [NumCh-1:0]       SFP_TXP, SFP_TXN,

   input wire [NumCh-1:0][63:0]  TX_DATA,
   output wire [NumCh-1:0][63:0] RX_DATA,
   input wire [NumCh-1:0][1:0]   TX_CTRL,
   output wire [NumCh-1:0][1:0]  RX_CTRL,
   output wire [NumCh-1:0]       TX_USRCLK, RX_USRCLK,
   input wire [NumCh-1:0]        TX_VALID, RX_BITSLIP,
   output wire [NumCh-1:0]       RX_VALID,

   output wire [NumCh-1:0]       PLL_LOCKED, RX_LOCKED
   );

   wire [NumCh-1:0] 	      TX_DLL_LOCK;
   wire [NumCh-1:0]           TX_READY, RX_READY, TX_PMA_READY, RX_PMA_READY;
   wire [NumCh-1:0][79:0]     TX_PARA_DATA, RX_PARA_DATA;

   wire [NumCh-1:0]           TX_USRCLK2, RX_USRCLK2;
   
   genvar                     ch;
   generate
      if (BondingEnable==0) begin : nobond_gen
         phy_10g_8ch phy0 // width is for 4ch
           ( .tx_dll_lock        (TX_DLL_LOCK  ), // O [7:0]
             .reset              ({NumCh{RST}} ), // I [7:0]
             .tx_ready           (TX_READY     ), // O [7:0]
             .rx_ready           (RX_READY     ), // O [7:0]
             .tx_pma_ready       (TX_PMA_READY ), // O [7:0]
             .rx_pma_ready       (RX_PMA_READY ), // O [7:0]
             .tx_serial_data     (SFP_TXP      ), // O [7:0]
             .tx_serial_data_n   (SFP_TXN      ), // O [7:0]
             .rx_serial_data     (SFP_RXP      ), // I [7:0]
             .rx_serial_data_n   (SFP_RXN      ), // I [7:0]
             .pll_refclk0        (CLK156       ), // I
             .rx_is_lockedtodata (RX_LOCKED    ), // O [7:0]
             .rx_pmaif_bitslip   (RX_BITSLIP   ), // I [7:0]
             .tx_parallel_data   (TX_PARA_DATA ), // I [639:0] 
             .rx_parallel_data   (RX_PARA_DATA ), // O [639:0]
             .tx_coreclkin       (TX_USRCLK2   ), // I [7:0]
             .rx_coreclkin       (RX_USRCLK2   ), // I [7:0]
             .tx_clkout          (TX_USRCLK    ), // O [7:0]
             .tx_clkout2         (TX_USRCLK2   ), // O [7:0]
             .rx_clkout          (RX_USRCLK    ), // O [7:0]
             .rx_clkout2         (RX_USRCLK2   ), // O [7:0]
             .tx_fifo_full       (), // O[7:0]
             .tx_fifo_pfull      (), // O[3:]0
             .rx_fifo_full       (), // O[7:0]
             .rx_fifo_pfull      (), // O[7:0]
             .rx_fifo_rd_en      ({NumCh{1'b1}})  // I [7:0]
             );

         assign PLL_LOCKED = TX_DLL_LOCK;

         for (ch=0; ch<NumCh; ch=ch+1) begin : ch_gen
            // TX FIFO for synchronize to 156 MHz to 161 MHz
            wire [1:0] 	      TX_CTRLi;
            wire [63:0]       TX_DATAi;
            wire              TXFIFO_VALID;
            wire              TXFIFO_RE;

            fifo_66x512_async txfifo
              ( .rst   (RST),                 // I
                .wr_clk(TX_USRCLK [ch]),      // I
                .rd_clk(TX_USRCLK2[ch]),      // I
                .din   ({TX_CTRL[ch], TX_DATA[ch]}), // I [65:0]
                .wr_en (1'b1),              // I
                .rd_en (TXFIFO_RE),         // I
                .dout  ({TX_CTRLi, TX_DATAi}),   // O [65:0]
                .valid (TXFIFO_VALID)           // O
                );

            // Tx FIFO readout pause (1 in every 33 clk) for sync gearbox
            reg [32:0]        TXFIFO_TIMER;
            always @ (posedge TX_USRCLK2[ch]) begin
               if (RST) begin
                  TXFIFO_TIMER <= 'b1;
               end else begin
                  TXFIFO_TIMER <= {TXFIFO_TIMER[31:0], TXFIFO_TIMER[32]};
               end
            end

            assign TXFIFO_RE = ~TXFIFO_TIMER[0];
            
            assign TX_PARA_DATA[ch] = {1'b0,             // 79    (word marking)
    			               1'b0,             // 78    (deskew)
    			               1'b0,             // 77    (snapshot)
    			               {7{1'b0}},        // 76-70 (blank)
    			               1'b0,             // 69    (sync)
    			               TXFIFO_VALID,     // 68    (VALID)
    			               1'b0,             // 67    (blank)
			               TX_CTRLi,         // 66-65 (HEADER)
    			               TX_DATAi[63:39],  // 64-40 (TXDATA[63:39])
   			               1'b0,             // 39    (word marking)
    			               TX_DATAi[38:32],  // 38-32 (TXDATA[38:32])
    			               TX_DATAi[31: 0]}; // 31-0  (TXDATA[31:0])

            wire [63:0] RX_DATAi = {RX_PARA_DATA[ch][64:40], 
                                    RX_PARA_DATA[ch][38:0]};
            wire [1:0]  RX_CTRLi =  RX_PARA_DATA[ch][66:65];
            wire        RX_VALIDi = RX_PARA_DATA[ch][68];

            // FIFO for synchronize 161 MHz to 156 MHz
            fifo_66x512_async rxfifo
              ( .rst   (RST),               // I
                .wr_clk(RX_USRCLK2[ch]),            // I
                .rd_clk(RX_USRCLK [ch]),            // I
                .din   ({RX_CTRLi, RX_DATAi}), // I [65:0]
                .wr_en (RX_VALIDi),         // I
                .rd_en (1'b1),              // I
                .dout  ({RX_CTRL[ch], RX_DATA[ch]}),   // O [65:0]
                .full  (),         // O
                .empty (),        // O
                .almost_empty(), // O
                .valid (RX_VALID[ch])           // O
                );
         end // block: ch_gen
      end else begin : bond_gen// block: nobond_gen
         wire [NumCh-1:0] TX_CORECLKIN, RX_CORECLKIN;
         wire [NumCh-1:0] TX_USRCLKi,   RX_USRCLKi;

         phy_10g_8ch_pd phy0 // width is for 4ch
           ( .PD_CLK (CLK100),
             .PD_RST (RST),
             .tx_dll_lock        (TX_DLL_LOCK           ), // O [7:0]
             .reset              ({NumCh{RST}}          ), // I [7:0]
             .tx_ready           (TX_READY              ), // O [7:0]
             .rx_ready           (RX_READY              ), // O [7:0]
             .tx_pma_ready       (TX_PMA_READY          ), // O [7:0]
             .rx_pma_ready       (RX_PMA_READY          ), // O [7:0]
             .tx_serial_data     (SFP_TXP               ), // O [7:0]
             .tx_serial_data_n   (SFP_TXN               ), // O [7:0]
             .rx_serial_data     (SFP_RXP               ), // I [7:0]
             .rx_serial_data_n   (SFP_RXN               ), // I [7:0]
             .pll_refclk0        (CLK156                ), // I
             .rx_is_lockedtodata (RX_LOCKED             ), // O [7:0]
             .rx_pmaif_bitslip   (RX_BITSLIP            ), // I [7:0]
             .tx_parallel_data   (TX_PARA_DATA          ), // I [639:0] 
             .rx_parallel_data   (RX_PARA_DATA          ), // O [639:0]
             .tx_coreclkin       (TX_CORECLKIN          ), // I [7:0]
             .rx_coreclkin       (RX_CORECLKIN          ), // I [7:0]
             .tx_clkout          (TX_USRCLKi            ), // O [7:0]
             .tx_clkout2         (TX_USRCLK2            ), // O [7:0]
             .rx_clkout          (RX_USRCLKi            ), // O [7:0]
             .rx_clkout2         (RX_USRCLK2            ), // O [7:0]
             .tx_fifo_full       (), // O[7:0]
             .tx_fifo_pfull      (), // O[7:0]
             .rx_fifo_full       (), // O[7:0]
             .rx_fifo_pfull      (), // O[7:0]
             .rx_fifo_rd_en      ({NumCh{1'b1}})  // I [7:0]
             );

         assign PLL_LOCKED = {NumCh{&TX_DLL_LOCK}};

         for (ch=0; ch<NumCh; ch=ch+BondingCh) begin : coreclkin_gen
            // drive a group by common clk
            assign TX_CORECLKIN[ch +: BondingCh] = {BondingCh{TX_USRCLK2[ch]}};
            assign RX_CORECLKIN[ch +: BondingCh] = {BondingCh{RX_USRCLK2[ch]}};
            assign TX_USRCLK   [ch +: BondingCh] = {BondingCh{TX_USRCLKi[ch]}};
            assign RX_USRCLK   [ch +: BondingCh] = {BondingCh{RX_USRCLKi[ch]}};
         end
         
                 
         for (ch=0; ch<NumCh; ch=ch+1) begin : ch_gen
            // TX FIFO for synchronize to 156 MHz to 161 MHz
            wire [1:0] 	      TX_CTRLi;
            wire [63:0]       TX_DATAi;
            wire              TXFIFO_VALID;
            wire              TXFIFO_RE;

            fifo_66x512_async txfifo
              ( .rst   (RST),                 // I
                .wr_clk(TX_USRCLK [ch]),      // I
                .rd_clk(TX_CORECLKIN[ch]),      // I
                .din   ({TX_CTRL[ch], TX_DATA[ch]}), // I [65:0]
                .wr_en (1'b1),              // I
                .rd_en (TXFIFO_RE),         // I
                .dout  ({TX_CTRLi, TX_DATAi}),   // O [65:0]
                .valid (TXFIFO_VALID)           // O
                );

            // Tx FIFO readout pause (1 in every 33 clk) for sync gearbox
            reg [32:0]        TXFIFO_TIMER;
            always @ (posedge TX_CORECLKIN[ch]) begin
               if (RST) begin
                  TXFIFO_TIMER <= 'b1;
               end else begin
                  TXFIFO_TIMER <= {TXFIFO_TIMER[31:0], TXFIFO_TIMER[32]};
               end
            end

            assign TXFIFO_RE = ~TXFIFO_TIMER[0];
            
            assign TX_PARA_DATA[ch] = {1'b0,             // 79    (word marking)
    			               1'b0,             // 78    (deskew)
    			               1'b0,             // 77    (snapshot)
    			               {7{1'b0}},        // 76-70 (blank)
    			               1'b0,             // 69    (sync)
    			               TXFIFO_VALID,     // 68    (VALID)
    			               1'b0,             // 67    (blank)
			               TX_CTRLi,         // 66-65 (HEADER)
    			               TX_DATAi[63:39],  // 64-40 (TXDATA[63:39])
   			               1'b0,             // 39    (word marking)
    			               TX_DATAi[38:32],  // 38-32 (TXDATA[38:32])
    			               TX_DATAi[31: 0]}; // 31-0  (TXDATA[31:0])

            wire [63:0] RX_DATAi = {RX_PARA_DATA[ch][64:40], 
                                    RX_PARA_DATA[ch][38:0]};
            wire [1:0]  RX_CTRLi =  RX_PARA_DATA[ch][66:65];
            wire        RX_VALIDi = RX_PARA_DATA[ch][68];

            // FIFO for synchronize 161 MHz to 156 MHz
            fifo_66x512_async rxfifo
              ( .rst   (RST),               // I
                .wr_clk(RX_CORECLKIN[ch]),            // I
                .rd_clk(RX_USRCLK [ch]),            // I
                .din   ({RX_CTRLi, RX_DATAi}), // I [65:0]
                .wr_en (RX_VALIDi),         // I
                .rd_en (1'b1),              // I
                .dout  ({RX_CTRL[ch], RX_DATA[ch]}),   // O [65:0]
                .full  (),         // O
                .empty (),        // O
                .almost_empty(), // O
                .valid (RX_VALID[ch])           // O
                );
         end // block: ch_gen

      end
   endgenerate

endmodule // agf014_xcvr
`default_nettype wire
