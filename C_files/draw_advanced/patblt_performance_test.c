/*
 * patblt_performance_test.c
 *
 *  Created on: 2014/09/04
 *      Author: koba
 */

#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"

void command( int );
void exe_draw( void );

//#define ALPHA_ON

#define NORMAL_PATBLTs 406  // 406が計測限界（コマンドバッファが満杯になるため）
#define ALPHA_PATBLTs 218

int main()
{
    int i;
    int p;
    int frame;
    int rgb[256];
    int dposx[256];
    int dposy[256];
    int index;

    /* 各種ハード初期化 */
    init_tpf410();

    /* 解像度を最初に設定 */
    set_resolution( VGA );

    /* 表示回路 */
    wait_vblank();
    set_disp_page(0); /* 表示：page0 */
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
    DISPCTRL = DISPON;

    xil_printf("PATBLT test start\n");

    // 計算に時間が掛かかり、描画性能計測に影響があるので事前計算
    for ( i = 0 ; i < 256 ; i++ ) {
      dposx[i] = ((rand()>>4)%10)*64;
      dposy[i] = ((rand()>>4)%10)*48;
      rgb[i] = (rand()&0xFF)<<16 | (rand()&0xFF)<<8 | (rand()&0xFF);
    }

    frame = 0;
    while (1) {
        // SETFRAME
        command(0x20000000);
        command(0x20000000+XSIZE*YSIZE*4*frame); // ページ0 or ページ1
        command(XSIZE<<16 | YSIZE);

        // SETDRAWAREA
        command(0x21000000);
        command(0x00000000); // POSX=0, POSY=0
        command(XSIZE<<16 | YSIZE);

        // SETSTMODE
        command(0x30000000);

        // SETBLENDOFF
        command(0x32000000);

        // SETFCOLOR
        command(0x23000000);
        command(0x00000000); // ARGB=0

        // PATBLT
        command(0x81000000);
        command(0x00000000); // DPOSX=0,   DPOSY=0
        command(XSIZE<<16 | YSIZE); // DSIZX=640, DSIZY=480

	#ifdef ALPHA_ON
        // SETBLENDALPHA
        command(0x33034E00);
        command(0x80808080); // COEF0
        command(0xFFFFFFFF); // COEF1
        for ( p = 0 ; p < ALPHA_PATBLTs ; p++ ) {
	#else
        for ( p = 0 ; p < NORMAL_PATBLTs ; p++ ) {
	#endif
        	index = rand();
        	// SETFCOLOR
        	command(0x23000000);
        	command(rgb[(index&0xFF00)>>8]);

            // PATBLT
            command(0x81000000);
            command(dposx[index&0xFF]<<16 | dposy[(index&0xFF0)>>4]);
            command((64<<16)| 48); // DSIZX=64, DSIZY=48
        }

        // EODL
        command(0x0F000000);

        wait_vblank();
        DISPCTRL |= VBLANK;

        // 描画開始&終了待ち
        exe_draw();

        // フレームバッファのスワップ(描画完了したフレームを表示)
        set_disp_page(frame);
        if ( frame == 0 )
            frame = 1;
        else
            frame = 0;
    }

    return 0;
}

/* 描画コマンド書き込み */
void command(int data) {
    DRAWCMD = data;
}

void exe_draw( void ) {
    DRAWCTRL = DRAWEXE;
    while ( (DRAWSTAT & DRAWBUSY) != 0 );
    DRAWCTRL = DRAWRST;
    if ( (DISPCTRL & VBLANK) != 0) {
        xil_printf("X"); // 描画終了時点でVBLANKが来ていたらNG（Xを表示）
        DISPCTRL |= VBLANK;
    }
    else {
        xil_printf(".");
        while ( (DISPCTRL & VBLANK) ==0 );
        DISPCTRL |= VBLANK;
    }
}
