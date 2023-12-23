module capture # (
  parameter integer C_M_AXI_THREAD_ID_WIDTH       = 1,
  parameter integer C_M_AXI_ADDR_WIDTH            = 32,
  parameter integer C_M_AXI_DATA_WIDTH            = 64,
  parameter integer C_M_AXI_AWUSER_WIDTH          = 1,
  parameter integer C_M_AXI_ARUSER_WIDTH          = 1,
  parameter integer C_M_AXI_WUSER_WIDTH           = 8,    // Warning対策
  parameter integer C_M_AXI_RUSER_WIDTH           = 8,    // Warning対策
  parameter integer C_M_AXI_BUSER_WIDTH           = 1,

  /* 以下は未対応だけどコンパイルエラー回避のため付加しておく */
  parameter integer C_INTERCONNECT_M_AXI_WRITE_ISSUING = 0,
  parameter integer C_M_AXI_SUPPORTS_READ              = 0,
  parameter integer C_M_AXI_SUPPORTS_WRITE             = 1,
  parameter integer C_M_AXI_TARGET                     = 0,
  parameter integer C_M_AXI_BURST_LEN                  = 0,
  parameter integer C_OFFSET_WIDTH                     = 0
) (
  // System Signals
  input wire        ACLK,
  input wire        ARESETN,

  // Master Interface Write Address
  output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_AWID,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]         M_AXI_AWADDR,
  output wire [8-1:0]                          M_AXI_AWLEN,
  output wire [3-1:0]                          M_AXI_AWSIZE,
  output wire [2-1:0]                          M_AXI_AWBURST,
  output wire [2-1:0]                          M_AXI_AWLOCK,
  output wire [4-1:0]                          M_AXI_AWCACHE,
  output wire [3-1:0]                          M_AXI_AWPROT,
  // AXI3 output wire [4-1:0]                  M_AXI_AWREGION,
  output wire [4-1:0]                          M_AXI_AWQOS,
  output wire [C_M_AXI_AWUSER_WIDTH-1:0]       M_AXI_AWUSER,
  output wire                                  M_AXI_AWVALID,
  input  wire                                  M_AXI_AWREADY,

  // Master Interface Write Data
  // AXI3 output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]     M_AXI_WID,
  output wire [C_M_AXI_DATA_WIDTH-1:0]         M_AXI_WDATA,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]       M_AXI_WSTRB,
  output wire                                  M_AXI_WLAST,
  output wire [C_M_AXI_WUSER_WIDTH-1:0]        M_AXI_WUSER,
  output wire                                  M_AXI_WVALID,
  input  wire                                  M_AXI_WREADY,

  // Master Interface Write Response
  input  wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_BID,
  input  wire [2-1:0]                          M_AXI_BRESP,
  input  wire [C_M_AXI_BUSER_WIDTH-1:0]        M_AXI_BUSER,
  input  wire                                  M_AXI_BVALID,
  output wire                                  M_AXI_BREADY,

  // Master Interface Read Address
  output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_ARID,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]         M_AXI_ARADDR,
  output wire [8-1:0]                          M_AXI_ARLEN,
  output wire [3-1:0]                          M_AXI_ARSIZE,
  output wire [2-1:0]                          M_AXI_ARBURST,
  output wire [2-1:0]                          M_AXI_ARLOCK,
  output wire [4-1:0]                          M_AXI_ARCACHE,
  output wire [3-1:0]                          M_AXI_ARPROT,
  // AXI3 output wire [4-1:0]                  M_AXI_ARREGION,
  output wire [4-1:0]                          M_AXI_ARQOS,
  output wire [C_M_AXI_ARUSER_WIDTH-1:0]       M_AXI_ARUSER,
  output wire                                  M_AXI_ARVALID,
  input  wire                                  M_AXI_ARREADY,

  // Master Interface Read Data
  input  wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_RID,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]         M_AXI_RDATA,
  input  wire [2-1:0]                          M_AXI_RRESP,
  input  wire                                  M_AXI_RLAST,
  input  wire [C_M_AXI_RUSER_WIDTH-1:0]        M_AXI_RUSER,
  input  wire                                  M_AXI_RVALID,
  output wire                                  M_AXI_RREADY,

  /* 割り込み */
  output              CAP_IRQ,

  /* 解像度切り替え */
  input   [1:0]       RESOL,

  /* カメラ信号 */
  input               PCLK, HREF, VSYNC,
  input   [7:0]       CAMDATA,

  /* レジスタバス */
  input   [15:0]      WRADDR,
  input   [3:0]       BYTEEN,
  input               WREN,
  input   [31:0]      WDATA,
  input   [15:0]      RDADDR,
  input               RDEN,
  output  [31:0]      RDATA,

  /* FIFOフラグ（LED[3]、LED[2]にそれぞれ接続している */
  output              CAP_FIFO_OVER, CAP_FIFO_UNDER
);

/*******************************************************************/

