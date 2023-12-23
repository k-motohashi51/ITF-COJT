//-----------------------------------------------------------------------------
// Title       : 表示回路２のテストプログラム
// Project     : 表示回路
// Filename    : disp2_test.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2015/03/08  1.00     M.Kobayashi   Created
// 2015/11/26  1.10     M.Kobayashi   最後にVRAMアクセス停止を追加
// 2017/04/01  1.20     M.Kobayashi   ブレークポイントの位置修正
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
    DISPADDR = 0x20000000;

    /* VGA */
    wait_vblank();
    set_resolution( VGA );
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
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

    /* この後にプログラムを追加して細かい動作を確かめる */


    /* XGA */
    wait_vblank();  /* ★ここにブレークポイントを置く★ */
    set_resolution( XGA );
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
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

    /* この後にプログラムを追加して細かい動作を確かめる */


    /* 最後はVRAMアクセスを停止して終わる */
    wait_vblank();  /* ★ここにブレークポイントを置く★ */
    DISPCTRL = DISPOFF;
    return 0;
}
