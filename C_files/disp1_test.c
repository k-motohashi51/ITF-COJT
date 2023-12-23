//-----------------------------------------------------------------------------
// Title       : 表示回路１のテストプログラム
// Project     : 表示回路１
// Filename    : disp1_test.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2015/03/04  1.00     M.Kobayashi   Created
// 2017/04/01  1.10     M.Kobayashi   ブレークポイント位置修正
//-----------------------------------------------------------------------------

#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"

int main()
{
    int i;

    init_tpf410();
    setVRAM(0);

    /* VGA */
    set_resolution( VGA );
    DISPCTRL = DISPON;

    /* 画面クリア */	    /* ★ここにブレークポイントを置く★ */
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = 0;
    }
    Xil_DCacheFlush();

    /* 縞模様を書く */	    /* ★ここにブレークポイントを置く★ */
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = i;
    }
    Xil_DCacheFlush();

    return 0;
}
