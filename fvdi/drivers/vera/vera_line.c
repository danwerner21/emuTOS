/*
 * Line drawing for the VERA fVDI driver.
 *
 * Copyright (C) 2026 Dan Werner
 * Based on the Xosera driver by Rob Gowin, danodus and Xark.
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

#include "vera.h"
#include "driver.h"         /* clip_line() */

/*
 * Lines are drawn a byte (two pixels) at a time. The change each pixel
 * makes to its byte is an AND mask and an XOR value, and they combine;
 * when the line moves on to another byte, the old byte is read only if
 * part of it shows through, then changed and written. The write address
 * is set again only when the byte is not where the VERA has stepped it
 * to: the next byte along the row for flat lines, the next row for
 * steep ones.
 */
struct line_state
{
    uint32_t cur;               /* the byte being built */
    uint8_t and_mask, xor_val;  /* its change so far */
    uint16_t read_page;         /* ADDR0 bits 16-8 as last set, for reads */
    uint32_t next_write;        /* where the VERA's write address is */
    long write_step;            /* how it moves after each write */
    uint8_t step_code;          /* ADDR_H increment bits for that */
};

static inline void line_flush(struct line_state *s)
{
    uint8_t b;

    if (s->and_mask == 0xff && s->xor_val == 0)
        return;                 /* nothing drawn in this byte */
    if (s->and_mask == 0)
        b = s->xor_val;         /* both pixels replaced: no read */
    else
    {
        const uint16_t page = (uint16_t)(s->cur >> 8);

        if (page != s->read_page)
        {
            s->read_page = page;
            VREG(V_ADDR_H) = (uint8_t)((page >> 8) & 1);    /* no increment */
            VREG(V_ADDR_M) = (uint8_t)page;
        }
        VREG(V_ADDR_L) = (uint8_t)s->cur;                   /* fetches the byte */
        b = (VREG(V_DATA0) & s->and_mask) ^ s->xor_val;
    }
    if (s->cur != s->next_write)
        v_set_write_step(s->cur, s->step_code);
    V_PUT(b);
    s->next_write = s->cur + s->write_step;
}

/* ops: index (line style bit set ? 2 : 0) + (right pixel of its byte ? 1 : 0) */
static inline void line_pixel(struct line_state *s, uint32_t addr, int i, const uint8_t *op_and, const uint8_t *op_xor)
{
    if (addr != s->cur)
    {
        line_flush(s);
        s->cur = addr;
        s->and_mask = 0xff;
        s->xor_val = 0;
    }
    s->xor_val = (s->xor_val & op_and[i]) ^ op_xor[i];
    s->and_mask &= op_and[i];
}

/* What each writing mode does to a pixel, for the line style bit clear
 * or set, in the left or the right half of a byte */
static void line_ops(uint8_t fg, uint8_t bg, long mode, uint8_t *op_and, uint8_t *op_xor)
{
    const uint8_t fgb = colour_byte(fg), bgb = colour_byte(bg);
    int i;

    for (i = 0; i < 4; i++)
    {
        const int on = i & 2;
        const uint8_t nibble = (i & 1) ? 0x0f : 0xf0;
        int draw;
        uint8_t c = fgb;

        if (mode == MODE_XOR)
        {
            op_and[i] = 0xff;
            op_xor[i] = on ? nibble : 0;
            continue;
        }
        if (mode == MODE_TRANSPARENT)
            draw = on;
        else if (mode == MODE_REVERSE_TRANSPARENT)
            draw = !on;
        else    /* MODE_REPLACE */
        {
            draw = 1;
            if (!on)
                c = bgb;
        }
        op_and[i] = draw ? (uint8_t)~nibble : 0xff;
        op_xor[i] = draw ? (c & nibble) : 0;
    }
}

/* Any line but a horizontal one: Bresenham, both ends included. The
 * line style is used from its top bit, one bit per pixel. */
