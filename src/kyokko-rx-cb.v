module kyokko_rx_cb
  (input wire CLK, RST, GO,
   input wire [3:0] RXCB,
   output reg [3:0] CB_STAT,
   output reg [3:0] FIFO_RE );

   parameter CB_Keep = 3;
   parameter CB_Clear_cnt = 4;

   reg [3:0] 	    CB;
   reg [4:0] 	    CNT;
   reg [2:0] 	    CB_Clear;

   always @ (posedge CLK) begin
      if (RST) begin
	 CB_STAT <= 1;
	 FIFO_RE <= 'b1111;
	 CNT <= 0;
	 CB <= 0;
	 CB_Clear <= 0;
      end else begin
	 if (GO) begin
	    case (CB_STAT)
	      'b0001: begin
		 CNT <= 0;
		 CB_STAT <= (CB_Clear == CB_Clear_cnt) ? 'b0100:
			    ( RXCB ? 'b0010: 'b0001 );
	      end
	      
	      'b0010: begin
		 if (CNT == CB_Keep) begin
		    CB <= 0;
		    if (&CB) CB_Clear <= CB_Clear +1;
		    CB_STAT <= 'b0001;
		 end else  CNT <= CNT +1;
	      end // case: 'b001
	      
	      'b0100: begin
		 if (&(~FIFO_RE)) begin
		    FIFO_RE <= 'b1111;
		    CB_STAT <= 'b1000;
		 end
	      end
	      
	      'b1000: begin
		 if (~(RXCB == 0) & (&RXCB == 0)) CB_STAT <= 'b001;
	      end
	    endcase // case (CB_STAT)
	 end // if (GO)
      end
   end // always @ (posedge CLK)

   always @ (posedge CLK) begin
      if (|CB_STAT[1:0]) begin
	 if (RXCB[0]) CB[0] <= 1;
	 if (RXCB[1]) CB[1] <= 1;
	 if (RXCB[2]) CB[2] <= 1;
	 if (RXCB[3]) CB[3] <= 1;
      end
      
      if (CB_STAT[2]) begin
	 if (RXCB[0]) FIFO_RE[0] <= 0;
	 if (RXCB[1]) FIFO_RE[1] <= 0;
	 if (RXCB[2]) FIFO_RE[2] <= 0;
	 if (RXCB[3]) FIFO_RE[3] <= 0;
      end
   end
   
endmodule
