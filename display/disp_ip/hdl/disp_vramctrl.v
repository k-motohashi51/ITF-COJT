module disp_vramctrl(
  // System Signals
  input                 ACLK,
  input                 ARST,
  
  // Read Address
  output  reg   [31:0]  ARADDR,
  output                ARVALID,
  input                 ARREADY,
  // Read Data 
  input                 RLAST,
  input                 RVALID,
  output                RREADY,

  /* �𑜓x�؂�ւ� */
  input         [1:0]   RESOL,

  /* ���u���b�N����̐M�� */
  input                 VRSTART,    // �\���J�n��1���C���O
  input                 DISPON,     // �\��ON
  input         [28:0]  DISPADDR,   // �\���A�h���X
  input                 BUF_WREADY  // FIFO���������݉\��
);

/*******************************************************************/
/* Avoid Meta Stable */

reg   [2:0] tmp;
wire  vrstart_posedge;

always @(posedge ACLK) begin
  if (ARST) begin
    tmp <= 3'd0;
  end else begin
    tmp[0] <= VRSTART;
    tmp[1] <= tmp[0];
    tmp[2] <= tmp[1];
  end
end

assign vrstart_posedge = (tmp[1] && !tmp[2]);

/*******************************************************************/
/* �g�����U�N�V�����̃J�E���^ */

localparam  BYTE_PER_BURST = 16'd256;  // 8byte * 32burst = 256

// 1��̃g�����U�N�V������2pixel * 32bust = 64pixel�����Ă���
// VGA�̏ꍇ�C1�s640pixel�Ȃ̂� 10��̃g�����U�N�V�����C�����480�s
localparam  ALL_TRANSACTION_VGA   = 16'd4800,
            ALL_TRANSACTION_XGA   = 16'd12288,
            ALL_TRANSACTION_SXGA  = 16'd20480;

reg [31:0] transaction;
wire is_all_transaction_complete;

always @(posedge ACLK) begin
  if (ARST) begin
    transaction <= 32'd0;
  end else if (CUR == S_IDLE) begin
    transaction <= 32'd0;
  end else if (is_ar_accept) begin
    transaction <= transaction + 32'd1;
  end
end

assign is_all_transaction_complete = (
  (RESOL == 2'd0 && transaction == ALL_TRANSACTION_VGA) ||
  (RESOL == 2'd1 && transaction == ALL_TRANSACTION_XGA) ||
  (RESOL == 2'd2 && transaction == ALL_TRANSACTION_SXGA)
);

/*******************************************************************/
/* AR Channel �X�e�[�g�}�V���̒�` */

localparam  S_IDLE     = 2'b00,
            S_SETADDR  = 2'b01,
            S_READ     = 2'b10,
            S_WAIT     = 2'b11;

reg [1:0] CUR, NXT;

always @(posedge ACLK) begin
  if (ARST) begin
    CUR <= S_IDLE;
  end else begin
    CUR <= NXT;
  end
end

/*******************************************************************/
/* AR Channel �X�e�[�g�}�V���̑J�� */

wire is_ar_accept = (ARVALID && ARREADY);
wire is_r_accpet  = (RVALID && RLAST);

always @* begin
  case (CUR)
    S_IDLE:
      if (DISPON && vrstart_posedge) begin
        NXT = S_SETADDR;  // 1��ʊJ�n
      end else begin
        NXT = S_IDLE;
      end

    S_SETADDR:
      if (is_ar_accept) begin
        NXT <= S_READ;  // �A�h���X���s�����C�g�����U�N�V�����J�n
      end else begin
        NXT <= S_SETADDR;
      end

    S_READ:
      if (is_r_accpet) begin
        if (is_all_transaction_complete) begin
          NXT <= S_IDLE;    // 1��ʏI��
        end else if (BUF_WREADY) begin
          NXT <= S_SETADDR;
        end else begin
          NXT <= S_WAIT;
        end
      end else begin
        NXT <= S_READ;
      end

    S_WAIT:
      if (BUF_WREADY) begin
        NXT <= S_SETADDR;   // FIFO�ɗ]�T���ł���
      end else begin
        NXT <= S_WAIT;
      end

    default:
      NXT <= S_IDLE;

  endcase
end

/*******************************************************************/
/* AR Channel */

always @(posedge ACLK) begin
  if (ARST) begin
    ARADDR <= 32'd0;
  end else if (NXT == S_SETADDR) begin
    ARADDR <= DISPADDR + transaction * BYTE_PER_BURST;
  end
end

assign ARVALID = (CUR == S_SETADDR);

/*******************************************************************/
/* R Channel */

assign RREADY = RVALID;

/*******************************************************************/

endmodule
