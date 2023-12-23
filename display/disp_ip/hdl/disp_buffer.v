module disp_buffer(
  // System Signals
  input               ACLK,
  input               ARST,

  /* 表示クロック、リセット */
  input               DCLK,
  input               DRST,

  /* FIFO関連信号 */
  input               DISPON,
  input               FIFORST,
  input   [63:0]      FIFOIN,
  input               FIFOWR,     
  input               DSP_preDE,
  output              BUF_WREADY,
  output              BUF_OVER,
  output              BUF_UNDER,

  /* 画像出力 */
  output  reg [7:0]   DSP_R, DSP_G, DSP_B,
  output  reg         DSP_DE
); 

/*******************************************************************/
/* FIFO */

wire [23:0] fifo_dout;
wire [9:0]  fifo_dout_cnt;
wire        is_fifo_valid;

fifo_48in24out_1024depth fifo_48in24out_1024depth(
  .rst          (FIFORST),
  .wr_clk       (ACLK),
  .rd_clk       (DCLK),
  .din          ({FIFOIN[23:0], FIFOIN[55:32]}),
  .wr_en        (FIFOWR),
  .rd_en        (DISPON && DSP_preDE),
  .dout         (fifo_dout),
  .full         (),
  .overflow     (BUF_OVER),
  .empty        (),
  .valid        (is_fifo_valid),
  .underflow    (BUF_UNDER),
  .wr_data_count(fifo_dout_cnt)
);

/*******************************************************************/
/* DSP_preDEの2クロック後であるDSP_DEを生成 */

reg dsp_inter_de;

always @(posedge DCLK) begin
  if (DRST) begin
    dsp_inter_de <= 1'd0;
  end else begin
    dsp_inter_de <= DSP_preDE;
  end
end

always @(posedge DCLK) begin
  if (DRST) begin
    DSP_DE <= 1'd0;
  end else begin
    DSP_DE <= dsp_inter_de;
  end
end

/*******************************************************************/
/* FIFOからの読み出しデータの出力 */

always @(posedge DCLK) begin
  if (DRST) begin
    DSP_R <= 8'd0;
    DSP_G <= 8'd0;
    DSP_B <= 8'd0;
  end else if (dsp_inter_de) begin
    DSP_R <= fifo_dout[23:16];
    DSP_G <= fifo_dout[15:8];
    DSP_B <= fifo_dout[7:0];
  end else if (dsp_inter_de && !DISPON) begin
    DSP_R <= 8'd0;
    DSP_G <= 8'd0;
    DSP_B <= 8'd0;
  end
end

/*******************************************************************/
/* BUF_WREADYの生成 */

// 残容量が256以上の時に書き込み可能
// 今回はFIFOの深さは1024なので，1024-256=768以上の時に書き込み可能
assign BUF_WREADY = (fifo_dout_cnt < 10'd1024 - 10'd256) ? 1'b1 : 1'b0;

endmodule
