/*
 * Rectangle fill for the VERA fVDI driver.
 *
 * Copyright (C) 2026 Dan Werner
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

#include "vera.h"
#include "driver.h"

/* Two pixels to a byte: a 2-bit pixel mask (left pixel in bit 1) to the
 * nibbles holding them */
static const uint8_t pair_mask[4] = { 0x00, 0x0f, 0xf0, 0xff };

/*
 * Draw pixels x1 to x2 (inclusive) of row y with a 16-pixel pattern
 * word, aligned on the screen (bit 15 is the pixel at x = 0 mod 16).
 * Writing modes, as in the VDI: replace draws fg where the pattern is
 * set and bg elsewhere; transparent draws fg where it is set; reverse
 * transparent where it is clear; XOR inverts the pixels where it is set.
 * Call between v_begin() and v_end().
 */
void fill_span(uint16_t x1, uint16_t x2, uint16_t y, uint16_t pattern, uint8_t fg, uint8_t bg, long mode)
{
    uint8_t value[8], mask[8];      /* per byte of the pattern's 16 pixels */
    const uint8_t fgb = colour_byte(fg), bgb = colour_byte(bg);
    const uint32_t row = (uint32_t)y * bytes_per_line;
    const uint16_t b1 = x1 >> 1, b2 = x2 >> 1;
    const uint16_t nb = b2 - b1 + 1;
    uint8_t lmask = (x1 & 1) ? 0x0f : 0xff;
    const uint8_t rmask = (x2 & 1) ? 0xff : 0xf0;
    uint8_t uniform = 1;
    uint16_t k, i, n;
    union { uint8_t b[8]; uint32_t l[2]; } v, m;    /* the pattern from b1 on */
    uint8_t *const dst = (uint8_t *)row_dst;
    uint8_t *const out = (uint8_t *)row_out;

    for (k = 0; k < 8; k++)
    {
        uint8_t pm = pair_mask[(pattern >> (14 - 2 * k)) & 3];

        switch (mode)
        {
        case MODE_TRANSPARENT:
            value[k] = fgb;
            mask[k] = pm;
            break;
        case MODE_REVERSE_TRANSPARENT:
            value[k] = fgb;
            mask[k] = ~pm;
            break;
        case MODE_XOR:
            value[k] = 0xff;
            mask[k] = pm;
            break;
        default:    /* MODE_REPLACE */
            value[k] = (pm & fgb) | (~pm & bgb);
            mask[k] = 0xff;
            break;
        }
        if (value[k] != value[0] || mask[k] != mask[0])
            uniform = 0;
    }
    if (b1 == b2)
        lmask &= rmask;

    if (uniform && mask[0] == 0)
        return;     /* nothing to draw */

    /* Solid (or vertically striped): the edges, and a run between them */
    if (uniform && mask[0] == 0xff && mode != MODE_XOR)
    {
        const uint8_t c = value[0];

        v_set_write(row + b1);
        if (lmask != 0xff)
            V_PUT((v_read(row + b1) & ~lmask) | (c & lmask));
        else
            V_PUT(c);
        if (nb > 1)
        {
            v_fill_run(c, nb - 2);
            if (rmask != 0xff)
                V_PUT((v_read(row + b2) & ~rmask) | (c & rmask));
            else
                V_PUT(c);
        }
        return;
    }

    /*
     * Anything else: build the row 4 bytes at a time and write it whole.
     * The old row is read where it shows through: everywhere, except in
     * the replace mode, where only the edges need it.
     */
    if (mode == MODE_REPLACE)
    {
        dst[0] = v_read(row + b1);
        dst[nb - 1] = v_read(row + b2);
    }
    else
        v_read_run(dst, row + b1, nb);

    for (k = 0; k < 8; k++)
    {
        v.b[k] = value[(b1 + k) & 7];
        m.b[k] = mask[(b1 + k) & 7];
    }
    n = (nb + 3) >> 2;
    if (mode == MODE_XOR)
        for (i = 0; i < n; i++)
            row_out[i] = row_dst[i] ^ m.l[i & 1];
    else if (mode == MODE_REPLACE)
        for (i = 0; i < n; i++)
            row_out[i] = v.l[i & 1];
    else
        for (i = 0; i < n; i++)
            row_out[i] = (row_dst[i] & ~m.l[i & 1]) | (v.l[i & 1] & m.l[i & 1]);

    out[0] = (out[0] & lmask) | (dst[0] & ~lmask);
    if (nb > 1)
        out[nb - 1] = (out[nb - 1] & rmask) | (dst[nb - 1] & ~rmask);

    v_set_write(row + b1);
    v_write_run(out, nb);
}

long CDECL c_fill_area(Virtual *vwk, long x, long y, long w, long h, short *pattern, long colour, long mode,
                       long UNUSED(interior_style))
{
    long hw, x2, y2, j;
    uint8_t fg, bg;

    /* Reject the special (table) mode: the engine then calls us normally */
    if ((long)vwk & 1)
        return -1;

    /* stay on the screen */
    x2 = x + w - 1;
    y2 = y + h - 1;
    if (x < 0)
        x = 0;
    if (y < 0)
        y = 0;
    if (x2 >= screen_width)
        x2 = screen_width - 1;
    if (y2 >= screen_height)
        y2 = screen_height - 1;
    if (x > x2 || y > y2)
        return 1;

    hw = c_get_colour(vwk, colour);
    fg = hw & 0xff;
    bg = (hw >> 16) & 0xff;

    v_begin();
    for (j = y; j <= y2; j++)
        fill_span(x, x2, j, pattern ? (uint16_t)pattern[j & 15] : 0xffff, fg, bg, mode);
    v_end();
    return 1;
}
