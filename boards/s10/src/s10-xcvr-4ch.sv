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
//    s10_gx_4ch: Quad Stratix 10 transceiver wrapper in GX mode
//    c10_phy_bitorder: Bit order reverser for Intel GX transceivers
// ----------------------------------------------------------------------

`default_nettype none

module s10_xcvr_4ch # ( parameter NumCh=4, BondingEnable=0 )
   ( input wire                 RST, // RST somehow
     input wire                 USRCLK, // assumed to be 250MHz
     input wire                 REFCLK644P,
     input wire [NumCh-1:0]     SFP_RXP,
     output wire [NumCh-1:0]    SFP_TXP,
     
     input wire [NumCh*64-1:0]  TX_DATA, 
     output wire [NumCh*64-1:0] RX_DATA,
     input wire [NumCh*2-1:0]   TX_CTRL, 
     output wire [NumCh*2-1:0]  RX_CTRL,
     output wire [NumCh-1:0]    TX_USRCLK, RX_USRCLK,
     input wire [NumCh-1:0]     TX_VALID, RX_BITSLIP,
    
     output wire                PLL_LOCKED, 
     output wire [NumCh-1:0]    RX_LOCKED
  );

   wire [NumCh-1:0]   TX_ARST,  TX_DRST,  RX_ARST,  RX_DRST,
                      TX_ASTAT, TX_DSTAT, RX_ASTAT, RX_DSTAT;
   wire [NumCh-1:0]   TX_CALBUSY, TX_READY;
   wire [NumCh-1:0]   RX_CALBUSY, RX_READY;
   
   phy_rst_ctrl_4ch phy_rst 
     ( .clock               (USRCLK),      // I assumed to be 250MHz
       .reset               (RST),         // I
       .tx_analogreset      (TX_ARST),     // O [NumCh-1:0]
       .tx_analogreset_stat (TX_ASTAT),    // I [NumCh-1:0]
       .tx_digitalreset_stat(TX_DSTAT),    // I [NumCh-1:0]
       .tx_digitalreset     (TX_DRST),     // O [NumCh-1:0]
       .tx_ready            (TX_READY),    // O [NumCh-1:0]
       .pll_locked          (PLL_LOCKED),  // I
       .pll_select          (1'b0),        // I
       .tx_cal_busy         (TX_CALBUSY),  // I [NumCh-1:0]
       .rx_analogreset      (RX_ARST),     // O [NumCh-1:0]
       .rx_digitalreset     (RX_DRST),     // O [NumCh-1:0]
       .rx_analogreset_stat (RX_ASTAT),    // I [NumCh-1:0]
       .rx_digitalreset_stat(RX_DSTAT),    // I [NumCh-1:0]
       .rx_ready            (RX_READY),    // O [NumCh-1:0]
       .rx_is_lockedtodata  (RX_LOCKED),   // I [NumCh-1:0]
       .rx_cal_busy         (RX_CALBUSY)   // I [NumCh-1:0] 
       );


   wire [NumCh-1:0] [63:0] RX_DATAi;
   wire [NumCh-1:0] [63:0]        TX_DATAi;
   wire [NumCh-1:0] [1:0]         RX_CTRLi, TX_CTRLi;
   
   wire [NumCh-1:0]               TX_DLL_LOCK;
         

   wire                TX_SCLK;
   wire [5:0]          TX_BCLK; // bonding clock

   generate
      if (BondingEnable==0) begin : no_bond_gen
         atx_5g atxpll
           ( .pll_refclk0   (REFCLK644P),   // I
             .tx_serial_clk (TX_SCLK),      // O
             .pll_locked    (PLL_LOCKED),   // O
             .pll_cal_busy  () );           // O

         phy_10g_4ch phy0
           ( .tx_analogreset          (TX_ARST   ),  // I
             .tx_digitalreset         (TX_DRST   ),  // I
             .rx_analogreset          (RX_ARST   ),  // I
             .rx_digitalreset         (RX_DRST   ),  // I
             .tx_analogreset_stat     (TX_ASTAT  ),  // O
             .tx_digitalreset_stat    (TX_DSTAT  ),  // O
             .rx_analogreset_stat     (RX_ASTAT  ),  // O
             .rx_digitalreset_stat    (RX_DSTAT  ),  // O
             .tx_cal_busy             (TX_CALBUSY),  // O
             .rx_cal_busy             (RX_CALBUSY),  // O
             .tx_serial_clk0          ({NumCh{TX_SCLK}}),         // I
             .rx_cdr_refclk0          (REFCLK644P),      // I
             .tx_serial_data          (SFP_TXP   ),  // O
             .rx_serial_data          (SFP_RXP   ),  // I
             .rx_is_lockedtoref       (),                // O
             .rx_is_lockedtodata      (RX_LOCKED ),  // O
             .tx_coreclkin            (TX_USRCLK ),  // I
             .rx_coreclkin            (RX_USRCLK ),  // I
             .tx_clkout               (TX_USRCLK ),  // O PMA divclk
             .rx_clkout               (RX_USRCLK ),  // O PMA divclk
             .tx_parallel_data        (TX_DATAi),        // I [63:0]
             .tx_control              (TX_CTRLi),        // I [1:0]
             .unused_tx_parallel_data (),                // I
             .rx_fifo_rd_en           ({NumCh{1'b1}}),            // I
             .rx_parallel_data        (RX_DATAi),        // O [63:0]
             .rx_control              (RX_CTRLi),        // O [1:0]
             .unused_rx_parallel_data (),                // O
             .rx_bitslip              (RX_BITSLIP),  // I
             .tx_dll_lock             (TX_DLL_LOCK),     // O
             .tx_fifo_wr_en           ({NumCh{TX_VALID[0]}} & TX_DLL_LOCK) // I
             );

      end else begin : bond_gen
         atx_5g_4cb atxpll 
           ( .pll_refclk0   (REFCLK644P),   // I
             .tx_serial_clk (),             // O
             .pll_locked    (PLL_LOCKED),   // O
             .pll_cal_busy  (),             // O
             .tx_bonding_clocks (TX_BCLK) );

         wire TXCLKc, RXCLKc;
         assign TX_USRCLK = {NumCh{TXCLKc}};
         assign RX_USRCLK = {NumCh{RXCLKc}};
         
         phy_10g_4cb phy0
           ( .tx_analogreset          (TX_ARST   ),  // I
             .tx_digitalreset         (TX_DRST   ),  // I
             .rx_analogreset          (RX_ARST   ),  // I
             .rx_digitalreset         (RX_DRST   ),  // I
             .tx_analogreset_stat     (TX_ASTAT  ),  // O
             .tx_digitalreset_stat    (TX_DSTAT  ),  // O
             .rx_analogreset_stat     (RX_ASTAT  ),  // O
             .rx_digitalreset_stat    (RX_DSTAT  ),  // O
             .tx_cal_busy             (TX_CALBUSY),  // O
             .rx_cal_busy             (RX_CALBUSY),  // O
             .tx_bonding_clocks       ({NumCh{TX_BCLK}}),    // I
             .rx_cdr_refclk0          (REFCLK644P),      // I
             .tx_serial_data          (SFP_TXP   ),  // O
             .rx_serial_data          (SFP_RXP   ),  // I
             .rx_is_lockedtoref       (),                // O
             .rx_is_lockedtodata      (RX_LOCKED ),  // O
             .tx_coreclkin            (TX_USRCLK ),  // I
             .rx_coreclkin            (RX_USRCLK ),  // I
             .tx_clkout               (TXCLKc ),  // O PMA divclk
             .rx_clkout               (RXCLKc ),  // O PMA divclk
             .tx_parallel_data        (TX_DATAi),        // I [63:0]
             .tx_control              (TX_CTRLi),        // I [1:0]
             .unused_tx_parallel_data (),                // I
             .rx_fifo_rd_en           ({NumCh{1'b1}}),            // I
             .rx_parallel_data        (RX_DATAi),        // O [63:0]
             .rx_control              (RX_CTRLi),        // O [1:0]
             .unused_rx_parallel_data (),                // O
             .rx_bitslip              (RX_BITSLIP),  // I
             .tx_dll_lock             (TX_DLL_LOCK),     // O
             .tx_fifo_wr_en           ({NumCh{TX_VALID[0]}} & TX_DLL_LOCK)   // I
             );
      end
   endgenerate


   
   generate
      genvar    ch;
      for (ch=0; ch<NumCh; ch=ch+1) begin : phy_gen
         c10_phy_bitorder bo
           ( .RX_USRCLK(RX_USRCLK[ch]), 
             .TX_USRCLK(TX_USRCLK[ch]),
             .RX_DATAi (RX_DATAi[ch]),  .RX_DATA(RX_DATA[63+64*ch : 64*ch]),
             .TX_DATAi (TX_DATAi[ch]),  .TX_DATA(TX_DATA[63+64*ch : 64*ch]),
             .RX_CTRLi (RX_CTRLi[ch]),  .RX_CTRL(RX_CTRL[ 1+ 2*ch :  2*ch]),
             .TX_CTRLi (TX_CTRLi[ch]),  .TX_CTRL(TX_CTRL[ 1+ 2*ch :  2*ch]) );
      end // block: phy_gen
   endgenerate

endmodule // s10_xcvr_4ch

module c10_phy_bitorder
  ( input wire RX_USRCLK, TX_USRCLK,
    input wire [63:0]  RX_DATAi,
    output wire [63:0] RX_DATA,
    input wire [1:0]   RX_CTRLi,
    output reg [1:0]   RX_CTRL,

    input wire [63:0]  TX_DATA,
    output reg [63:0]  TX_DATAi,
    input wire [1:0]   TX_CTRL,
    output wire [1:0]  TX_CTRLi );

   
   assign RX_DATA = { RX_DATAi[ 0], RX_DATAi[ 1], RX_DATAi[ 2], RX_DATAi[ 3],
                      RX_DATAi[ 4], RX_DATAi[ 5], RX_DATAi[ 6], RX_DATAi[ 7],
                      RX_DATAi[ 8], RX_DATAi[ 9], RX_DATAi[10], RX_DATAi[11],
                      RX_DATAi[12], RX_DATAi[13], RX_DATAi[14], RX_DATAi[15],
                      RX_DATAi[16], RX_DATAi[17], RX_DATAi[18], RX_DATAi[19],
                      RX_DATAi[20], RX_DATAi[21], RX_DATAi[22], RX_DATAi[23],
                      RX_DATAi[24], RX_DATAi[25], RX_DATAi[26], RX_DATAi[27],
                      RX_DATAi[28], RX_DATAi[29], RX_DATAi[30], RX_DATAi[31],
                      RX_DATAi[32], RX_DATAi[33], RX_DATAi[34], RX_DATAi[35],
                      RX_DATAi[36], RX_DATAi[37], RX_DATAi[38], RX_DATAi[39],
                      RX_DATAi[40], RX_DATAi[41], RX_DATAi[42], RX_DATAi[43],
                      RX_DATAi[44], RX_DATAi[45], RX_DATAi[46], RX_DATAi[47],
                      RX_DATAi[48], RX_DATAi[49], RX_DATAi[50], RX_DATAi[51],
                      RX_DATAi[52], RX_DATAi[53], RX_DATAi[54], RX_DATAi[55],
                      RX_DATAi[56], RX_DATAi[57], RX_DATAi[58], RX_DATAi[59],
                      RX_DATAi[60], RX_DATAi[61], RX_DATAi[62], RX_DATAi[63] };

   // always @ (*)
   always @ (posedge RX_USRCLK)
     RX_CTRL <= { RX_CTRLi[0], RX_CTRLi[1] };

   // always @ (*)
   always @ (posedge TX_USRCLK)
     TX_DATAi <= { TX_DATA[ 0], TX_DATA[ 1], TX_DATA[ 2], TX_DATA[ 3],
                   TX_DATA[ 4], TX_DATA[ 5], TX_DATA[ 6], TX_DATA[ 7],
                   TX_DATA[ 8], TX_DATA[ 9], TX_DATA[10], TX_DATA[11],
                   TX_DATA[12], TX_DATA[13], TX_DATA[14], TX_DATA[15],
                   TX_DATA[16], TX_DATA[17], TX_DATA[18], TX_DATA[19],
                   TX_DATA[20], TX_DATA[21], TX_DATA[22], TX_DATA[23],
                   TX_DATA[24], TX_DATA[25], TX_DATA[26], TX_DATA[27],
                   TX_DATA[28], TX_DATA[29], TX_DATA[30], TX_DATA[31],
                   TX_DATA[32], TX_DATA[33], TX_DATA[34], TX_DATA[35],
                   TX_DATA[36], TX_DATA[37], TX_DATA[38], TX_DATA[39],
                   TX_DATA[40], TX_DATA[41], TX_DATA[42], TX_DATA[43],
                   TX_DATA[44], TX_DATA[45], TX_DATA[46], TX_DATA[47],
                   TX_DATA[48], TX_DATA[49], TX_DATA[50], TX_DATA[51],
                   TX_DATA[52], TX_DATA[53], TX_DATA[54], TX_DATA[55],
                   TX_DATA[56], TX_DATA[57], TX_DATA[58], TX_DATA[59],
                   TX_DATA[60], TX_DATA[61], TX_DATA[62], TX_DATA[63] };
   
   assign TX_CTRLi = { TX_CTRL[0], TX_CTRL[1] };
   

endmodule // c10_phy_bitorder

`default_nettype wire
  
