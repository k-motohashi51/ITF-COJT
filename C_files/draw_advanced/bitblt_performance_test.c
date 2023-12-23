/*
 * bitblt_performance_test.c
 *
 *  Created on: 2017/04/01
 *      Author: koba
 */

#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"
#include "init_ov9655.h"
#include "init_xclk.h"
#include "ff.h"

void dispclear( void );
void command( int );
void fileread( char *, int );
void exe_draw( void );

// #define ALPHA_ON
#define CAPTURE_ON

#define NORMAL_BITBLTs 177
#define NORMAL_CAPTURE_BITBLTs 175
#define ALPHA_BITBLTs 113
#define ALPHA_CAPTURE_BITBLTs 112


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
    init_xclk(XCLK24MHz);
    init_ov9655(OV9655_VGA);

    /* 解像度を最初に設定 */
    set_resolution( VGA );

    /* テクスチャー画像をページ3に読み込む */
    fileread("JetCoaster_VGA.bin", 3);

    /* 表示回路 */
    wait_vblank();
    set_disp_page(0); /* 表示：page0 */
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
    DISPCTRL = DISPON;

    /* キャプチャON */
    set_cap_page(2); /* キャプチャ：page2 */
    wait_cblank();
    CAPFIFO = CAP_FIFO_OVER | CAP_FIFO_UNDER;
    CAPCTRL = CAPON;

    xil_printf("BITBLT test start\n");

    // 計算に時間が掛かかり、描画性能計測に影響があるので事前計算
    for ( i = 0 ; i < 256 ; i++ ) {
      dposx[i] = ((rand()>>4)%10)*64;
      dposy[i] = ((rand()>>4)%10)*48;
      rgb[i] = (rand()&0xFF)<<16 | (rand()&0xFF)<<8 | (rand()&0xFF);
    }

    frame = 0;
    wait_cblank();
#ifndef CAPTURE_ON
    // キャプチャOFF
    CAPCTRL  = CAPOFF;
#endif

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
        command(rgb[i]);

        // SETTEXTURE(キャプチャ画像)
        command(0x22000000);
        command(0x20000000+XSIZE*YSIZE*4*2); // ページ2

        // BITBLT
        command(0x82000000);
        command(0x00000000);        // DPOSX=0,   DPOSY=0
        command(XSIZE<<16 | YSIZE); // DSIZX=640, DSIZY=480
        command(0x00000000);        // SPOSX=0,   SPOSY=0

        // SETTEXTURE(ファイルの画像)
        command(0x22000000);
        command(0x20000000+XSIZE*YSIZE*4*3); // ページ3

  #ifdef ALPHA_ON
        // SETBLENDALPHA
        command(0x33034E00);
        command(0x80808080); // COEF0
        command(0xFFFFFFFF); // COEF1
    #ifdef CAPTURE_ON
        for ( p = 0 ; p < ALPHA_CAPTURE_BITBLTs ; p++ ) {
    #else
        for ( p = 0 ; p < ALPHA_BITBLTs ; p++ ) {
    #endif
  #else
    #ifdef CAPTURE_ON
        for ( p = 0 ; p < NORMAL_CAPTURE_BITBLTs ; p++ ) {
    #else
        for ( p = 0 ; p < NORMAL_BITBLTs ; p++ ) {
    #endif
  #endif

            index = rand();
            // BITBLT
            command(0x82000000);
            command(dposx[index&0xFF]<<16 | dposy[(index&0xFF0)>>4]);
            command((64<<16)|48);     // DSIZX=64, DSIZY=48
            command(dposx[index&0xFF]<<16 | dposy[(index&0xFF0)>>4]);
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


/* 画面クリア */
void dispclear( void )
{
     int i;
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = 0;
    }
    Xil_DCacheFlush();
}


/* 描画コマンド書き込み */
void command(int data) {
    DRAWCMD = data;
}


/* 画像ファイルの読み込み */
void fileread( char *filename, int page )
{
    int i, pnt;
    UINT num;
    FRESULT fr;
    FATFS FatFs;
    FIL Fil;
    char buff[4100];

    setVRAM(page);
    f_mount(&FatFs, "", 0);
    fr=f_open(&Fil, filename, FA_READ);
    if ( fr ) {
        xil_printf("Open Error!\n");
    }
    xil_printf("Reading '%s' on SD Card.\n", filename);
    pnt = 0;
    while(1) {
        f_read(&Fil, buff, 4096, &num);
        for ( i=0; i<num; i+=4 ) {
            VRAM[i/4 + pnt] = (buff[i+3] << 24 ) | (buff[i+2] << 16 ) | (buff[i+1] << 8 ) | buff[i];
        }
        pnt += num/4;
        if (num<4096) {
            break;
        }
    }
    f_close(&Fil);
    Xil_DCacheFlush();
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
