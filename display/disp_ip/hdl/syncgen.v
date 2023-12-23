module syncgen(
    input               DCLK,
    input               DRST,
    input       [1:0]   RESOL,
    output  reg         DSP_HSYNC_X,
    output  reg         DSP_VSYNC_X,
    output  reg         DSP_preDE,
    output  reg         VRSTART,
    output  reg [10:0]  HCNT,
    output  reg [10:0]  VCNT
);

`include "syncgen_param.vh"

/*******************************************************************/
/* DSP_HSYNC_X */

always @(posedge DCLK) begin
    if (DRST) begin
        DSP_HSYNC_X <= 1'b1;
    end else if (HCNT == HFP - 1) begin
        DSP_HSYNC_X <= 1'b0;
    end else if (HCNT == HFP + HPW - 1) begin
        DSP_HSYNC_X <= 1'b1;
    end
end

/*******************************************************************/
/* DSP_VSYNC_X */

always @(posedge DCLK) begin
    if (DRST) begin
        DSP_VSYNC_X <= 1'b1;
    end else if (HCNT == HFP - 1 && VCNT == VFP) begin
        DSP_VSYNC_X <= 1'b0;
    end else if (HCNT == HFP - 1 && VCNT == VFP + VPW) begin
        DSP_VSYNC_X <= 1'b1;
    end
end

/*******************************************************************/
/* DSP_preDE */

always @(posedge DCLK) begin
    if (DRST) begin
        DSP_preDE <= 1'b0;
    end else if (VCNT < VFP + VPW + VBP - 11'd1) begin
        DSP_preDE <= 1'b0;
    end else if (HCNT == HSC - 11'd3) begin
        DSP_preDE <= 1'b0;
    end else if (HFP + HPW + HBP - 11'd3 <= HCNT && HCNT < HSC - 11'd3) begin
        DSP_preDE <= 1'b1;
    end else begin
        DSP_preDE <= 1'b0;
    end
end

/*******************************************************************/
/* HCNT */

always @(posedge DCLK) begin
    if (DRST) begin
        HCNT <= 11'd0;
    end else if (HCNT == HSC - 11'd1) begin
        HCNT <= 11'd0;
    end else begin
        HCNT <= HCNT + 11'd1;
    end
end

/*******************************************************************/
/* VCNT */

always @(posedge DCLK) begin
    if (DRST) begin
        VCNT <= 11'd0;
    end else if (VCNT == VSC - 11'd1) begin
        VCNT <= 11'd0;
    end else if (HCNT == HSC - 11'd1) begin
        VCNT <= VCNT + 11'd1;
    end
end

/*******************************************************************/
/* VRSTART */

always @(posedge DCLK) begin
    if (DRST) begin
        VRSTART <= 1'b0;
    end else if (VCNT == VFP + VPW + VBP - 1'b1) begin
        VRSTART <= 1'b1;
    end else begin 
        VRSTART <= 1'b0;
    end
end

/*******************************************************************/

endmodule