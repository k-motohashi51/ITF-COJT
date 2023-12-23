//-----------------------------------------------------------------------------
// Title       : サウンド回路のテストプログラム（SDカード内のwavファイルを読み込んで出力する）
// Project     : サウンド回路
// Filename    : snd_test_sd.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/07/28  1.00     M.Kobayashi   Created
// 2017/12/18  1.10     M.Kobayashi   SDK純正のFatFSに対応
//-----------------------------------------------------------------------------

#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "ff.h"

#define MEM ((volatile unsigned char *) 0x20000000)
#define BLKSIZE 4096

#define WAV_FILE "s33.wav"

/* SDカードのファイルを読み込みVRAMに書き込む */
void readfile(char *filename) {
    int i, cnt=0;
    UINT num;
    FRESULT fr;
    FATFS FatFs;
    FIL Fil;
    unsigned char buff[BLKSIZE+100];

    xil_printf("Reading '%s' on the SD Card.\n", filename);
    f_mount(&FatFs, "", 0);
    fr=f_open(&Fil, filename, FA_READ);
    if ( fr ) {
        xil_printf("Open Error!\n");
    }
    while(1) {
        f_read(&Fil, buff, BLKSIZE, &num);
        for ( i=0; i<num; i++ ) {
            MEM[cnt+i] = buff[i];
        }
        cnt += BLKSIZE;
        if (num<BLKSIZE) {
            break;
        }
    }
    f_close(&Fil);
    Xil_DCacheFlush();
}


int main()
{
    int size;

    SNDCTRL = SNDSTOP;

    readfile(WAV_FILE);

    /* サイズを抽出してサウンド回路を起動 */
    size = (MEM[43]<<24) | (MEM[42]<<16) | (MEM[41]<<8) | MEM[40];
    xil_printf("WAV data size = %x(HEX) %d(DEC)\n", size, size);
    SNDADDR = 0x2000002C;
    SNDSIZE = size;
    SNDVOL  = 0xFF;
    SNDCTRL = SNDLOOP | SNDPLAY;

    xil_printf("SNDADDR = %x\n", SNDADDR);
    xil_printf("SNDSIZE = %x\n", SNDSIZE);
    xil_printf("SNDVOL  = %x\n", SNDVOL);
    xil_printf("SNDCTRL = %x\n", SNDCTRL);

    /* 以下はステップ動作により、細かい動作を確認する */
    SNDCTRL = SNDLOOP | SNDPAUSE;
    SNDCTRL = SNDLOOP | SNDPLAY;
    SNDCTRL = SNDLOOP | SNDSTOP;
    SNDCTRL = SNDLOOP | SNDPLAY;

    SNDVOL  = 0x80;
    SNDVOL  = 0x40;
    SNDVOL  = 0x20;
    SNDVOL  = 0x00;
    SNDVOL  = 0xFF;

    SNDCTRL = SNDLOOP | SNDPAUSE;
    SNDCTRL = SNDPLAY;
    SNDCTRL = SNDSTOP;
    SNDCTRL = SNDPLAY;

    return 0;
}
