//-----------------------------------------------------------------------------
// Title       : �\����H1�̃e�X�g�x���`�i�r����DISPON�j
// Project     : display
// Filename    : tb_disp1_dispon.sv
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2023/01/20  1.00     M.Kobayashi   VIP���p�AARREADY�����_�����ASystemVerilog
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

`define VIPINST dut.design_1_i.axi_vip_0.inst

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module tb_disp1_dispon;

/* �e��萔 */
localparam integer STEP  = 8;
localparam integer DSTEP = 40;

localparam P_RESOL_VGA  = 2'b00;
localparam P_RESOL_XGA  = 2'b01;
localparam P_RESOL_SXGA = 2'b10;

/* �V�~�����[�V��������𑜓x�̐ݒ� */
localparam SIM_RESOL = P_RESOL_VGA;

/* �𑜓x�ɉ����đ���f����摜�t�@�C����؂�ւ��� */
localparam PIX_NUMBER   = (SIM_RESOL == P_RESOL_VGA) ? 640*480: (SIM_RESOL == P_RESOL_XGA) ? 1024*768: 1280*1024;
localparam PIC_FILENAME = (SIM_RESOL == P_RESOL_VGA) ? "wcup2002_VGA.raw":
                          (SIM_RESOL == P_RESOL_XGA) ? "wcup2002_XGA.raw": "wcup2002_SXGA.raw";

/* �摜�n�M�� */
logic           ACLK;
logic           ARESETN;
logic           DCLK;
logic           DSP_IRQ;
logic   [1:0]   RESOL;
logic   [7:0]   DSP_R, DSP_G, DSP_B;
logic           DSP_DE, DSP_HSYNC_X, DSP_VSYNC_X;
logic           DSP_FIFO_OVER, DSP_FIFO_UNDER;

/* ���W�X�^�o�X */
logic   [15:0]  WRADDR;
logic   [3:0]   BYTEEN;
logic           WREN;
logic   [31:0]  WDATA;
logic   [15:0]  RDADDR;
logic           RDEN;
logic   [31:0]  RDATA;

/* DUT�̐ڑ� */
design_1_wrapper dut (.*);

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
    meminit_pic();
endtask

/* VRAM�̃A�h���X */
localparam MEMBASE = 32'h2000_0000;

/* �摜�t�@�C���ǂݍ��� */
task meminit_pic();
reg [7:0] r, g, b;
integer fd, i;
begin
    fd = $fopen(PIC_FILENAME, "rb");
    for( i=0; i<PIX_NUMBER; i=i+1 ) begin
        r = $fgetc(fd);
        g = $fgetc(fd);
        b = $fgetc(fd);
        agent.mem_model.backdoor_memory_write_4byte( MEMBASE+i*4, {8'h00, r, g, b}, 4'hf );
    end
    $fclose(fd);
end
endtask

/* �e�X�g�x���`�{�� */
integer fd, vflag;

initial begin
    RESOL = SIM_RESOL;
    vflag = 0;
    fd = $fopen("imagedata.txt");
    ARESETN = 1; WRADDR = 0; BYTEEN = 0; WREN = 0; WDATA = 0; RDEN = 0; RDADDR = 0;
    #STEP;
    ARESETN = 0;
    #(STEP*100);
    ARESETN = 1;
    #(STEP*100);

    init_system();
    user_gen_arready();

    write_reg(DISPADDR, 4'hf, 32'h0);
    #(STEP*500000);
    write_reg(DISPCTRL, 4'hf, 32'h1); /* �����o���Ă���DISPON */

    #(STEP*4500000); /* 2��ʕ��{�� */
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

endmodule
