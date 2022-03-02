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
//    kyokko_rx_cb: Kyokko Rx channel-bonding synchronizer
// ----------------------------------------------------------------------

`default_nettype none

module kyokko_rx_cb # ( parameter BondingCh = 4 )
   ( input wire CLK, RST,
     input wire [BondingCh-1:0] DATA_IS_VALIDi, RX_IS_CB,
     output reg [4:0] CB_STAT,
     output reg [BondingCh-1:0] FIFO_RE,
     output wire                TIMEOUT);

   parameter CB_Timeout = 3;
   parameter CB_SYNC_max = 7;
   parameter WORD_CNT_max = 100;
   parameter CB_Limit = 400;

   reg [BondingCh-1:0] 	    CB;
   reg [4:0] 	    CNT;
   reg [7:0] 	    CB_SYNC;

   /*
   always @ (posedge CLK) begin
      if (RST) begin
	 CB_STAT <= 1;
	 CNT <= 0;
	 CB_Clear <= 0;
      end else begin
	 case (CB_STAT)
	   'b0001: begin
	      CNT <= 0;
	      CB_STAT <= (CB_Clear == CB_Clear_cnt) ? 'b0100:
			 ( RX_IS_CB ? 'b0010: 'b0001 );
	   end
           
	   'b0010: begin
	      if (CNT == CB_Timeout) begin
		 if (&CB) CB_Clear <= CB_Clear +1;
                 else     CB_Clear <= 0;  // Reset on fail
		 CB_STAT <= 'b0001;
	      end else  CNT <= CNT +1;

    	   end // case: 'b001
           
	   'b0100: begin
              // Wait for all FIFO_RE goes down
	      if (&(~FIFO_RE)) begin
		 CB_STAT <= 'b1000;
	      end
	   end
           
	   'b1000: begin // Ready
              // non-synchronous CB detection
	      if ((RX_IS_CB != 0) && (&RX_IS_CB == 0)) begin 
                 CB_STAT <= 'b001;
                 CNT <= 0;
                 CB_Clear <= 0;
              end
	   end

           default:
             CB_STAT <= 1;
	 endcase // case (CB_STAT)
      end
   end // always @ (posedge CLK)
    


   reg [4:0] CB_STATt;
   reg [4:0] CNTt;
   reg [7:0] CB_Cleart;*/
   reg [7:0] 	    WORD_CNT;
   wire 	    DATA_IS_VALID = &DATA_IS_VALIDi;
   reg 		    WAIT_CB;

   always @ (posedge CLK) begin
      if (RST) begin
	 CB_STAT <= 1;
      end else begin
	 case (CB_STAT)
	   'b00001: begin // Reset
	      CNT <= 0;
	      CB_SYNC <= 0;
	      WORD_CNT <= 0;
	      CB_STAT <= 'b0010;
	      WAIT_CB <= 0;
	   end

	   'b00010: begin // Write CB words to FIFO
	      if (WAIT_CB) begin // Start count
		 if (CNT == CB_Timeout) begin
		    CB_STAT <= (CB_SYNC == CB_SYNC_max) ? 'b00100:
			       'b00010;
		    CB_SYNC <= (&CB) ? CB_SYNC +1: 0;
		    CNT <= 0;
		    WAIT_CB <= 0;
		 end else CNT <= CNT +1;
	      end else if (|RX_IS_CB) WAIT_CB <= 1;
	   end
	   
	   'b00100: begin // Write all words to FIFO
/*	      if (WAIT_CB) begin
		 if (CNT == CB_Timeout) begin
		    CB_STAT <=  (WORD_SYNC == WORD_SYNC_max) ? 'b01000:
			     'b00100;
		    WORD_SYNC <= (&CB) ?  WORD_SYNC +1: 0;
		    CNT <= 0;
		    WAIT_CB <= 0;
		 end else CNT <= CNT +1;
	      end else if (|RX_IS_CB) WAIT_CB <= 1; */
	      if (WORD_CNT == WORD_CNT_max) CB_STAT <= 'b01000;
	      else WORD_CNT <= DATA_IS_VALID ? WORD_CNT +1: WORD_CNT;
	   end

	   'b01000: begin
	      if (&(~FIFO_RE)) CB_STAT <= 'b10000;
	   end

	   'b10000: begin
	      if ((RX_IS_CB != 0) && (RX_IS_CB == 0)) CB_STAT <= 'b0001;
	   end
	 endcase
      end
   end
   

   /* 
   // 4-lane 
   always @ (posedge CLK) begin
      if (RST) begin
	 CB <= 0;
	 FIFO_RE <= {BondingCh{'b1}};
      end else begin
	 if (|CB_STAT[1:0]) begin
	    if (CB_STAT[1] & CNT == CB_Timeout) CB <= 0;
	    else begin
	       if (RX_IS_CB[0]) CB[0] <= 1;
	       if (RX_IS_CB[1]) CB[1] <= 1;
	       if (RX_IS_CB[2]) CB[2] <= 1;
	       if (RX_IS_CB[3]) CB[3] <= 1;
	    end
	 end

	 if (CB_STAT[2]) begin
	    if (&(~FIFO_RE)) FIFO_RE <= 'b1111;
	    else begin
	       if (RX_IS_CB[0]) FIFO_RE[0] <= 0;
	       if (RX_IS_CB[1]) FIFO_RE[1] <= 0;
	       if (RX_IS_CB[2]) FIFO_RE[2] <= 0;
	       if (RX_IS_CB[3]) FIFO_RE[3] <= 0;
	    end
	 end
      end // else: !if(RST)
   end // always @ (posedge CLK)
    */

   // n-lane version
   wire [BondingCh-1:0]      CB_CNT_FULL;
   wire [BondingCh-1:0]       CB_WAIT_CNT_FULL;
   
   genvar lane;
   generate
      for (lane=0; lane<BondingCh; lane=lane+1) begin : cb_reg_gen
         reg  [26:0] CB_WAIT_CNT;
         reg [9:0]   CB_CNT;

         always @ (posedge CLK) begin
            if (RST) begin
	       CB     [lane] <= 0;
	       FIFO_RE[lane] <= 1;
               CB_CNT  <= 0;
               CB_WAIT_CNT   <= 0;
            end else begin
	       if (|CB_STAT[2:0]) begin
	          if (CB_STAT[1] & CNT == CB_Timeout) CB[lane] <= 0;
	          else if (RX_IS_CB[lane]) CB[lane] <= 1;
	       end

	       if (CB_STAT[3]) begin
	          if (&(~FIFO_RE)) FIFO_RE[lane] <= 'b1;
	          else if (RX_IS_CB[lane]) FIFO_RE[lane] <= 0;
	       end

               if (RX_IS_CB[lane] & ~CB_STAT[4] & ~CB_CNT_FULL[lane]) begin
                  CB_CNT <= CB_CNT + 1;
               end

               if (~CB_WAIT_CNT_FULL[lane] & ~CB_STAT[4]) 
                 CB_WAIT_CNT <= RX_IS_CB[lane] ? 0 : CB_WAIT_CNT+1;
               
            end // else: !if(RST)
         end // always @ (posedge CLK)

         assign CB_CNT_FULL[lane] = (CB_CNT == CB_Limit);
         assign CB_WAIT_CNT_FULL[lane] = &CB_WAIT_CNT;
      end // block: cb_reg_gen
   endgenerate
   

   assign TIMEOUT = |{CB_CNT_FULL, CB_WAIT_CNT_FULL};
   
endmodule

`default_nettype wire
  
