/*
 * Mouse pointer for the VERA fVDI driver: VERA sprite 0.
 *
 * Copyright (C) 2026 Dan Werner
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

/*
 * The pointer is a 16x16 sprite at 4 bits per pixel: 0 is transparent,
 * 1 the background (mask) colour and 2 the foreground (data) colour. With
 * palette offset 1, those are VERA palette entries 17 and 18, which hold
 * copies of the current colours of the pointer.
 *
 * fVDI calls c_mouse_draw() from its VBL handler, an interrupt, which may
 * come in while a drawing call is using the VERA ports. The new position
 * or shape is then only recorded, and applied when the drawing is done
 * (v_end(), or EmuTOS's release hook for its own console drawing).
 */

#include "vera.h"
#include "driver.h"

static volatile int16_t pointer_x, pointer_y;   /* top left of the form */
static volatile uint8_t pointer_shown;
static volatile uint8_t pending_position, pending_shape;
static int16_t hot_x, hot_y;
static uint8_t pointer_fg = 15, pointer_bg = 0; /* hardware colours */
static uint16_t pointer_mask[16], pointer_data[16];

/* Copy the pointer colours into palette entries 17 and 18 */
void mouse_update_colours(void)
{
    v_set_write(VRAM_PALETTE + 2 * 17);
    V_PUT(hw_palette[pointer_bg] & 0xff);
    V_PUT((hw_palette[pointer_bg] >> 8) & 0x0f);
    V_PUT(hw_palette[pointer_fg] & 0xff);
    V_PUT((hw_palette[pointer_fg] >> 8) & 0x0f);
}

static void write_shape(void)
{
    uint16_t row, bit;

    v_set_write(VRAM_POINTER);
    for (row = 0; row < 16; row++)
    {
        uint16_t mask = pointer_mask[row];
        uint16_t data = pointer_data[row];

        for (bit = 0x8000; bit; bit >>= 2)  /* 2 pixels per byte */
        {
            uint8_t b;

            b = (data & bit) ? 0x20 : (mask & bit) ? 0x10 : 0x00;
            b |= (data & (bit >> 1)) ? 0x02 : (mask & (bit >> 1)) ? 0x01 : 0x00;
            V_PUT(b);
        }
    }
    mouse_update_colours();
}

static void write_position(void)
{
    int16_t x = pointer_x;
    int16_t y = pointer_y;

    v_set_write(VRAM_SPRITES);          /* sprite 0 */
    V_PUT((VRAM_POINTER >> 5) & 0xff);
    V_PUT((VRAM_POINTER >> 13) & 0x0f); /* 4 bpp */
    V_PUT(x & 0xff);
    V_PUT((x >> 8) & 0x03);             /* 10 bits: -1 is 1023 */
    V_PUT(y & 0xff);
    V_PUT((y >> 8) & 0x03);
    V_PUT(pointer_shown ? 0x0c : 0x00); /* Z: in front of the layers, or off */
    V_PUT(0x51);                        /* 16x16, palette offset 1 */
}

/* Write whatever changed, unless the VERA ports are in use */
void mouse_apply_pending(void)
{
    if (*vera_busy)
        return;

    (*vera_busy)++;
    VREG(V_CTRL) = 0;
    while (pending_shape || pending_position)
    {
        if (pending_shape)
        {
            pending_shape = 0;
            write_shape();
        }
        if (pending_position)
        {
            pending_position = 0;
            write_position();
        }
    }
    (*vera_busy)--;
}

/* Set up the arrow before the first vsc_form; call inside v_begin() */
void mouse_init(void)
{
    static const uint16_t arrow_mask[16] =
    {
        0xc000, 0xe000, 0xf000, 0xf800, 0xfc00, 0xfe00, 0xff00, 0xff80,
        0xffc0, 0xffe0, 0xfe00, 0xef00, 0xcf00, 0x8780, 0x0780, 0x0380
    };
    static const uint16_t arrow_data[16] =
    {
        0x0000, 0x4000, 0x6000, 0x7000, 0x7800, 0x7c00, 0x7e00, 0x7f00,
        0x7f80, 0x7c00, 0x6c00, 0x4600, 0x0600, 0x0300, 0x0300, 0x0000
    };
    uint16_t i;

    for (i = 0; i < 16; i++)
    {
        pointer_mask[i] = arrow_mask[i];
        pointer_data[i] = arrow_data[i];
    }
    pointer_shown = 0;
    write_shape();
    write_position();
}

long CDECL c_mouse_draw(Workstation *UNUSED(wk), long x, long y, Mouse *mouse)
{
    long op = (long)mouse;
    uint16_t i;

    switch (op)
    {
    case 0:     /* move, shown */
    case 4:     /* move, shown, forced */
    case 3:     /* show */
        pointer_x = (int16_t)x - hot_x;
        pointer_y = (int16_t)y - hot_y;
        pointer_shown = 1;
        pending_position = 1;
        break;
    case 2:     /* hide */
        pointer_shown = 0;
        pending_position = 1;
        break;
    default:
        if (op <= 7)
            return 0;
        /* a new shape (vsc_form) */
        for (i = 0; i < 16; i++)
        {
            pointer_mask[i] = mouse->mask[i];
            pointer_data[i] = mouse->data[i];
        }
        hot_x = mouse->hotspot.x & 0x0f;
        hot_y = mouse->hotspot.y & 0x0f;
        pointer_fg = tos_colours[mouse->colour.foreground & 0x0f];
        pointer_bg = tos_colours[mouse->colour.background & 0x0f];
        pending_shape = 1;
        break;
    }

    mouse_apply_pending();
    return 1;
}
