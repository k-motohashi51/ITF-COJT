// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Sat Dec 23 16:06:27 2023
// Host        : COJTHW108 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/HW108.COJTHW/COJT/SUBMIT/capture/cap_ip/src/fifo_48in48out_2048depth/fifo_48in48out_2048depth_stub.v
// Design      : fifo_48in48out_2048depth
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_7,Vivado 2022.2" *)
module fifo_48in48out_2048depth(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, 
  overflow, empty, underflow, rd_data_count)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[47:0],wr_en,rd_en,dout[47:0],full,overflow,empty,underflow,rd_data_count[10:0]" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [47:0]din;
  input wr_en;
  input rd_en;
  output [47:0]dout;
  output full;
  output overflow;
  output empty;
  output underflow;
  output [10:0]rd_data_count;
endmodule
