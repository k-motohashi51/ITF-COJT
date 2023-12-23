//-----------------------------------------------------------------------------
// Title       : キャプチャ回路の割込テスト
// Project     : キャプチャ回路
// Filename    : cap_int_test.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/04/23  1.00     M.Kobayashi   Created
//-----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>

#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"
#include "init_ov9655.h"
#include "init_xclk.h"

int vcnt, ccnt;

/* VBLANK割り込み処理 */
void DispIntHandler( void )
{
    xil_printf("   V:%d\n", vcnt);  /* 実行時間を要すので本利用の際には削除する */
    vcnt++;
    DISPINT |= DISPINTCLR;
}

/* VBLANK割り込み待ち */
void wait_vint( void )
{
    int pre_vcnt;
    pre_vcnt = vcnt;
    while(pre_vcnt==vcnt);
}

/* CBLANK割り込み処理 */
void CapIntHandler( void )
{
    xil_printf("C:%d\n", ccnt);  /* 実行時間を要すので本利用の際には削除する */
    ccnt++;
    CAPINT |= CAPINTCLR;
}

/* CBLANK割り込み待ち */
void wait_cint( void )
{
    int pre_ccnt;
    pre_ccnt = ccnt;
    while(pre_ccnt==ccnt);
}

int main()
{
    CojtCtr DispInstancePtr, CapInstancePtr;

    vcnt = ccnt = 0;

    /* 各種ハード初期化 */
    init_tpf410();
    init_xclk(XCLK24MHz);
    init_ov9655(OV9655_VGA);

    /* 表示とキャプチャページを0に */
    set_disp_page(0);
    set_cap_page(0);

    /* 割り込み関連初期設定 */
    ScuGicInt_Init();
    ScuGicInt_Reg(XPAR_FABRIC_DISPLAY_0_DSP_IRQ_INTR, &DispInstancePtr, (void *)DispIntHandler);
    ScuGicInt_Reg(XPAR_FABRIC_CAPTURE_0_CAP_IRQ_INTR, &CapInstancePtr,  (void *)CapIntHandler);

    /* 表示ON */
    DISPINT  = DISPINTENBL;
    wait_vint();
    set_resolution( VGA );
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
    DISPCTRL = DISPON;

    /* キャプチャON */
    CAPINT  = CAPINTENBL;
    wait_cint();
    CAPFIFO = CAP_FIFO_OVER | CAP_FIFO_UNDER;
    CAPCTRL = CAPON;

    /* 割り込み待ちのため無限ループ */
    while(1);

    return 0;
}
