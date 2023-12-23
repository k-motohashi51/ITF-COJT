//-----------------------------------------------------------------------------
// Title       : SDカード内の画像ファイルを読み込んで表示するサンプルプログラム
// Project     : 表示回路
// Filename    : disp_sd_sample.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/06/14  1.00     M.Kobayashi   Created
// 2015/06/19  1.01     H.ISOmura
// 2017/04/01  1.02     M.Kobayashi   SDK純正のFatFSに対応
//-----------------------------------------------------------------------------

// #define MMC_SUPPORT

#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"

#include "ff.h"

int main()
{
	/* 解像度とファイル名の定義 */
	const int resol[3] = {VGA, XGA, SXGA};
    const TCHAR file_name[][30] = {"wcup2002_VGA.bin",  "wcup2002_XGA.bin" , "wcup2002_SXGA.bin"};

    init_tpf410();
    setVRAM(0);
    DISPADDR = 0x20000000;

    int i, pnt,r;
    UINT num;
    FRESULT fr;
    FATFS FatFs;
    FIL Fil;
    char buff[4100];

    while(1){
		for(r=0;r<3;r++){
			wait_vblank();/* ここにブレークポイントを置く */
			set_resolution( resol[r] );//解像度変更
			DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
			DISPCTRL = DISPON;

			/* 画面クリア */
			for ( i=0; i<XSIZE*YSIZE; i++) {
				VRAM[i] = 0x00AAAAAA;
			}
			Xil_DCacheFlush();

			/* ファイルを読み込みVRAMに書き込む */
			wait_vblank();/* ここにブレークポイントを置く */
			f_mount(&FatFs, "", 0);
			fr=f_open(&Fil, file_name[r], FA_READ);
			if ( fr ) {
				xil_printf("Open Error!\n");
			}
			pnt = 0;
			while(1) {
				f_read(&Fil, buff, 4096, &num);
				for ( i=0; i<num; i+=4 ) {
					VRAM[i/4 + pnt] = (buff[i+3] << 24 ) | (buff[i+2] << 16 ) | (buff[i+1] << 8 ) | buff[i];
				}
				if (num<4096)
					break;
				else
					pnt += num/4;
			}
			f_close(&Fil);

		    Xil_DCacheFlush();
		}
    }
    return 0;
}
