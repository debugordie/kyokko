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
//    a10_xcvr_4ch: Quad Arria 10 GX transceiver wrapper
//    c10_phy_bitorder: Bit order reverser for Intel GX transceivers
// ----------------------------------------------------------------------

`default_nettype none

module a10_xcvr_4ch # ( parameter NumCh=4 )
   ( input wire                 RST, // RST somehow
     input wire                 USRCLK, // 125MHz on HawkEye
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
     output wire [NumCh-1:0]          RX_LOCKED
  );

   wire                PLL_PD;
   wire                TX_SCLK;
   
   atx_5g atxpll
     ( .pll_powerdown (PLL_PD),       // I
       .pll_refclk0   (REFCLK644P),     // I
       .tx_serial_clk (TX_SCLK),      // O
       .pll_locked    (PLL_LOCKED),   // O
       .pll_cal_busy  ()              // O
       );

   wire [NumCh-1:0]   TX_ARST, TX_DRST, RX_ARST, RX_DRST;
   wire [NumCh-1:0]   TX_CALBUSY, TX_READY;
   wire [NumCh-1:0]   RX_CALBUSY, RX_READY;
   
   phy_rst_ctrl_4ch phy_rst 
     ( .clock              (USRCLK),      // I
       .reset              (RST),         // I
       .pll_powerdown      (PLL_PD),      // O
       .tx_analogreset     (TX_ARST),     // O [NumCh-1:0]
       .tx_digitalreset    (TX_DRST),     // O [NumCh-1:0]
       .tx_ready           (TX_READY),    // O [NumCh-1:0]
       .pll_locked         (PLL_LOCKED),  // I
       .pll_select         (1'b0),        // I
       .tx_cal_busy        (TX_CALBUSY),  // I [NumCh-1:0]
       .rx_analogreset     (RX_ARST),     // O [NumCh-1:0]
       .rx_digitalreset    (RX_DRST),     // O [NumCh-1:0]
       .rx_ready           (RX_READY),    // O [NumCh-1:0]
       .rx_is_lockedtodata (RX_LOCKED),   // I [NumCh-1:0]
       .rx_cal_busy        (RX_CALBUSY)   // I [NumCh-1:0] 
       );

   generate
      genvar    ch;
      for (ch=0; ch<NumCh; ch=ch+1) begin : phy_gen

         wire [63:0]  RX_DATAi;
         wire [63:0]  TX_DATAi;
         wire [1:0]   RX_CTRLi, TX_CTRLi;

         phy_10g phy0
           ( .tx_analogreset          (TX_ARST   [ch]),  // I
             .tx_digitalreset         (TX_DRST   [ch]),  // I
             .rx_analogreset          (RX_ARST   [ch]),  // I
             .rx_digitalreset         (RX_DRST   [ch]),  // I
             .tx_cal_busy             (TX_CALBUSY[ch]),  // O
             .rx_cal_busy             (RX_CALBUSY[ch]),  // O
             .tx_serial_clk0          (TX_SCLK),         // I
             .rx_cdr_refclk0          (REFCLK644P),      // I
             .tx_serial_data          (SFP_TXP   [ch]),  // O
             .rx_serial_data          (SFP_RXP   [ch]),  // I
             .rx_is_lockedtoref       (),                // O
             .rx_is_lockedtodata      (RX_LOCKED [ch]),  // O
             .rx_enh_fifo_rd_en       (1'b1),            // I
             .tx_coreclkin            (TX_USRCLK [ch]),  // I
             .rx_coreclkin            (RX_USRCLK [ch]),  // I
             .tx_clkout               (),                // O
             .rx_clkout               (),                // O
             .tx_pma_div_clkout       (TX_USRCLK [ch]),  // O
             .rx_pma_div_clkout       (RX_USRCLK [ch]),  // O
             .tx_parallel_data        (TX_DATAi),        // I [63:0]
             .tx_control              (TX_CTRLi),        // I [1:0]
             .unused_tx_parallel_data (),                // I
             .unused_tx_control       (),                // I
             .rx_parallel_data        (RX_DATAi),        // O [63:0]
             .rx_control              (RX_CTRLi),        // O [1:0]
             .unused_rx_parallel_data (),                // O
             .unused_rx_control       (),                // O
             .rx_bitslip              (RX_BITSLIP[ch]),  // I
             .tx_enh_data_valid       (TX_VALID  [0])    // I
             );


         c10_phy_bitorder bo
           ( .RX_USRCLK(RX_USRCLK[ch]), 
             .TX_USRCLK(TX_USRCLK[ch]),
             .RX_DATAi (RX_DATAi),  .RX_DATA(RX_DATA[63+64*ch : 64*ch]),
             .TX_DATAi (TX_DATAi),  .TX_DATA(TX_DATA[63+64*ch : 64*ch]),
             .RX_CTRLi (RX_CTRLi),  .RX_CTRL(RX_CTRL[ 1+ 2*ch :  2*ch]),
p             .TX_CTRLi (TX_CTRLi),  .TX_CTRL(TX_CTRL[ 1+ 2*ch :  2*ch]) );
      end // block: phy_gen
   endgenerate

endmodule // c10_xcvr

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
  
