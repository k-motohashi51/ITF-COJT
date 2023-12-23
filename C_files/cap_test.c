//-----------------------------------------------------------------------------
// Title       : キャプチャ回路のテストプログラム
// Project     : キャプチャ回路
// Filename    : cap_test.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/02/22  1.00     M.Kobayashi   Created
// 2014/04/23  1.01     M.Kobayashi   Modified
//-----------------------------------------------------------------------------

#include <stdio.h>
#include "xparameters.h"
#include "xil_cache.h"

#include "init_dvi.h"
#include "init_ov9655.h"
#include "init_xclk.h"
#include "cojt.h"

int main()
{
    init_tpf410();
    init_xclk(XCLK24MHz);

    DISPADDR = 0x20000000;
    CAPADDR  = 0x20000000;

    /* VGA */
    init_ov9655(OV9655_VGA);

    wait_vblank();
    set_resolution( VGA );
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
    DISPCTRL = DISPON;

    wait_cblank();
    CAPFIFO = CAP_FIFO_OVER | CAP_FIFO_UNDER;
    CAPCTRL = CAPON;


    /* XGA */
    wait_cblank();  /* ★★★　ここにブレークポイントを置く　★★★ */
    CAPCTRL = CAPOFF;
    init_ov9655(OV9655_SXGA);

    wait_vblank();
    set_resolution( XGA );
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;

    wait_cblank();
    CAPFIFO = CAP_FIFO_OVER | CAP_FIFO_UNDER;
    CAPCTRL = CAPON;

    return 0;
}