/* VRAM制御部のAWADDRにVRAMCTRL_AWADDRを接続することで */
/* アクセス範囲を0x20000000～0x3FFFFFFFに限定する      */
wire    [31:0] VRAMCTRL_AWADDR;
assign M_AXI_AWADDR = {3'b001, VRAMCTRL_AWADDR[28:0]};

/* とりあえず0固定しておくが、自由に使っていい */
assign CAP_FIFO_OVER  = 1'b0;   // LED[3]
assign CAP_FIFO_UNDER = 1'b0;   // LED[2]

/*******************************************************************/
/* AXI信号の初期化 */

assign M_AXI_AWLEN   = 8'd15;   // 16 burst
assign M_AXI_AWSIZE  = 3'b011;  // 8 byte

// 以下，COJTでは固定

assign M_AXI_AWID    = 1'd0;
assign M_AXI_AWBURST = 2'b01;
assign M_AXI_AWLOCK  = 2'b00;
assign M_AXI_AWCACHE = 4'b0011;
assign M_AXI_AWPROT  = 3'd0;
assign M_AXI_AWQOS   = 4'd0;
assign M_AXI_AWUSER  = 1'd0;

assign M_AXI_WSTRB   = 8'hFF;
assign M_AXI_WUSER   = 8'h00;

assign M_AXI_ARID    = 1'd0;
assign M_AXI_ARADDR  = 32'd0;
assign M_AXI_ARLEN   = 8'd0;
assign M_AXI_ARSIZE  = 3'd0;
assign M_AXI_ARBURST = 2'd0;
assign M_AXI_ARLOCK  = 2'd0;
assign M_AXI_ARCACHE = 4'b0011;
assign M_AXI_ARPROT  = 3'd0;
assign M_AXI_ARQOS   = 4'd0;
assign M_AXI_ARUSER  = 1'd0;
assign M_AXI_ARVALID = 1'd0;

assign M_AXI_RREADY  = 1'd0;

/*******************************************************************/
/* ACLKで同期化したリセット信号ARSTの作成 */

reg [1:0] arst_ff;

always @(posedge ACLK) begin
  arst_ff <= {arst_ff[0], ~ARESETN}
end

wire ARST = arst_ff[1];

/*******************************************************************/
/* wireの宣言 */

wire [28:0] cap_addr;
wire        cap_on;
wire [47:0] fifo_in;
wire        fifo_wr;
wire        fifo_rd;
wire        fifo_rst;
wire [47:0] fifo_dout;
wire        fifo_buf_over;
wire        fifo_buf_under;
wire [10:0] fifo_data_cnt;

/*******************************************************************/
/* FIFO */

fifo_48in48out_2048depth fifo_48in48out_2048depth (
 .rst           (fifo_rst),       // in
 .wr_clk        (PCLK),           // in
 .rd_clk        (ACLK),           // in
 .din           (fifo_in),        // in
 .wr_en         (fifo_wr),        // in
 .rd_en         (fifo_rd),        // in
 .dout          (fifo_dout),      // out
 .full          (),
 .overflow      (fifo_buf_over),  // out
 .empty         (),
 .underflow     (fifo_buf_under), // out
 .rd_data_count (fifo_data_cnt)   // out
);

/*******************************************************************/
/* キャプチャしたデータのデコーダ部 */

cap_decoder cap_decoder (
  .PCLK     (PCLK),     // in
  .PRST     (ARST),     // in
  .RESOL    (RESOL),    // in
  .CAMDATA  (CAMDATA),  // in
  .HREF     (HREF),     // in
  .VSYNC    (VSYNC),    // in
  .CAPON    (cap_on),   // in
  .FIFOIN   (fifo_in),  // out
  .FIFOWR   (fifo_wr),  // out
  .FIFORST  (fifo_rst)  // out
);

/*******************************************************************/
/* VRAM制御部 */

cap_vramctrl cap_vramctrl (
  .ACLK    (ACLK),                // in
  .ARST    (ARST),                // in
  .RESOL  (RESOL),                // in
  .CAPON (cap_on),                // in
  .CAPADDR (cap_addr),            // in
  .VSYNC (VSYNC),                 // in
  .AWADDR (VRAMCTRL_AWADDR),      // out
  .AWVALID (M_AXI_AWVALID),       // out
  .AWREADY (M_AXI_AWREADY),       // in
  .AWBURSTLEN (M_AXI_AWLEN),      // in
  .WDATA (M_AXI_WDATA),           // out
  .WVALID (M_AXI_WVALID),         // out
  .WREADY (M_AXI_WREADY),         // in
  .WLAST (M_AXI_WLAST),           // out
  .BRESP (M_AXI_BRESP),           // in
  .BVALID (M_AXI_BVALID),         // in
  .BREADY (M_AXI_BREADY),         // out
  .FIFO_DOUT (fifo_dout),         // in
  .FIFO_DATA_CNT (fifo_data_cnt), // in
  .FIFO_RD (fifo_rd),             // out
);

/*******************************************************************/
/* レジスタ制御部 */

cap_regctrl cap_regctrl (
  .ACLK (ACLK),                 // in
  .ARST (ARST),                 // in
  .VSYNC (VSYNC),               // in
  .WRADDR (WRADDR),             // in
  .BYTEEN (BYTEEN),             // in
  .WREN (WREN),                 // in
  .WDATA (WDATA),               // in
  .RDADDR (RDADDR),             // in
  .RDEN (RDEN),                 // in
  .RDATA (RDATA),               // out
  .CAPON (cap_on),              // out
  .CAPADDR (cap_addr),          // out
  .CAP_IRQ (CAP_IRQ),           // out
  .BUF_UNDER (fifo_buf_under),  // in
  .BUF_OVER (fifo_buf_over)     // in
);

/*******************************************************************/

endmodule
