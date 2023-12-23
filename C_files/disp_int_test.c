//-----------------------------------------------------------------------------
// Title       : 表示回路の割込テスト
// Project     : 表示回路
// Filename    : disp_int_test.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/04/23  1.00     M.Kobayashi   Created
// 2015/03/05  1.01     M.Kobayashi   Modified
//-----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>

#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"

int vcnt;

/* VBLANK割り込み処理 */
void DispIntHandler( void )
{
    vcnt++;
//  xil_printf("%d\n", vcnt);
    DISPINT |= DISPINTCLR;
}

/* VBLANK割り込み待ち */
void wait_vint( void )
{
    int pre_vcnt;
    pre_vcnt = vcnt;
    while(pre_vcnt==vcnt);
}

int main()
{
    int x, y, i;
    CojtCtr DispInstancePtr;

    vcnt = 0;

    init_tpf410();
    set_disp_page(0);

    /* 割り込み関連初期設定 */
    ScuGicInt_Init();
    ScuGicInt_Reg(XPAR_FABRIC_DISPLAY_0_DSP_IRQ_INTR, &DispInstancePtr, (void *)DispIntHandler);

    /* 表示ON */
    DISPINT = DISPINTENBL;
    wait_vint();
    set_resolution( VGA );
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
    DISPCTRL = DISPON;

    /* Page0 クリア */
    setVRAM(0);
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = 0;
    }

    /* Page0 に枠線をたくさん引いてみる */
    for ( i=0; i<50; i++ ) {
      drawbox(rand()%XSIZE, rand()%YSIZE, (rand()%XSIZE)/2, (rand()%YSIZE)/2, rand() );
    }

    /* Page1 にグラデーションを書く */
    setVRAM(1);
    for ( y=0; y<YSIZE; y++ ) {
        for ( x=0; x<XSIZE; x++ ) {
            VRAM[x+y*XSIZE] = ((x/4) << 16) | ((y/3) << 8) | 0x80;
        }
    }
    Xil_DCacheFlush();

    /* 60フレームごとに画面を切り替える */
    while(1) {
        for (i=0; i<60; i++ ) {
            wait_vint();
        }
        if ( (vcnt/60)%2==1 )
            set_disp_page(0);
        else
            set_disp_page(1);
    }

    return 0;
}
