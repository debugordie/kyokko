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
//    axis_fifo: AXI4-Stream FIFO compatible for IntelFPGAs
//    axis_async_fifo: and its async version
// ----------------------------------------------------------------------

// `timescale 1ns/1ps
`default_nettype none

module axis_fifo # ( parameter Width=64)
  ( input wire         s_aclk, 
    input wire         s_aresetn,
    
    input wire         s_axis_tvalid,
    output wire        s_axis_tready,
    input wire [Width-1:0]  s_axis_tdata,
    input wire         s_axis_tlast,

    output wire        m_axis_tvalid,
    input wire         m_axis_tready,
    output wire [Width-1:0] m_axis_tdata,
    output wire        m_axis_tlast
   );


   wire               WRITE_FULL, READ_EMPTY;
   assign s_axis_tready = ~(WRITE_FULL | ~s_aresetn);
   assign m_axis_tvalid = ~READ_EMPTY;

   scfifo #
     ( .lpm_width(Width+1),
       .lpm_numwords(512),
       .lpm_widthu(9),
       .lpm_showahead          ("ON"),
//       .almost_full_value(400),
       .lpm_type("scfifo"),
       .overflow_checking("ON"),
       .underflow_checking("ON"),
       .use_eab("ON"), // on BRAM
       .add_ram_output_register("ON")
      )
   fifo
     (
      .clock (s_aclk),
      .data  ({s_axis_tdata, s_axis_tlast}),
      .wrreq (s_axis_tvalid),
      .rdreq (m_axis_tready),
      .sclr  (~s_aresetn),
      .aclr  (~s_aresetn),
      .empty (READ_EMPTY),
      .full  (WRITE_FULL),
      .q     ({m_axis_tdata, m_axis_tlast})
      );

 
endmodule // axis_fifo

module axis_async_fifo # (parameter Width=64)
  ( input wire s_aclk, m_aclk,
    input wire         s_aresetn,

    input wire         s_axis_tvalid,
    output wire        s_axis_tready,
    input wire [Width-1:0]  s_axis_tdata,
    input wire         s_axis_tlast,

    output wire        m_axis_tvalid,
    input wire         m_axis_tready,
    output wire [Width-1:0] m_axis_tdata,
    output wire        m_axis_tlast
    );

   wire                WRITE_FULL, READ_EMPTY;
   assign s_axis_tready = ~(WRITE_FULL | ~s_aresetn);
   assign m_axis_tvalid = ~READ_EMPTY;
   
   dcfifo_async # 
     ( .lpm_width(Width+1),
       .lpm_numwords(512),
       .lpm_widthu(9),
       .lpm_showahead("ON"),
       .overflow_checking("ON"),
       .underflow_checking("ON"),
       .use_eab("ON"), // on BRAM
       .add_ram_output_register("ON") )
   fifo 
     ( .rdclk   (m_aclk),
       .wrclk   (s_aclk), 
       .aclr    (~s_aresetn), 
       .wrreq   (s_axis_tvalid),
       .wrfull  (WRITE_FULL), 
       .data    ({s_axis_tdata, s_axis_tlast}), 
       .rdreq   (m_axis_tready),
       .rdfull  (), 
       .rdempty (READ_EMPTY), 
       .wrempty (), 
       .rdusedw (), 
       .wrusedw (),
       .q       ({m_axis_tdata, m_axis_tlast})
       );

endmodule // axis_async_fifo

// ------------------------------------------------------------
// Testbenches: requires altera_mf.v

`ifdef AXIS_FIFO_TB

module tb();
   parameter real StepIn = 8;

   reg CLK = 1;
   always # (StepIn/2) CLK <= ~CLK;

   reg RST;

   initial begin
      `include "wave-record.vh"
      RST <= 1;

      #(10.1*StepIn)
      RST <= 0;


      #(2500*StepIn)
      $finish;
   end

   reg [63:0] IN_DATA = 0;
   reg        IN_VALID;
   wire       IN_READY;

   reg        OUT_READY;
   wire [63:0] OUT_DATA;
   wire        OUT_VALID;

   axis_fifo uut
     ( .s_aclk(CLK),
       .s_aresetn(~RST),
       .s_axis_tvalid(IN_VALID),
       .s_axis_tready(IN_READY),
       .s_axis_tdata (IN_DATA),
       .m_axis_tready(OUT_READY),
       .m_axis_tvalid(OUT_VALID),
       .m_axis_tdata (OUT_DATA) );
       

   always @ (posedge CLK) begin
      IN_VALID <= (($random & 8'hff) > 120);

      if (IN_VALID & IN_READY) IN_DATA <= IN_DATA+1;

   end

   reg [63:0] OUT_R;
   reg        OUT_OK;
   always @ (posedge CLK) begin
      OUT_READY <= (($random & 8'hff) > 180);

      if (OUT_VALID & OUT_READY) begin
         $display("OUT %x", OUT_DATA);
         OUT_R <= OUT_DATA;
         OUT_OK <= (OUT_DATA == OUT_R+1);
      end
   end

endmodule

`endif


`ifdef AXIS_ASYNC_FIFO_TB

module tb();
   parameter real StepIn = 8;
   parameter real StepOut = 10;

   reg CLK_IN = 1;
   always # (StepIn/2) CLK_IN <= ~CLK_IN;

   reg CLK_OUT = 1;
   always # (StepOut/2) CLK_OUT <= ~CLK_OUT;

   reg RST;

   initial begin
      `include "wave-record.vh"
      RST <= 1;

      #(10.1*StepIn)
      RST <= 0;


      #(2500*StepIn)
      $finish;
   end

   reg [63:0] IN_DATA = 0;
   reg        IN_VALID;
   wire       IN_READY;

   reg        OUT_READY;
   wire [63:0] OUT_DATA;
   wire        OUT_VALID;

   axis_async_fifo uut
     ( .m_aclk(CLK_OUT),
       .s_aclk(CLK_IN),
       .s_aresetn(~RST),
       .s_axis_tvalid(IN_VALID),
       .s_axis_tready(IN_READY),
       .s_axis_tdata (IN_DATA),
       .m_axis_tready(OUT_READY),
       .m_axis_tvalid(OUT_VALID),
       .m_axis_tdata (OUT_DATA) );
       

   always @ (posedge CLK_IN) begin
      IN_VALID <= (($random & 8'hff) > 120);

      if (IN_VALID & IN_READY) IN_DATA <= IN_DATA+1;

   end

   reg [63:0] OUT_R;
   reg        OUT_OK;
   always @ (posedge CLK_OUT) begin
      OUT_READY <= (($random & 8'hff) > 180);

      if (OUT_VALID & OUT_READY) begin
         $display("OUT %x", OUT_DATA);
         OUT_R <= OUT_DATA;
         OUT_OK <= (OUT_DATA == OUT_R+1);
      end
   end

endmodule

`endif


`default_nettype wire
