/*
 * Mouse cursor functions for Xosera
 * This is part of the Xosera driver for fVDI.
 *
 * Copyright (C) 2024 Rob Gowin
 * Copyright (C) 2023 Daniel Cliche
 * Copyright (C) 2023 Xark
 */

#include <stdint.h>
#include "xosera.h"
#include "driver.h"

void local_xosera_set_pointer(volatile xmreg_t *xosera_ptr, int16_t x, int16_t y, uint16_t colormap_index);

static void show_mouse(volatile xmreg_t *const xosera_ptr, short x, short y)
{
    static uint16_t mouse_y_scale = 0, mouse_x_scale = 0;
    if (mouse_y_scale == 0) {
        uint16_t pa_gfx_ctrl = xreg_getw(PA_GFX_CTRL);
        switch (pa_gfx_ctrl & GFX_CTRL_V_REPEAT_F) {
            case GFX_1X: mouse_y_scale = 1; break;
            case GFX_2X: mouse_y_scale = 2; break;
            case GFX_3X: mouse_y_scale = 3; break;
            case GFX_4X: mouse_y_scale = 4; break;
            default: mouse_y_scale = 1; break;
        }
        switch ((pa_gfx_ctrl & GFX_CTRL_H_REPEAT_F) >> GFX_CTRL_H_REPEAT_B) {
            case GFX_1X: mouse_x_scale = 1; break;
            case GFX_2X: mouse_x_scale = 2; break;
            case GFX_3X: mouse_x_scale = 3; break;
            case GFX_4X: mouse_x_scale = 4; break;
            default: mouse_x_scale = 1; break;
        }
    }
    local_xosera_set_pointer(xosera_ptr, x * mouse_x_scale, y * mouse_y_scale, 0xF000);
}

static void set_mouse_image(volatile xmreg_t *const xosera_ptr, uint16_t *mask, uint16_t *data)
{
    // TOS will provide a 16x16x1 mouse image that we need to store into a 32x32x4 array.
    uint16_t pointer_sprite[256];
    uint16_t exp_mask[4], exp_data[4];

    memset(pointer_sprite, 0, 256 * sizeof(uint16_t));
    // Expand the mouse data. Each word of incoming data gets expanded to four words. The other four words on the
    // raster line are skipped and left as zero.
    const uint16_t fg = 0x1111, bg = 0xFFFF; // FIXME: This should deal with colors.

    for (int i = 0; i < 16; i++) {
        // Expand the 1bpp mask and data to 4ppp words.
        expand_word(exp_mask, mask[i]);
        expand_word(exp_data, data[i]);

        for (int j = 0; j < 4; j++) {
            pointer_sprite[i * 8 + j] = ((exp_data[j] & fg) | (~exp_data[j] & bg)) & exp_mask[j];
        }
    }
    xmem_setw_next_addr(XR_POINTER_ADDR);
    for (int i = 0; i < 256; i++) {
        xmem_setw_next_wait(pointer_sprite[i]);
    }
}

long CDECL
c_mouse_draw(Workstation *UNUSED(wk), long x, long y, Mouse *mouse)
{
    volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);

    long mouse_val = (long) mouse;
    short sx = (short) x, sy = (short) y;
    switch (mouse_val) {
        case 0: /* Move visible */
        case 4: /* Move visible forced (wk_mouse_forced) */
            show_mouse(xosera_ptr, sx, sy);
            return 1;
        case 2: /* Hide the mouse. */
            local_xosera_set_pointer(xosera_ptr, -32, -32, 0xF000);
            return 1;
        case 3: /* Show the mouse. */
            show_mouse(xosera_ptr, sx, sy);
            return 1;
        default:
            if (mouse_val > 7) {  /* Set new mouse cursor shape */
                set_mouse_image(xosera_ptr, (uint16_t *) mouse->mask, (uint16_t *) mouse->data);
                return 1;
            } else {
                char numbuf[32];
                access->funcs.ltoa(numbuf, mouse_val, 10);
                access->funcs.puts("xosera_mouse.c: unexpected mouse value ");
                access->funcs.puts(numbuf);
                access->funcs.puts("\n");
            }
            break;
    }
    return 0;
}
