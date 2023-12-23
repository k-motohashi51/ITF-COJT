module cap_regctrl (
  input               ACLK,
  input               ARST,
  input               VSYNC,

  input       [15:0]  WRADDR,
  input       [3:0]   BYTEEN,
  input               WREN,
  input       [31:0]  WDATA,
  input       [15:0]  RDADDR,
  input               RDEN,
  output  reg [31:0]  RDATA,

  output  reg         CAPON,
  output  reg [28:0]  CAPADDR,

  output  reg         CAP_IRQ,
  input               BUF_UNDER,
  input               BUF_OVER
);

/*******************************************************************/
/* VSYNCの立ち下がり検出 */

reg [2:0] tmp;

always @(posedge ACLK) begin
  if (ARST) begin
    tmp <= 3'd0;
  end else begin
    tmp[0] <= VSYNC;
    tmp[1] <= tmp[0];
    tmp[2] <= tmp[1];
  end
end

wire vsync_neg = tmp[2] && !tmp[1];

/*******************************************************************/
/* 制御するレジスタの選択 */

// 自ブロックに対する書き込みかどうかを判断して，WRADDRを判断
wire  is_capture_block  = (WREN && WRADDR[15:12] == 4'd1);
wire  is_capaddr_reg    = (is_capture_block && WRADDR[11:2] == 10'd0);
wire  is_capctrl_reg    = (is_capture_block && WRADDR[11:2] == 10'd1);
wire  is_capint_reg     = (is_capture_block && WRADDR[11:2] == 10'd2);
wire  is_capfifo_reg    = (is_capture_block && WRADDR[11:2] == 10'd3);

/*******************************************************************/
/* CAPADDRレジスタ */

always @(posedge ACLK) begin
  if (ARST) begin
    CAPADDR <= 29'd0;
  end else if (is_capaddr_reg) begin
    if (BYTEEN[0]) CAPADDR[ 7: 0] <= WDATA[ 7: 0];
    if (BYTEEN[1]) CAPADDR[15: 8] <= WDATA[15: 8];
    if (BYTEEN[2]) CAPADDR[23:16] <= WDATA[23:16];
    if (BYTEEN[3]) CAPADDR[28:24] <= WDATA[28:24];
  end
end

/*******************************************************************/
/* CAPCTRLレジスタ */

always @(posedge ACLK) begin
  if (ARST) begin
    CBLANK <= 1'b0;
  end else if (V_NEGEDGE) begin
    CBLANK <= 1'b1;
  end else if (is_capctrl_reg && BYTEEN[0] && WDATA[1]) begin
    CBLANK <= 1'b0;        
  end
end

always @(posedge ACLK) begin
  if (ARST) begin
    CAPON <= 1'b0;
  end else if (is_capctrl_reg && BYTEEN[0]) begin
    CAPON <= WDATA[0];
  end
end

/*******************************************************************/
/* CAPINTレジスタ */

always @(posedge ACLK) begin
  if (ARST) begin
    INTENBL <= 1'b0;
  end else if (is_capint_reg && BYTEEN[0]) begin
    INTENBL <= WDATA[0];
  end
end

/*******************************************************************/
/* CAPFIFOレジスタ */

always @(posedge ACLK) begin
  if (ARST) begin
    FIFOOVER <= 1'b0;
  end else if (BUF_OVER) begin
    FIFOOVER <= 1'b1;
  end else if (is_capfifo_reg && BYTEEN[0] && WDATA[1]) begin
    FIFOOVER <= 1'b0;
  end
end

always @(posedge ACLK) begin
  if (ARST) begin
    FIFOUNDER <= 1'b0;
  end else if (BUF_UNDER) begin
    FIFOUNDER <= 1'b1;
  end else if (is_capfifo_reg && BYTEEN[0] && WDATA[0]) begin
    FIFOUNDER <= 1'b0;
  end
end

/*******************************************************************/
/* レジスタの値を連結して出力 */

always @(posedge ACLK) begin
  if (ARST) begin
    RDATA <= 32'd0;
  end else if (RDEN && !RDADDR[15:12]) begin
    if (RDADDR[11:2] == 10'd0) RDATA <= { 3'd0, CAPADDR};
    if (RDADDR[11:2] == 10'd1) RDATA <= {30'd0, CBLANK, CAPON};
    if (RDADDR[11:2] == 10'd2) RDATA <= {31'd0, INTENBL};
    if (RDADDR[11:2] == 10'd3) RDATA <= {30'd0, FIFOOVER, FIFOUNDER};
  end
end

/*******************************************************************/
/* CAP_IRQの生成 */

always @(posedge ACLK) begin
  if (ARST) begin
    CAP_IRQ <= 1'b0;
  end else if (INTENBL && V_NEGEDGE) begin
    CAP_IRQ <= 1'b1;
  end else if (is_capint_reg && WDATA[1]) begin
    CAP_IRQ <= 1'b0;
  end
end

/*******************************************************************/

endmodule