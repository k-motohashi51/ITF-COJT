module cap_decoder (
  input           PCLK,
  input           PRST,

  input [1:0]     RESOL,
  input [7:0]     CAMDATA,
  input           HREF,     // 画像が有効かどうか
  input           VSYNC,
  input           CAPON,    // キャプチャ動作中

  output  [47:0]  FIFOIN,
  output          FIFOWR,
  output          FIFORST
);

/*******************************************************************/
/* PCLKの立ち上がりで画像やHREFなどを取り込む */

reg       href_ff;
reg       vsync_ff;
reg [7:0] camdata_ff;

always @(posedge PCLK) begin
  if (PRST || vsync_ff) begin
    href_ff <= 1'd0;
  end else begin
    href_ff <= HREF;
  end
end

always @(posedge PCLK) begin
  if (PRST) begin
    vsync_ff <= 1'd0;
  end else begin
    vsync_ff <= VSYNC;
  end
end

always @(posedge PCLK) begin
  if (PRST || vsync_ff) begin
    camdata_ff <= 8'd0;
  end else begin
    camdata_ff <= CAMDATA;
  end
end

/*******************************************************************/
/* 取得する画像の水平カウンタ */

localparam  WIDTH_VGA = 12'd640,
            WIDTH_XGA = 12'd1024,
            WIDTH_SXGA = 12'd1280;

reg   [11:0]  hcnt;
wire  [11:0]  hcnt_start;
wire  [11:0]  hcnt_end;
wire          is_hcnt_valid;

always @(posedge PCLK) begin
  if (PRST || vsync_ff) begin
    hcnt <= 12'd0;
  end else if (href_ff) begin
    hcnt <= hcnt + 12'd1;
  end else begin
    hcnt <= 12'd0;
  end
end

// 画像の水平カウンタの範囲設定 (XGAだけはSXGAのトリミング)
assign hcnt_start = (RESOL == 2'd0) ? 12'd0
                  : (RESOL == 2'd1) ? 12'd256
                  : 12'd0;

assign hcnt_end = (RESOL == 2'd0) ? WIDTH_VGA + WIDTH_VGA
                : (RESOL == 2'd1) ? 12'd256 + WIDTH_XGA + WIDTH_XGA
                : WIDTH_SXGA + WIDTH_SXGA;

assign is_hcnt_valid = ((hcnt_start <= hcnt) && (hcnt < hcnt_end));

/*******************************************************************/
/* 取得する画像の垂直カウンタ */

localparam  HEIGHT_VGA = 12'd480,
            HEIGHT_XGA = 12'd768,
            HEIGHT_SXGA = 12'd1024;

reg   [11:0]  vcnt;
wire  [11:0]  vcnt_start;
wire  [11:0]  vcnt_end;
wire          is_vcnt_valid;

always @(posedge PCLK) begin
  if (PRST || vsync_ff) begin
    vcnt <= 12'd0;
  end else if (href_ff && hcnt == hcnt_end) begin
    vcnt <= vcnt + 12'd1;
  end else if (vcnt == vcnt_end) begin
    vcnt <= 12'd0;
  end
end

// 画像の垂直カウンタの範囲設定 (XGAだけはSXGAのトリミング)
assign vcnt_start = (RESOL == 2'd0) ? 12'd0
                  : (RESOL == 2'd1) ? 12'd256
                  : 12'd0;

assign vcnt_end = (RESOL == 2'd0) ? HEIGHT_VGA + HEIGHT_VGA
                : (RESOL == 2'd1) ? 12'd256 + HEIGHT_XGA + HEIGHT_XGA
                : HEIGHT_SXGA + HEIGHT_SXGA;

assign is_vcnt_valid = ((vcnt_start <= vcnt) && (vcnt < vcnt_end));

/*******************************************************************/
/* 色データ取得 */

// 下位2bitで色データを把握する
localparam  LSB_U0 = 2'b00,
            LSB_Y0 = 2'b01,
            LSB_V0 = 2'b10,
            LSB_Y1 = 2'b11; 

reg [7:0] u0, y0, v0, y1;

always @(posedge PCLK) begin
  if (PRST || vsync_ff) begin
    u0 <= 8'd0;  
    y0 <= 8'd0;  
    v0 <= 8'd0;  
    y1 <= 8'd0;  
  end else if (CAPON) begin
    case (hcnt[1:0])
      LSB_U0: u0 <= camdata_ff;
      LSB_Y0: y0 <= camdata_ff;
      LSB_V0: v0 <= camdata_ff;
      LSB_Y1: y1 <= camdata_ff;
    endcase
  end
end

wire is_yuv_valid = (hcnt[1:0] == LSB_Y1);

/*******************************************************************/
/* 色変換 */

wire [7:0]  r0, g0, b0;
wire [7:0]  r1, g1, b1;
wire [18:0] trans_common_0;
wire [18:0] trans_common_1;
wire [18:0] trans_r0, trans_g0, trans_b0;
wire [18:0] trans_r1, trans_g1, trans_b1;

assign trans_common_0 = (19'd298 * y0 - 19'd4769);
assign trans_common_1 = (19'd298 * y0 - 19'd4769);

assign trans_r0 = (trans_common_0   + (19'd409 * v0 - 19'd52299));
assign trans_g0 = (trans_common_0   - (19'd100 * u0 - 19'd12832)
                                    - (19'd208 * v0 - 19'd26634));
assign trans_b0 = (trans_common_0   + (19'd516 * u0 - 19'd66101));

assign trans_r1 = (trans_common_1   + (19'd409 * v0 - 19'd52299));
assign trans_g1 = (trans_common_1   - (19'd100 * u0 - 19'd12832)
                                    - (19'd208 * v0 - 19'd26634));
assign trans_b1 = (trans_common_1   + (19'd516 * u0 - 19'd66101));

assign r0 = (trans_r0[18])  ? 8'd0
          : (trans_r0[17] || trans_r0[16])  ? 8'd255
          : trans_r0[15:8];

assign g0 = (trans_g0[18])  ? 8'd0
          : (trans_g0[17] || trans_g0[16])  ? 8'd255
          : trans_g0[15:8];

assign b0 = (trans_b0[18])  ? 8'd0
          : (trans_b0[17] || trans_b0[16])  ? 8'd255
          : trans_b0[15:8];

assign r1 = (trans_r1[18])  ? 8'd0
          : (trans_r1[17] || trans_r1[16])  ? 8'd255
          : trans_r1[15:8];

assign g1 = (trans_g1[18])  ? 8'd0
          : (trans_g1[17] || trans_g1[16])  ? 8'd255
          : trans_g1[15:8];

assign b1 = (trans_b1[18])  ? 8'd0
          : (trans_b1[17] || trans_b1[16])  ? 8'd255
          : trans_b1[15:8];

/*******************************************************************/
/* FIFO関連 */

assign FIFOIN   = {r1, g1, b1, r0, g0, b0};
assign FIFOWR   = (is_hcnt_valid && is_vcnt_valid && is_yuv_valid && CAPON);
assign FIFORST  = (PRST || vsync_ff);

/*******************************************************************/

endmodule