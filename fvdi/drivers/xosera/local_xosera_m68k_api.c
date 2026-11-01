/*
 * A copy of some functions from xosera_m68k_api.c. I'll delete this if and when the Xosera API
 * supports setting xosera_ptr dynamically.
 */

#include <stdbool.h>
#include "xosera_m68k_api.h"

bool local_xosera_init(volatile xmreg_t *const xosera_ptr, xosera_mode_t init_mode);
void local_xosera_set_pointer(volatile xmreg_t *const xosera_ptr, int16_t x, int16_t y, uint16_t colormap_index);

#define SYNC_RETRIES 250        // ~1/4 second

// TODO: This is less than ideal (tuned for ~10MHz)
__attribute__((noinline)) static void my_cpu_delay(int ms)
{
    __asm__ __volatile__(
            "    lsl.l   #8,%[temp]\n"
            "    add.l   %[temp],%[temp]\n"
            "0:  sub.l   #1,%[temp]\n"
            "    tst.l   %[temp]\n"
            "    bne.s   0b\n"
            : [temp] "+d"(ms));
}

static bool local_xosera_sync(volatile xmreg_t *const xosera_ptr)
{
    uint16_t rd_incr = xm_getw(RD_INCR);
    uint16_t test_incr = rd_incr ^ 0xF5FA;
    xm_setw(RD_INCR, test_incr);
    if (xm_getw(RD_INCR) != test_incr) {
        return false;        // not detected
    }
    xm_setw(RD_INCR, rd_incr);

    return true;
}

// wait for Xosera to respond after reconfigure
static bool local_xosera_wait_sync(volatile xmreg_t *const xosera_ptr)
{
    // check for Xosera presense (retry in case it is reconfiguring)
    for (uint16_t r = SYNC_RETRIES; r != 0; --r) {
        if (local_xosera_sync(xosera_ptr)) {
            return true;
        }
        my_cpu_delay(10);
    }
    return false;
}


// reconfigure or sync Xosera and return true if it is responsive
// NOTE: May BUS ERROR if no hardware present
bool local_xosera_init(volatile xmreg_t *const xosera_ptr, xosera_mode_t init_mode)
{
    bool detected = local_xosera_wait_sync(xosera_ptr);

    if (detected) {
        xwait_not_vblank();
        xwait_vblank();
        if (init_mode >= XINIT_CONFIG_640x480) {
            xm_setbh(INT_CTRL, 0x80 | (init_mode & 0x03));        // reconfig FPGA to init_mode 0-3
            detected = local_xosera_wait_sync(xosera_ptr);                        // wait for detect
            if (detected) {
                // wait for initial copper program to disable itself (or timeout)
                uint16_t timeout = 100;
                do {
                    my_cpu_delay(1);
                } while ((xreg_getw(COPP_CTRL) & COPP_CTRL_COPP_EN_F) && --timeout);
            }
        }
    }

    return detected;
}

void local_xosera_set_pointer(volatile xmreg_t *const xosera_ptr, int16_t x, int16_t y, uint16_t colormap_index)
{
    uint8_t ws = xm_getbl(FEATURE) & FEATURE_MONRES_F;        // 0 = 640x480

    // offscreen pixels plus 6 pixel "head start"
    x = x + (ws ? MODE_848x480_LEFTEDGE - POINTER_H_OFFSET : MODE_640x480_LEFTEDGE - POINTER_H_OFFSET);
    // make sure doesn't wrap back onscreen due to limited bits in POINTER_H
    if (x < 0 || x > MODE_848x480_TOTAL_H)
    {
        x = MODE_848x480_TOTAL_H;
    }

    // make sure doesn't wrap back onscreen due to limited bits in POINTER_V
    if (y < -32 || y > MODE_640x480_V)
    {
        y = MODE_640x480_V;
    }
    else if (y < 0)
    {
        // special handling for partially off top (offset to before V wrap)
        y = y + (ws ? MODE_848x480_TOTAL_V : MODE_640x480_TOTAL_V);
    }

    // wait for start of hblank to hide change
    xwait_not_hblank();
    xwait_hblank();
    xreg_setw(POINTER_H, x);
    xreg_setw(POINTER_V, colormap_index | y);
}
