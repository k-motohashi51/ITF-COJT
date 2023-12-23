//-----------------------------------------------------------------------------
// Title       : パターン表示回路のテストプログラム
// Project     : パターン表示回路
// Filename    : pattern.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/02/22  1.00     M.Kobayashi   Created
// 2017/04/06  1.01     M.Kobayashi   コメントを追加
//-----------------------------------------------------------------------------

#include <stdio.h>
#include "xparameters.h"
#include "init_dvi.h"

#define RESOLUTION (*(volatile unsigned int *) (XPAR_AXI_GPIO_0_BASEADDR + 0x00))
#define RESOL_CTRL (*(volatile unsigned int *) (XPAR_AXI_GPIO_0_BASEADDR + 0x04))

#define VGA  0
#define XGA  1
#define SXGA 2

int main()
{
    init_tpf410();
    RESOL_CTRL = 0;

    /* ステップ動作して解像度を切り替える */
    /* 解像度の変化は、LCDモニタのステータス表示で確認する */
    while(1) {
        RESOLUTION = VGA;   /* ★ここにブレークポイントを置く★ */
        RESOLUTION = XGA;
        RESOLUTION = SXGA;
    }
    
    return 0;
}
