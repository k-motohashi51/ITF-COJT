//-----------------------------------------------------------------------------
// Title       : �L���v�`����H�S�̌��؃e�X�g�x���`
// Project     : capture
// Filename    : tb_capture_all.sv
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2023/01/16  1.00     M.Kobayashi   VIP���p�A�eREADY�����_�����ASystemVerilog
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

`define VIPINST  dut.design_1_i.axi_vip_0.inst

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module tb_capture_all;

/* �e��萔 */
localparam integer STEP  = 8;
localparam integer DSTEP = 40;

localparam P_RESOL_VGA  = 2'b00;
localparam P_RESOL_XGA  = 2'b01;
localparam P_RESOL_SXGA = 2'b10;

/* �V�~�����[�V��������𑜓x�̐ݒ�i������؂�ւ��čēx�V�~�����[�V��������j */
localparam SIM_RESOL = P_RESOL_VGA;

/* �𑜓x�ɉ����đ���f����V�~�����[�V�����X�e�b�v����؂�ւ��� */
localparam PIX_NUMBER = (SIM_RESOL == P_RESOL_VGA) ? 640*480: (SIM_RESOL == P_RESOL_XGA) ? 1024*768: 1280*1024;
localparam SIMSTEP    = (SIM_RESOL == P_RESOL_VGA) ? 4500000: 12000000;


/* �V�X�e���n�M�� */
logic           ACLK;
logic           ARESETN;
logic           CAP_IRQ;
logic   [1:0]   RESOL;
logic           CAP_FIFO_OVER, CAP_FIFO_UNDER;

/* �摜�n�M�� */
logic           DCLK;
logic           DSP_IRQ;
logic   [7:0]   DSP_R, DSP_G, DSP_B;
logic           DSP_DE, DSP_HSYNC_X, DSP_VSYNC_X;
logic           DSP_FIFO_OVER, DSP_FIFO_UNDER;

/* �J�����M�� */
logic           PCLK, HREF, VSYNC;
logic   [7:0]   CAMDATA;

/* ���W�X�^�o�X */
logic   [15:0]  WRADDR;
logic   [3:0]   BYTEEN;
logic           WREN;
logic   [31:0]  WDATA;
logic   [15:0]  RDADDR;
logic           RDEN;
logic   [31:0]  RDATA_DISP;
logic   [31:0]  RDATA_CAPT;

/* DUT�̐ڑ� */
design_1_wrapper dut (.*);

/* �ŏ��Ƀ}�N����`�𖢒�`�ɂ��Ă��� */
`undef CAM_INCR
`undef CAM_PICT

/* �����̃}�N����`��ύX���ăJ�������f����؂�ւ��ăV�~�����[�V�������Ă݂� */
`define CAM_PICT  // CAM_INCR: �C���N�������g�^�C�v(camera.v)�ACAM_PICT: ���ʉ摜(camera2.v)

/* �J�������f���ڑ� */
logic CAM_ENABLE;
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

/* �e��N���b�N */
always begin
    ACLK = 0; #(STEP/2);
    ACLK = 1; #(STEP/2);
end

always begin
    DCLK = 0; #(DSTEP/2);
    DCLK = 1; #(DSTEP/2);
end

/* ���W�X�^�A�h���X */
localparam CAPADDR = 16'h1000;
localparam CAPCTRL = 16'h1004;
localparam CAPINT  = 16'h1008;
localparam CAPFIFO = 16'h100c;
localparam CBLANK = 32'h2;

localparam DISPADDR = 16'h0000;
localparam DISPCTRL = 16'h0004;
localparam DISPINT  = 16'h0008;
localparam DISPFIFO = 16'h000c;
localparam VBLANK = 32'h2;

/* ���W�X�^�������� */
task write_reg(
input [15:0] addr,
input [3:0]  byteen,
input [31:0] wdata );
begin
    WRADDR = addr;
    BYTEEN = byteen;
    WDATA = wdata;
    @(negedge ACLK);
    WREN = 1;
    @(negedge ACLK);
    WREN = 0;
end
endtask


/* VIP Slave�p�̃G�[�W�F���g��錾���X���[�u���N�� */
design_1_axi_vip_0_0_slv_mem_t agent;

task init_system();
    agent = new("AXI Slave Agent", `VIPINST.IF);
    agent.start_slave();
endtask

/* VRAM�̃A�h���X */
localparam MEMBASE = 32'h2000_0000;

/* �e�X�g�x���`�{�� */
integer fd, vflag;

initial begin
    RESOL = SIM_RESOL;
    vflag = 0;
    fd = $fopen("imagedata.txt");
    ARESETN = 1; WRADDR = 0; BYTEEN = 0;
    WREN = 0; WDATA = 0; RDEN = 0; RDADDR = 0;
    CAM_ENABLE = 0;
    #STEP;
    ARESETN = 0;
    #(STEP*100);
    ARESETN = 1; CAM_ENABLE = 1;
    #(STEP*100);

    init_system();
    user_gen_arready();
    user_gen_awready();
    user_gen_wready();

    write_reg(DISPADDR, 4'hf, 32'h0);
    write_reg(DISPCTRL, 4'hf, 32'h1);
    write_reg(CAPADDR,  4'hf, 32'h0);
    write_reg(CAPCTRL,  4'hf, 32'h1);

    #(STEP*SIMSTEP);
    $fclose(fd);
    $stop;
end

/* �V�~�����[�����ʉ摜�𕶎��t�@�C���ŏo�� */
always @(posedge DCLK) begin
    if ( DSP_DE ) begin
        $fdisplay(fd, "%06x", {DSP_R, DSP_G, DSP_B});
        vflag = 1;
    end
    else if ( DSP_VSYNC_X==0 && vflag==1 ) begin
        $fdisplay(fd, "vsync");
        vflag = 0;
    end
end

/* ARREADY�̋����������_���� */
task user_gen_arready();
    axi_ready_gen arready_gen;
    arready_gen = agent.wr_driver.create_ready("arready");
    arready_gen.set_ready_policy(XIL_AXI_READY_GEN_RANDOM);
    agent.rd_driver.send_arready(arready_gen);
endtask

/* AWREADY�̋����������_���� */
task user_gen_awready();
    axi_ready_gen awready_gen;
    awready_gen = agent.wr_driver.create_ready("awready");
    awready_gen.set_ready_policy(XIL_AXI_READY_GEN_RANDOM);
    agent.wr_driver.send_awready(awready_gen);
endtask

/* WREADY�̋����������_���� */
task user_gen_wready();
    axi_ready_gen wready_gen;
    wready_gen = agent.wr_driver.create_ready("wready");
    wready_gen.set_ready_policy(XIL_AXI_READY_GEN_RANDOM);
    agent.wr_driver.send_wready(wready_gen);
endtask

endmodule
