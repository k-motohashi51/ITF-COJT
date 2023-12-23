//-----------------------------------------------------------------------------
// Title       : PS/2マウスのサンプルプログラム
// Project     :
// Filename    : mouse_sample.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/09/25  1.00     M.Kobayashi   Created
// 2017/04/01  1.10     M.Kobayashi   設定のデフォルト値をマクロ化
//-----------------------------------------------------------------------------
#include <stdio.h>
#include "xil_printf.h"
#include "cojt.h"

/* 解像度 ・・ VGA, XGA, SXGA */
/* マウス速度 ・・ MOUSE_FAST, MOUSE_NORM, MOUSE_SLOW, MOUSE_SLOW2 */
#define RESOL VGA
#define SPEED MOUSE_NORM

int main()
{
    int xpos, ypos, zpos, button;

    init_mouse( RESOL, SPEED );

    while(1) {
        if ( get_mouse( &xpos, &ypos, &zpos, &button) ) {
            xil_printf("xpos = %d  ypos = %d  zpos = %02x  btn = %02x\n",
                    xpos, ypos, zpos, button );
            if ( (button & MOUSE_CENTER) !=0 ) {
                /* 初期化するとマウス位置は中心座標になる */
                init_mouse( RESOL, SPEED );
            }
        }
    }
    return 0;
}
