//-----------------------------------------------------------------------------
// Title       : �\����H2�̃e�X�g�x���`�i���W�X�^�Ɖ𑜓x�؂�ւ��̃e�X�g�j
// Project     : display
// Filename    : tb_disp2.sv
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2023/01/20  1.00     M.Kobayashi   VIP���p�AARREADY�����_�����ASystemVerilog
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

`define VIPINST dut.design_1_i.axi_vip_0.inst

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module tb_disp2;

/* �e��萔 */
localparam integer STEP  = 8;
localparam integer DSTEP = 40;

localparam P_RESOL_VGA  = 2'b00;
localparam P_RESOL_XGA  = 2'b01;
localparam P_RESOL_SXGA = 2'b10;

/* �V�~�����[�V��������𑜓x�̐ݒ�i������؂�ւ��čēx�V�~�����[�V��������j */
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

/* ���W�X�^�ǂݏo���i2�N���b�N�j*/
task read_reg;
input  [15:0] addr;
output [31:0] rdata;
begin
    RDADDR = addr;
    @(negedge ACLK);
    RDEN = 1;
    @(negedge ACLK);
    @(negedge ACLK);
    rdata = RDATA;
    RDEN = 0;
    @(negedge ACLK);
end
endtask


/* VIP Slave�p�̃G�[�W�F���g��錾���X���[�u���N�� */
design_1_axi_vip_0_0_slv_mem_t agent;

task init_system();
    agent = new("AXI Slave Agent", `VIPINST.IF);
    agent.start_slave();
    meminit_pic();
endtask

/* VRAM�̃A�h���X�i�y�[�W#1�ɐݒ�j*/
localparam MEMBASE = 32'h20000000 + PIX_NUMBER * 4;

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

/* ���W�X�^�̓ǂݏo���ƕ\�� */
task read_disp;
input  [15:0] addr;
reg [31:0] readdata;
begin
    #(STEP*2);
    read_reg(addr, readdata);
    $display( "ADDR=%h DATA=%h", addr, readdata);
end
endtask

/* VBLANK�҂� */
task wait_vblank;
reg [31:0] readdata;
begin
    read_reg(DISPCTRL, readdata);
    write_reg(DISPCTRL, 4'b0001, readdata | 32'h00000002); // VBLANK�N���A
    read_reg(DISPCTRL, readdata);
    while ((readdata & VBLANK)==0) begin
        read_reg(DISPCTRL, readdata);
    end
    $display("VBLANK");
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

    $display("-- DISPADDR write/read --");
    write_reg(DISPADDR, 4'b0001, 32'h12345678); // [7:0]�ɏ�������
    read_disp(DISPADDR);
    write_reg(DISPADDR, 4'b0010, 32'h00005600); // [15:8]�ɏ�������
    read_disp(DISPADDR);
    write_reg(DISPADDR, 4'b0100, 32'h00340000); // [23:16]�ɏ�������
    read_disp(DISPADDR);
    write_reg(DISPADDR, 4'b1000, 32'h12000000); // [31:24]�ɏ�������
    read_disp(DISPADDR);

    $display("-- Waiting VBLANK --");
    wait_vblank;
    write_reg(DISPADDR, 4'b1111, MEMBASE); // �y�[�W#1�̃A�h���X��ݒ�
    read_disp(DISPADDR);

    $display("DISPON");
    write_reg(DISPCTRL, 4'b0001, 32'h00000001); // DISPON
    write_reg(DISPINT,  4'b0001, 32'h00000003); // INTCLR, INTENBL
    write_reg(DISPFIFO, 4'b0001, 32'h00000003); // FIFO�t���O���N���A

    read_disp(DISPCTRL);
    read_disp(DISPINT);
    read_disp(DISPFIFO);

    $display("-- Waiting VBLANK --");
    wait_vblank;
    #(STEP*100);
    write_reg(DISPINT,  4'b0001, 32'h00000003); // DSP_IRQ���N���A
    #(STEP*100);
    $display("-- All Registers --");
    read_disp(DISPADDR);
    read_disp(DISPCTRL);
    read_disp(DISPINT);
    read_disp(DISPFIFO);
    #(STEP*10000);

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
