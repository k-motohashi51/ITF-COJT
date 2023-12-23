//-----------------------------------------------------------------------------
// Title       : decoder�̃e�X�g�x���`
// Project     : capture
// Filename    : tb_decoder.v
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/04/17  1.00     M.Kobayashi   Created
// 2015/03/12  1.10     M.Kobayashi   �J�������f���؂�ւ��ɑΉ�
// 2023/02/15  1.20     M.Kobayashi   �𑜓x�؂�ւ��ɑΉ�
//-----------------------------------------------------------------------------


`timescale 1ns/1ps

module tb_decoder;

reg             PRST, CAPON;
wire            PCLK, HREF, VSYNC;
wire    [7:0]   CAMDATA;
reg     [1:0]   RESOL;

wire            FIFOWR, FIFORST;
wire    [47:0]  FIFOIN;

/* �e��萔 */
localparam integer STEP = 30;

localparam P_RESOL_VGA  = 2'b00;
localparam P_RESOL_XGA  = 2'b01;
localparam P_RESOL_SXGA = 2'b10;

/* �V�~�����[�V��������𑜓x�̐ݒ�i������؂�ւ��čēx�V�~�����[�V��������j */
localparam SIM_RESOL = P_RESOL_VGA;

/* �ŏ��Ƀ}�N����`�𖢒�`�ɂ��Ă��� */
`undef CAM_INCR
`undef CAM_PICT

/* �����̃}�N����`��ύX���ăJ�������f����؂�ւ��ăV�~�����[�V�������Ă݂� */
`define CAM_INCR  // CAM_INCR: �C���N�������g�^�C�v(camera.v)�ACAM_PICT: ���ʉ摜(camera2.v)

/* �J�������f���ڑ� */
reg CAM_ENABLE;
`ifdef CAM_INCR
  camera
`else
  camera2
`endif
    camera (
    .PCLK       (PCLK),
    .HREF       (HREF),
    .VSYNC      (VSYNC),
    .CAMDATA    (CAMDATA),
    .ENABLE     (CAM_ENABLE),
    .RESOL      (RESOL)
);

/* �f�R�[�_�ڑ� */
cap_decoder cap_decoder (
    .PRST       (PRST),
    .CAPON      (CAPON),
    .PCLK       (PCLK),
    .HREF       (HREF),
    .VSYNC      (VSYNC),
    .CAMDATA    (CAMDATA),
    .RESOL      (RESOL),
    .FIFOIN     (FIFOIN),
    .FIFOWR     (FIFOWR),
    .FIFORST    (FIFORST)
);

integer fd, vflag;

initial begin
    vflag = 0;
    fd = $fopen("imagedata.txt");
    RESOL = SIM_RESOL; CAM_ENABLE = 0; CAPON = 0;
    #STEP;
    PRST = 1;
    #(STEP*10);
    PRST = 0; CAM_ENABLE = 1; CAPON = 1;
    @(negedge VSYNC);
    @(negedge VSYNC);
    $fclose(fd);
    $stop;
end


always @(posedge PCLK) begin
    if ( FIFOWR ) begin
        $fdisplay(fd, "%06x", FIFOIN[23:0] );
        $fdisplay(fd, "%06x", FIFOIN[47:24]);
        vflag = 1;
    end
    else if ( VSYNC && vflag==1 ) begin
        $fdisplay(fd, "vsync");
        vflag = 0;
    end
end

endmodule
