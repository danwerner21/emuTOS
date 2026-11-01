/*
 * Line drawing routines for Xosera, 4bpp.
 *
 * Implements FVDI driver API function c_line_draw().
 *
 */

#include "xosera.h"
#include "driver.h" /* For clip_line() */

#undef FVDI_DEBUG

static int
xosera_blit_horiz_line(volatile xmreg_t *const xosera_ptr, enum Mode mode, uint16_t dst_addr, uint16_t exp_fg,
                       uint16_t exp_bg,
                       uint16_t line_style, uint16_t shift, uint16_t wdwidth, uint16_t pf_words_per_line)
{
    uint16_t control = 0, src_s = 0;
    switch (mode) {
        case MODE_REPLACE:
            control = 0x0001;
            src_s = (exp_fg & line_style) | (exp_bg & ~line_style);
            break;
        case MODE_XOR:
            control = 0x0000;
            src_s = dst_addr;
            break;
        case MODE_TRANSPARENT:
            control = 0x0011;
            src_s = exp_fg & line_style;
            break;
        case MODE_REVERSE_TRANSPARENT:
            control = 0x0011;
            src_s = exp_fg & ~(line_style & 0xFFFF);
            break;
    }

    BlitParameters p = {
            .control = control,
            .andc = 0,
            .xor = mode == MODE_XOR ? (line_style & 0xFFFF) : 0,
            .src_s = src_s,
            .mod_s = pf_words_per_line - wdwidth,
            .dst_d = dst_addr,
            .mod_d = pf_words_per_line - wdwidth,
            .shift = shift,
            .words = wdwidth,
            .lines = 1
    };
    do_blit(xosera_ptr, &p);
    return 1;
}


static inline void swap(long *a, long *b)
{
    long temp = *a;
    *a = *b;
    *b = temp;
}

static inline int is_fast_pattern(const uint16_t exp_line_style[4])
{
    // A fast pattern/line style is defined as one that when expanded to 4bpp that each
    // word is the same. In this case (for horizontal lines) we can use the blitter without
    // having to write the pattern to VRAM.

    return (exp_line_style[0] == exp_line_style[1]) && (exp_line_style[0] == exp_line_style[2]) &&
           (exp_line_style[0] == exp_line_style[3]);
}

static int xosera_draw_horiz_line(volatile xmreg_t *const xosera_ptr, long x1, long x2, long y, uint16_t line_style,
                                  uint16_t fg, uint16_t bg, enum Mode mode, uint16_t pf_words_per_line)
{
    if (x1 == x2) return 0;

    uint16_t fore = expanded_color[fg & 0xF];
    uint16_t back = expanded_color[bg & 0xF];
    if (x1 > x2) swap(&x1, &x2); // FIXME: It may not be legit to swap these.
    uint16_t wdwidth = compute_word_width(x1, x2 - x1 + 1);
    uint16_t shift = compute_shift(x1, x2 - x1 + 1);
    uint16_t dest_addr = pf_words_per_line * y + (x1 >> 2);

    uint16_t exp_line_style[4];
    expand_word(exp_line_style, line_style);

    // If all four words of the expanded line style are the same, then we can do a single BLIT.
    if (is_fast_pattern(exp_line_style)) {
        uint16_t val = exp_line_style[0];
        if (mode == MODE_REPLACE) val = (fore & val) | (back & ~val);
        return xosera_blit_horiz_line(xosera_ptr, mode, dest_addr, fore, back,
                                      exp_line_style[0], shift & 0xFFFC, wdwidth, pf_words_per_line);
    }
    // Otherwise, we skip the blitter and write to VRAM ourselves.
    xm_setw(WR_ADDR, dest_addr);
    xm_setw(WR_INCR, 1);
    if (mode != MODE_REPLACE) {
        xm_setw(RD_INCR, 1);
        xm_setw(RD_ADDR, dest_addr);
    }
    uint16_t mask = (shift >> 12) & 0xF; // start with left mask
    uint16_t right_mask = (shift >> 8) & 0xF;
    uint16_t pattern_index = (x1 >> 2) & 3;
    for (uint16_t wd = 0; wd < wdwidth; wd++) {
        xm_setbl(SYS_CTRL, wd == wdwidth - 1 ? right_mask : mask);  // use right mask for last word
        uint16_t val = 0, old = 0;
        uint16_t pattern_mask = exp_line_style[pattern_index++];
        if (pattern_index == 4) pattern_index = 0;

        if (mode != MODE_REPLACE) old = vram_getw_next_wait();
        switch (mode) {
            case MODE_REPLACE:
                val = (fore & pattern_mask) | (back & ~pattern_mask);
                break;
            case MODE_XOR:
                val = old ^ pattern_mask;
                break;
            case MODE_TRANSPARENT:
                val = (fore & pattern_mask) | (old & ~pattern_mask);
                break;
            case MODE_REVERSE_TRANSPARENT:
                val = (fore & ~pattern_mask) | (old & pattern_mask);
                break;
        }
        vram_setw_next_wait(val);
        mask = 0xF;
    }
    return 1;
}

