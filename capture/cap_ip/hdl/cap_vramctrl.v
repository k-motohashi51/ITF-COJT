module cap_vramctrl (
  input               ACLK,
  input               ARST,
  input       [1:0]   RESOL,
  input               CAPON,
  input       [28:0]  CAPADDR,
  input               VSYNC,

  // AXI: AWチャネル
  output  reg [31:0]  AWADDR,
  output              AWVALID,
  input               AWREADY,
  input       [7:0]   AWBURSTLEN,

  // AXI: Wチャネル
  output      [63:0]  WDATA,
  output              WVALID,
  input               WREADY,
  output              WLAST,

  // AXI: Bチャネル
  input       [1:0]   BRESP
  input               BVALID,
  output              BREADY,

  // FIFO
  input       [47:0]  FIFO_DOUT,
  input       [10:0]  FIFO_DATA_CNT,
  output              FIFO_RD,
);

/*******************************************************************/
/* 必要なregやwireの宣言 */

// 1トランザクションで転送するデータの合計バイト数
localparam  BYTE_PER_BURST = 32'd128; // 8 byte * 16 burst

// AWチャネルステートマシンの状態
localparam  S_AW_IDLE     = 2'b00,
            S_AW_SETADDR  = 2'b01,
            S_AW_WAIT     = 2'b10;

// Wチャネルステートマシンの状態
localparam  S_W_IDLE  = 2'b00,
            S_W_WRITE = 2'b01,
            S_W_WAIT  = 2'b10,
            S_W_FIFO  = 2'b11;

reg [1:0]   AW_CUR, AW_NXT;
reg [1:0]   W_CUR, W_NXT;

reg [31:0]  transaction;              // トランザクション回数のカウンタ
reg         is_transaction_complete;  // 1画面分のトランザクションが終わったかどうか
reg [7:0]   data_cnt;                 // 1トランザクション間で書込みデータのカウンタ

wire vsync_rst; // VSYNCによるリセット

wire is_fifo_enough = (FIFO_DATA_CNT >= AWBURSTLEN + 8'd1);

// AXIのチャネルのやりとり検知を簡単に扱うためのwire
wire is_aw_accept     = (AWVALID && AWREADY);
wire is_w_accept      = (WVALID && WREADY);
wire is_w_all_accept  = (WVALID && WREADY && WLAST);
wire is_b_accept      = (BVALID && BREADY);

/*******************************************************************/
/* VSYNCによるリセット */

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

assign vsync_rst = tmp[1] && !tmp[2];

/*******************************************************************/
/* トランザクション回数のカウンタ */

always @(posedge ACLK) begin
  if (ARST || vsync_rst) begin
    transaction <= 32'd0;
  end else if (AW_CUR == S_AW_IDLE) begin
    transaction <= 32'd0;
  end else if (AW_CUR == S_AW_SETADDR) begin
    if (is_aw_accept) begin
      transaction <= transaction + 32'd1;
    end
  end
end

/*******************************************************************/
/* トランザクションが1画面分行われたかどうか */

always @(posedge ACLK) begin
  if (ARST) begin
    is_transaction_complete <= 1'd0;
  end else if (is_b_accept) begin
    is_transaction_complete <= 1'd1;
  end else if (is_aw_accept) begin
    is_transaction_complete <= 1'd0;
  end
end

/*******************************************************************/
/* 1トランザクション間でWチャネルに渡したデータのカウンタ */

always @(posedge ACLK) begin
  if (ARST || vsync_rst) begin
    data_cnt <= 8'd0;
  end else if (W_CUR == S_W_WRITE && is_w_all_accept) begin
    data_cnt <= 8'd0;
  end else if (W_CUR == S_W_WRITE && is_w_accept) begin
    data_cnt <= data_cnt + 8'd1;
  end
end

/*******************************************************************/
/* AWチャネルステートマシン */

always @(posedge ACLK) begin
  if (ARST || vsync_rst) begin
    AW_CUR <= S_AW_IDLE;
  end else begin
    AW_CUR <= AW_NXT;
  end
end

always @* begin
  case (AW_CUR)
    S_AW_IDLE:
      if (CAPON && is_fifo_enough) begin
        AW_NXT <= S_AW_SETADDR;
      end else begin
        AW_NXT <= S_AW_IDLE;
      end

    S_AW_SETADDR:
      if (is_aw_accept) begin
        AW_NXT <= S_AW_WAIT;
      end else begin
        AW_NXT <= S_AW_SETADDR;
      end

    S_AW_WAIT:
      if (is_transaction_complete && is_fifo_enough) begin
        AW_NXT <= S_AW_SETADDR;
      end else begin
        AW_NXT <= S_AW_WAIT;
      end

    default:
      AW_NXT <= S_AW_IDLE;
  endcase
end

/*******************************************************************/
/* Wチャネルステートマシン */

always @(posedge ACLK) begin
  if (ARST || vsync_rst) begin
    W_CUR <= S_W_IDLE;
  end else begin
    W_CUR <= W_NXT;
  end
end

always @* begin
  case (W_CUR)
    S_W_IDLE:
      if (CAPON && is_fifo_enough) begin
        W_NXT <= S_W_WRITE;
      end else begin
        W_NXT <= S_W_IDLE;
      end

    S_W_WRITE:  
      if (is_w_all_accept) begin
        W_NXT <= S_W_WAIT;
      end else begin
        W_NXT <= S_W_WRITE;
      end

    S_W_WAIT:
      if (is_b_accept) begin
        W_NXT <= (is_fifo_enough) ? S_W_WRITE : S_W_FIFO;
      end else begin
        W_NXT <= S_W_WAIT;
      end
      
    S_W_FIFO:
      if (is_fifo_enough) begin
        W_NXT <= S_W_WRITE;
      end else begin
        W_NXT <= S_W_FIFO;
      end

    default:
      W_NXT <= S_W_IDLE;
  endcase
end

/*******************************************************************/
/* AWチャネルの出力 */

assign AWVALID  = (AW_CUR == S_AW_SETADDR);

always @(posedge ACLK) begin
  if (ARST || vsync_rst) begin
    AWADDR <= 32'd0;
  end else if (AW_NXT == S_AW_SETADDR) begin
    if (AW_CUR == S_AW_IDLE || AW_CUR == S_AW_WAIT) begin
      AWADDR <= {3'd0 + CAPADDR[28:0]} + transaction * BYTE_PER_BURST; 
    end
  end
end

/*******************************************************************/
/* Wチャネルの出力 */

assign WDATA  = {8'd0, FIFO_DOUT[47:24], 8'd0, FIFO_DOUT[23:0]};
assign WLAST  = (data_cnt == AWBURSTLEN);
assign WVALID = (W_CUR == S_W_WRITE);

/*******************************************************************/
/* Bチャネルの出力 */

assign BREADY = 1'd1;

/*******************************************************************/
/* FIFOの読み出し信号 */

assign FIFO_RD  =   (W_CUR == S_W_WRITE && WREADY && !WLAST)
                ||  (W_CUR != S_W_WRITE && W_NXT == S_W_WRITE);

/*******************************************************************/

endmodule