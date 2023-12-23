module disp_regctrl (
  // System Signals
  input               ACLK,
  input               ARST,

  /* VSYNC */
  input               DSP_VSYNC_X,

  /* レジスタバス */
  input       [15:0]  WRADDR,
  input       [3:0]   BYTEEN,
  input               WREN,
  input       [31:0]  WDATA,
  input       [15:0]  RDADDR,
  input               RDEN,
  // output  reg [31:0]  RDATA,
  output      [31:0]  RDATA,

  /* レジスタ出力 */
  output  reg         DISPON,
  // output  reg [28:0]  DISPADDR,
  output      [28:0]  DISPADDR,

  /* 割り込み、FIFOフラグ */
  // output  reg         DSP_IRQ,
  output              DSP_IRQ,
  input               BUF_UNDER,
  input               BUF_OVER
); 

/*******************************************************************/
/* 表示回路1用 */

assign RDATA = 32'b0;
assign DISPADDR = 29'h0;
assign DSP_IRQ = 1'b0;

/* 以下の記述はそのまま使用可 */
wire    write_reg  = WREN && WRADDR[15:12]==4'h0;
wire    ctrlreg_wr = (write_reg && WRADDR[11:2]==10'h001 && BYTEEN[0]);

// コントロールレジスタ（DISPCTRL）・・DISPON
always @( posedge ACLK ) begin
  if ( ARST )
    DISPON <= 1'b0;
  else if ( ctrlreg_wr )
    DISPON <= WDATA[0];
end

/*******************************************************************/
/* Avoid Meta Stable */

/*
reg   [2:0] tmp;
wire        dsp_vsync_x_negedge;

always @(posedge ACLK) begin
  if (ARST) begin
    tmp <= 3'd0;
  end else begin
    tmp[0] <= DSP_VSYNC_X;
    tmp[1] <= tmp[0];
    tmp[2] <= tmp[1];
  end
end

assign dsp_vsync_x_negedge = (!tmp[1] && tmp[2]);
*/

/*******************************************************************/
/* レジスタバスの定義 */

/*
wire  is_display_block  = (WREN && WRADDR[15:12] == 4'd0);
wire  is_dispaddr_reg   = (is_display_block && WRADDR[11:2]==10'd0);
wire  is_dispctrl_reg   = (is_display_block && WRADDR[11:2]==10'd1);
wire  is_dispint_reg    = (is_display_block && WRADDR[11:2]==10'd2);
wire  is_dispfifo_reg   = (is_display_block && WRADDR[11:2]==10'd3);

reg   VBLANK;
reg   INTENBL;
reg   FIFOOVER;
reg   FIFOUNDER;
*/

/*******************************************************************/
/* DISPADDR */

/*
always @(posedge ACLK) begin
  if (ARST) begin
    DISPADDR <= 28'd0;
  end else if (is_dispaddr_reg) begin
    if (BYTEEN[0]) DISPADDR[7:0]   <= WDATA[7:0];
    if (BYTEEN[1]) DISPADDR[15:8]  <= WDATA[15:8];
    if (BYTEEN[2]) DISPADDR[23:16] <= WDATA[23:16];
    if (BYTEEN[3]) DISPADDR[27:24] <= WDATA[27:24];
  end
end
*/

/*******************************************************************/
/* DISPCTRL */

/*
always @(posedge ACLK) begin
  if (ARST) begin
      VBLANK <= 1'b0;
  end else if (dsp_vsync_x_negedge) begin
      VBLANK <= 1'b1;
  end else if (is_dispctrl_reg && BYTEEN[0] && WDATA[1]) begin
      VBLANK <= 1'b0;        
  end
end

always @(posedge ACLK) begin
  if (ARST) begin
    DISPON <= 1'b0;
  end else if (is_dispctrl_reg && BYTEEN[0]) begin
    DISPON <= WDATA[0];
  end
end
*/

/*******************************************************************/
/* DISPINT */

/*
always @(posedge ACLK) begin
  if (ARST) begin
    INTENBL <= 1'b0;
  end else if (is_dispint_reg && BYTEEN[0]) begin
    INTENBL <= WDATA[0];
  end
end

always @(posedge ACLK) begin
  if (ARST) begin
    DSP_IRQ <= 1'b0;
  end else if (dsp_vsync_x_negedge && INTENBL) begin
    DSP_IRQ <= 1'b1;
  end else if (is_dispint_reg && WDATA[1]) begin
    DSP_IRQ <= 1'b0;
  end
end
*/

/*******************************************************************/
/* DISPFIFO */

/*
always @(posedge ACLK) begin
  if (ARST) begin
    FIFOUNDER <= 1'b0;
  end else if (BUF_UNDER) begin
    FIFOUNDER <= 1'b1;
  end else if (dispfifo_wr && BYTEEN[0] && WDATA[0]) begin
    FIFOUNDER <= 1'b0;
  end
end

always @(posedge ACLK) begin
  if (ARST) begin
    FIFOOVER <= 1'b0;
  end else if (BUF_OVER) begin
    FIFOOVER <= 1'b1;
  end else if (is_dispint_reg && BYTEEN[0] && WDATA[1]) begin
    FIFOOVER <= 1'b0;
  end
end
*/

/*******************************************************************/
/* Read from Config Register. */

/*
always @(posedge ACLK) begin
  if (ARST) begin
    RDATA <= 32'd0;
  end else if (RDEN && !RDADDR[15:12]) begin
    if (RDADDR[11:2] == 10'd0) RDATA <= { 3'd0, DISPADDR};
    if (RDADDR[11:2] == 10'd1) RDATA <= {30'd0, VBLANK, DISPON};
    if (RDADDR[11:2] == 10'd2) RDATA <= {31'd0, INTENBL};
    if (RDADDR[11:2] == 10'd3) RDATA <= {30'd0, FIFOOVER, FIFOUNDER};
  end
end
*/

/*******************************************************************/

endmodule
