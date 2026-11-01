/* 
 * Pixel read/write routines for Xosera.
 *
 * This file implements for FVDI API functions c_read_pixel() and c_write_pixel().
 */

#include "xosera.h"
#include "driver.h"

/*
 * Destination MFDB (odd address marks table operation)
 * x or table address
 * y or table length (high) and type (0 - coordinates)
 */

long CDECL
c_write_pixel(Virtual *vwk, MFDB *dst, long x, long y, long colour)
{
    static uint16_t offscreen_y_offset = 0;

    if ((long) vwk & 1) return -1;
    if (offscreen_y_offset == 0) offscreen_y_offset = vwk->real_address->screen.mfdb.height;

    volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);

    // If off screen, offset the Y by the height of the screen.
    uint16_t offset = is_screen(vwk->real_address, dst) ? 0 : offscreen_y_offset;
    xm_setw(PIXEL_X, x);
    xm_setw(PIXEL_Y, y + offset);
    vram_setw_next_wait(expanded_color[colour & 0xF]);
    xm_setbl(SYS_CTRL, 0xF); /* restore the possibly-modified write mask. */
    return 1;
}

long CDECL
c_read_pixel(Virtual *vwk, MFDB *src, long x, long y)
{
    static uint16_t offscreen_y_offset = 0, screen_width = 0;
    if (offscreen_y_offset == 0) {
        offscreen_y_offset = vwk->real_address->screen.mfdb.height;
        screen_width = vwk->real_address->screen.mfdb.width;
    }

    volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);
    // If off screen, offset the Y by the height of the screen.
    uint16_t offset = is_screen(vwk->real_address, src) ? 0 : offscreen_y_offset;
    uint16_t addr = (y + offset) * (screen_width / 4) + (x / 4);
    xm_setw(RD_ADDR, addr);
    uint16_t color = xm_getw(DATA);
    uint16_t shifted_color = color >> ((3 - (x & 0x3)) * 4);
    return shifted_color & 0xF;
}