static int xosera_draw_vertical_line(volatile xmreg_t *const xosera_ptr, long x, long y1, long y2, uint16_t line_style,
                                     uint16_t fg, uint16_t bg, enum Mode mode, uint16_t pf_words_per_line)
{
    if (y1 == y2) return 0;

    // FIXME: I don't think it is legit to swap the Y values. Instead, always start at Y1 and increment or decrement as needed.
    if (y1 > y2) swap(&y1, &y2);

    uint16_t fore = expanded_color[fg & 0xF];
    uint16_t back = expanded_color[bg & 0xF];
    xm_setw(WR_INCR, pf_words_per_line);
    xm_setw(PIXEL_Y, y1);
    xm_setw(PIXEL_X, x);
    if (mode != MODE_REPLACE) {
        // Set up for read-modify-write
        uint16_t dest_addr = pf_words_per_line * y1 + (x >> 2);
        xm_setw(RD_INCR, pf_words_per_line);
        xm_setw(RD_ADDR, dest_addr);
    }
    uint16_t s = line_style >> (y1 & 0xF);
    for (long y = y1; y < y2; y++) {
        uint16_t val = 0, old = 0;
        if ((y & 0xF) == 0) s = line_style;
        if (mode != MODE_REPLACE) old = vram_getw_next_wait();
        switch (mode) {
            case MODE_REPLACE:
                val = s & 1 ? fore : back;
                break;
            case MODE_XOR:
                val = old ^ (s & 1 ? 0xFFFF : 0x0000);
                break;
            case MODE_TRANSPARENT:
                val = s & 1 ? fore : old;
                break;
            case MODE_REVERSE_TRANSPARENT:
                val = s & 1 ? old : fore;
        }
        s >>= 1;
        vram_setw_next_wait(val);
    }
    xm_setbl(SYS_CTRL, 0xF);
    return 1;
}

long CDECL c_line_draw(Virtual *vwk, long x1, long y1, long x2, long y2, long line_style_in, long colour, long mode)
{
    uint16_t line_style = (uint16_t) (line_style_in & 0xFFFF);
#ifdef FVDI_DEBUG
    PRINTF(("c_line_draw(): vwk = %p, x1 = %ld, y1 = %ld, x2 = %ld, y2 = %ld, style = 0x%04lx, mode = %ld (%s)\n",
            vwk, x1 & 0xFFFF, y1 & 0xFFFF, x2 & 0xFFFF, y2 & 0xFFFF, line_style_in & 0xFFFF, mode, mode2string(mode)));
#endif
    if ((long) vwk & 1) {
        long table_mode = y1 & 0xFFFF;
        if (table_mode == 0) { /* special mode 0 */
            Virtual *vwk_real = (Virtual *) ((uint32_t) (vwk) & ~1);

            short num_entries = (short) ((y1 >> 16) & 0xFFFF);
            long *table = (long *) x1;
            short x_start = (short) ((table[0] >> 16) & 0xFFFF);
            short y_start = (short) (table[0] & 0xFFFF);
            if (x_start == -1 || y_start == -1) return -1;
            for (int i = 1; i < num_entries; i++) {
                short x_end = (short) ((table[i] >> 16) & 0xFFFF);
                short y_end = (short) (table[i] & 0xFFFF);
                c_line_draw(vwk_real, x_start, y_start, x_end, y_end, line_style_in, colour, mode);
                x_start = x_end;
                y_start = y_end;
            }
            return 1;
        } else {
            // We currently don't handle special table mode 1.
            return -1;
        }
    }

    if (!clip_line(vwk, &x1, &y1, &x2, &y2)) return 1;

    volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);
    uint16_t pf_words_per_line = vwk->real_address->screen.mfdb.wdwidth;
    uint32_t hw_color = (uint32_t) c_get_colour(vwk, colour);
    uint16_t fg = hw_color & 0xFFFF, bg = (hw_color >> 16) & 0xFFFF;

    int result;
    if (y1 == y2) result = xosera_draw_horiz_line(xosera_ptr, x1, x2, y1, line_style, fg, bg, mode, pf_words_per_line);
    else if (x1 == x2)
        result = xosera_draw_vertical_line(xosera_ptr, x1, y1, y2, line_style, fg, bg, mode, pf_words_per_line);
    else result = 0; // Use FVDI engine fallback for lines that are neither horizontal nor vertical.

    xm_setbl(SYS_CTRL, 0xF);
    return result;
}