static void draw_line(long x1, long y1, long x2, long y2, uint16_t style, uint8_t fg, uint8_t bg, long mode)
{
    long dx = x2 - x1, dy = y2 - y1;
    const long sx = (dx < 0) ? -1 : 1;
    const long row_step = (dy < 0) ? -(long)bytes_per_line : (long)bytes_per_line;
    uint32_t row = (uint32_t)(uint16_t)y1 * bytes_per_line;
    uint8_t op_and[4], op_xor[4];
    struct line_state s;
    uint16_t bit = 0x8000;
    long err, n;

    line_ops(fg, bg, mode, op_and, op_xor);
    if (dx < 0)
        dx = -dx;
    if (dy < 0)
        dy = -dy;

    s.cur = 0xffffffffUL;       /* no byte yet */
    s.and_mask = 0xff;
    s.xor_val = 0;
    s.read_page = 0xffff;
    s.next_write = 0xffffffffUL;
    if (dx >= dy)               /* along the row */
    {
        s.write_step = sx;
        s.step_code = V_INC1 | ((sx < 0) ? V_STEP_DECR : 0);
    }
    else if (bytes_per_line == 320)     /* a row down or up */
    {
        s.write_step = row_step;
        s.step_code = V_STEP_LINE | ((row_step < 0) ? V_STEP_DECR : 0);
    }
    else                        /* no such step: set the address each time */
    {
        s.write_step = 0;
        s.step_code = V_INC1;
    }

    if (dx >= dy)
    {
        err = dx / 2;
        for (n = dx; n >= 0; n--)
        {
            line_pixel(&s, row + (x1 >> 1), ((style & bit) ? 2 : 0) | (x1 & 1), op_and, op_xor);
            bit = (bit >> 1) ? (bit >> 1) : 0x8000;
            x1 += sx;
            err -= dy;
            if (err < 0)
            {
                row += row_step;
                err += dx;
            }
        }
    }
    else
    {
        err = dy / 2;
        for (n = dy; n >= 0; n--)
        {
            line_pixel(&s, row + (x1 >> 1), ((style & bit) ? 2 : 0) | (x1 & 1), op_and, op_xor);
            bit = (bit >> 1) ? (bit >> 1) : 0x8000;
            row += row_step;
            err -= dx;
            if (err < 0)
            {
                x1 += sx;
                err += dy;
            }
        }
    }
    line_flush(&s);
}

long CDECL c_line_draw(Virtual *vwk, long x1, long y1, long x2, long y2, long pattern, long colour, long mode)
{
    long hw;
    uint8_t fg, bg;

    if ((long)vwk & 1)
    {
        /* Special mode 0: a table of points, drawn as a polyline */
        if ((y1 & 0xffff) == 0)
        {
            Virtual *real_vwk = (Virtual *)((long)vwk & ~1L);
            short entries = (short)((y1 >> 16) & 0xffff);
            long *table = (long *)x1;
            short i;
            long xs = (table[0] >> 16) & 0xffff;
            long ys = table[0] & 0xffff;

            if (xs == 0xffff || ys == 0xffff)
                return -1;
            for (i = 1; i < entries; i++)
            {
                long xe = (table[i] >> 16) & 0xffff;
                long ye = table[i] & 0xffff;

                c_line_draw(real_vwk, (short)xs, (short)ys, (short)xe, (short)ye, pattern, colour, mode);
                xs = xe;
                ys = ye;
            }
            return 1;
        }
        return -1;      /* special mode 1: let the engine do it */
    }

    if (!clip_line(vwk, &x1, &y1, &x2, &y2))
        return 1;

    hw = c_get_colour(vwk, colour);
    fg = hw & 0xff;
    bg = (hw >> 16) & 0xff;

    v_begin();
    if (y1 == y2)
    {
        if (x1 > x2)
        {
            long t = x1;
            x1 = x2;
            x2 = t;
        }
        fill_span(x1, x2, y1, (uint16_t)pattern, fg, bg, mode);
    }
    else
        draw_line(x1, y1, x2, y2, (uint16_t)pattern, fg, bg, mode);
    v_end();
    return 1;
}
