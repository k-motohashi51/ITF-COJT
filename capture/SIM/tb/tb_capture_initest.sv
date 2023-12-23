//-----------------------------------------------------------------------------
// Title       : capture�̃e�X�g�x���`�i�O����^����VSYNC�ɂ�鏉�������e�X�g�j
// Project     : capture
// Filename    : tb_capture_initest.sv
//-----------------------------------------------------------------------------
// Description : ���ʉ摜�̃J�������f���icamera2.v�j���g�p
//   CBLANK���o������摜�ۑ������v3��ʁiimagedata0.txt�`imagedata2.txt�j�ۑ�����
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2023/02/15  1.00     M.Kobayashi   VIP���p�A�eREADY�����_�����ASystemVerilog
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

`define VIPINST  dut.design_1_i.axi_vip_0.inst

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module tb_capture_initest;

/* �e��萔 */
localparam integer STEP  = 8;

localparam P_RESOL_VGA  = 2'b00;
localparam P_RESOL_XGA  = 2'b01;
localparam P_RESOL_SXGA = 2'b10;

/* �V�~�����[�V��������𑜓x�̐ݒ�i������؂�ւ��čēx�V�~�����[�V��������j */
localparam SIM_RESOL = P_RESOL_VGA;

/* �O���̃^�C�v��؂�ւ��čēx�V�~�����[�V�������� */
`define TOCHU_DE_CAPON          /* �r����CAPON���� */
//`define TOCHU_DE_CAMREST     /* �r���ŃJ�������f�������Z�b�g���� */


/* �𑜓x�ɉ����đ���f����؂�ւ��� */
localparam PIX_NUMBER = (SIM_RESOL == P_RESOL_VGA) ? 640*480: (SIM_RESOL == P_RESOL_XGA) ? 1024*768: 1280*1024;


/* �V�X�e���n�M�� */
logic           ACLK;
logic           ARESETN;
logic           CAP_IRQ;
logic   [1:0]   RESOL;
logic           CAP_FIFO_OVER, CAP_FIFO_UNDER;

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
logic   [31:0]  RDATA;

/* DUT�̐ڑ� */
design_1_wrapper dut (.*);

/* �J�������f���ڑ� */
reg CAM_ENABLE;
camera2 camera
  (
    .PCLK       (PCLK),
    .HREF       (HREF),
    .VSYNC      (VSYNC),
    .CAMDATA    (CAMDATA),
    .ENABLE     (CAM_ENABLE),
    .RESOL      (RESOL)
);

/* �N���b�N */
always begin
    ACLK = 0; #(STEP/2);
    ACLK = 1; #(STEP/2);
end

/* ���W�X�^�A�h���X */
localparam CAPADDR = 16'h1000;
localparam CAPCTRL = 16'h1004;
localparam CAPINT  = 16'h1008;
localparam CAPFIFO = 16'h100c;
localparam CBLANK = 32'h2;

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

/* �V�~�����[�����ʉ摜�𕶎��t�@�C���ŏo�́i�t�@�C�����ɐ����t���j */
task fileout_page();
input [7:0] page;
reg [31:0] pic;
integer fd, i;
begin
    fd = $fopen( {"imagedata", page+8'h30, ".txt"} );
    for ( i=0; i<PIX_NUMBER; i=i+1 ) begin
        pic = agent.mem_model.backdoor_memory_read_4byte( MEMBASE+i*4 );
        $fdisplay(fd, "%06x", pic[23:0]);
    end
    $fdisplay(fd, "vsync");
    $fclose(fd);
end
endtask

/* �e�X�g�x���`�{�� */
integer i, fd;

initial begin
    RESOL = SIM_RESOL;
    ARESETN = 1; WRADDR = 0; BYTEEN = 0;
    WREN = 0; WDATA = 0; RDEN = 0; RDADDR = 0;
    CAM_ENABLE = 0;
    #STEP;
    ARESETN = 0;
    #(STEP*100);
    ARESETN = 1; CAM_ENABLE = 1;
    #(STEP*100);

    init_system();
    user_gen_awready();
    user_gen_wready();

    write_reg(CAPADDR, 4'hf, 32'h0);
`ifdef TOCHU_DE_CAMREST
    write_reg(CAPCTRL, 4'hf, 32'h1);
`endif
end

`ifdef TOCHU_DE_CAPON
/* 1/3��ʒ��x��CAPON */
initial begin
    #(STEP*1000000)
    write_reg(CAPCTRL, 4'hf, 32'h1);
    for ( i=0; i<3; i=i+1 ) begin
        @(negedge VSYNC);
        fileout_page(i);
        #(STEP*10);
    end
    $stop;
end
`endif

`ifdef TOCHU_DE_CAMREST
/* 1/3��ʒ��x�ŃJ���������Z�b�g */
initial begin
    #(STEP*1000000)
    CAM_ENABLE = 0;
    #(STEP*10);
    CAM_ENABLE = 1;
    for ( i=0; i<3; i=i+1 ) begin
        @(negedge VSYNC);
        fileout_page(i);
        #(STEP*10);
    end
    $stop;
end
`endif

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
