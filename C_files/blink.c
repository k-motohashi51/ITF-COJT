//-----------------------------------------------------------------------------
// Title       : LED点滅プログラム
// Project     : Zynqシステム体験
// Filename    : blink.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2015/03/09  1.00     M.Kobayashi   Created
// 2017/03/22  1.10     M.Kobayashi   Modified
//-----------------------------------------------------------------------------

#include <stdio.h>
#include "xparameters.h"

/* 出力ポートの定義 */
#define LED (*(volatile unsigned int *) XPAR_MYPORT_V1_0_0_BASEADDR)

/* 時間待ちのループ */
void delay( void ){
    int i;
    for ( i=0; i<4000000; i++);
}

int main()
{
    int i;

    while(1) {
        for ( i=0; i<14; i++ ) {
            switch ( i ) {
                case  0: LED = 0x01; break;
                case  1: LED = 0x02; break;
                case  2: LED = 0x04; break;
                case  3: LED = 0x08; break;
                case  4: LED = 0x10; break;
                case  5: LED = 0x20; break;
                case  6: LED = 0x40; break;
                case  7: LED = 0x80; break;
                case  8: LED = 0x40; break;
                case  9: LED = 0x20; break;
                case 10: LED = 0x10; break;
                case 11: LED = 0x08; break;
                case 12: LED = 0x04; break;
                case 13: LED = 0x02; break;
            }
            delay();
        }
    }
    return 0;
}
