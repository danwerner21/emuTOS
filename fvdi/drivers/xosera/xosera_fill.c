/*
 * Fill routines for Xosera.
 *
 * Implements driver API function c_fill_area().
 */

#include "xosera.h"
#include "driver.h"

#undef FVDI_DEBUG

extern uint16_t expand_table[];

void expand_word(uint16_t *dest, uint16_t val)
{
    uint16_t hi_index = ((val >> 8) & 0xFF) << 1, lo_index = (val & 0xFF) << 1;
    dest[0] = expand_table[hi_index];
    dest[1] = expand_table[hi_index + 1];
    dest[2] = expand_table[lo_index];
    dest[3] = expand_table[lo_index + 1];
}

static void expand_pattern_4bpp(uint16_t *dest, const uint16_t *pattern)
{
    for (int i = 0; i < 16; i++) {
        expand_word(dest, pattern[i]);
        dest += 4;
    }
}

// Copy the VDI pattern to Xosera's VRAM. The patterns come in as 16 16-bit words, which we need to expand to
// 64 16-bit words.
static void copy_pattern_to_vram_4pp(volatile xmreg_t *const xosera_ptr, uint16_t vram_addr, const uint16_t *pattern)
{
    xm_setw(WR_INCR, 1);
    xm_setw(WR_ADDR, vram_addr);
    for (int i = 0; i < 64; i++) {
        vram_setw_next_wait(pattern[i]);
    }
}

static void blit_horiz(volatile xmreg_t *const xosera_ptr, BlitParameters *p, uint16_t x0, uint16_t width,
                       uint16_t src_addr, uint16_t dst_addr, uint16_t pf_words_per_line)
{
    uint16_t x_pos = x0;

    while (width) {
        uint16_t src_addr_this_blit = src_addr;
        // Blit to the next sixteen pixel boundary
        uint16_t next_x = (x_pos + 16) & ~0xF;
        uint16_t pixels_this_blit = next_x - x_pos;
        if (pixels_this_blit > width) pixels_this_blit = width;
        uint16_t words_this_blit = compute_word_width(x_pos, pixels_this_blit);

        // If not starting from a sixteen pixel boundary, adjust pattern starting point (source address).
        if (x_pos & 0xF) src_addr_this_blit += 4 - words_this_blit;

        xm_setbl(SYS_CTRL, 0xF);

        p->shift = compute_lr_masks_4bpp(x_pos, pixels_this_blit);
        p->src_s = src_addr_this_blit;
        p->dst_d = dst_addr;
        p->mod_s = 4 - words_this_blit;
        p->mod_d = pf_words_per_line - words_this_blit;
        p->words = words_this_blit;
        do_blit(xosera_ptr, p);

        dst_addr += words_this_blit;
        width -= pixels_this_blit;
        x_pos += pixels_this_blit;
    }
}

static void xosera_pattern_fill(volatile xmreg_t *const xosera_ptr, uint16_t x0, uint16_t y0, uint16_t w, uint16_t h,
                                uint16_t color, uint16_t mode, uint16_t src_addr, uint16_t pf_words_per_line)
{
    uint16_t exp_color = expanded_color[color];
    const uint16_t pattern_vram = 0xFFC0;
    uint16_t dst_addr = y0 * pf_words_per_line + (x0 >> 2);
    const int max_lines_per_blit = 16;
    xm_setbl(SYS_CTRL, 0xF);

    BlitParameters p = {
            .control = mode == MODE_TRANSPARENT ? MAKE_BLIT_CTRL(0xFF, 0, 1, 0) : MAKE_BLIT_CTRL(0x00, 0, 0, 0),
            .andc    = (mode == MODE_TRANSPARENT) ? exp_color : ~exp_color,
            .xor     = 0,
            .src_s   = src_addr,
            .mod_s   = 0,
            .dst_d   = dst_addr,
            .mod_d   = pf_words_per_line - 4,
            .shift   = 0xff00
    };
    int lines_remaining = h;
    uint16_t next_y = (y0 + 16) & ~0xF;
    uint16_t lines_this_time = next_y - y0;

    // Do the first blit up to a 16-line boundary
    // Offset the source address for this first blit based on y address.

    src_addr = pattern_vram + (y0 & 0xF) * 4;
    if (lines_this_time < 16) {
        if (lines_this_time > h) lines_this_time = h;
        p.lines = lines_this_time;
        blit_horiz(xosera_ptr, &p, x0, w, src_addr, dst_addr, pf_words_per_line);
        dst_addr += pf_words_per_line * lines_this_time;
        lines_remaining -= lines_this_time;
    }
    src_addr = pattern_vram;

    while (lines_remaining > 0) {
        lines_this_time = lines_remaining > max_lines_per_blit ? max_lines_per_blit : lines_remaining;
        p.lines = lines_this_time;
        blit_horiz(xosera_ptr, &p, x0, w, src_addr, dst_addr, pf_words_per_line);
        dst_addr += pf_words_per_line * lines_this_time;
        lines_remaining -= lines_this_time;
    }
}

void do_blit(volatile xmreg_t *const xosera_ptr, BlitParameters *p)
{
    xwait_blit_ready();
    xreg_setw(BLIT_CTRL, p->control);
    xreg_setw(BLIT_ANDC, p->andc);
    xreg_setw(BLIT_XOR, p->xor);
    xreg_setw(BLIT_MOD_S, p->mod_s);
    xreg_setw(BLIT_SRC_S, p->src_s);
    xreg_setw(BLIT_MOD_D, p->mod_d);
    xreg_setw(BLIT_DST_D, p->dst_d);
    xreg_setw(BLIT_SHIFT, p->shift);
    xreg_setw(BLIT_LINES, p->lines > 0 ? p->lines - 1 : 0);
    xreg_setw(BLIT_WORDS, p->words - 1);
}

static void xosera_solid_fill(volatile xmreg_t *const xosera_ptr, uint16_t x0, uint16_t y0, uint16_t w, uint16_t h,
                              uint16_t color, enum Mode mode, uint16_t pf_words_per_line)
{
    uint16_t wdwidth = compute_word_width(x0, w);
    uint16_t dst_addr = y0 * pf_words_per_line + (x0 >> 2);

    BlitParameters p = {
            .control = MAKE_BLIT_CTRL(0, 0, 0, mode == MODE_XOR ? 0 : 1),
            .andc = 0,
            .xor =  mode == MODE_XOR ? 0xFFFF : 0,
            .src_s = mode == MODE_XOR ? dst_addr : expanded_color[color],
            .mod_s = pf_words_per_line - wdwidth,
            .dst_d = dst_addr,
            .mod_d = pf_words_per_line - wdwidth,
            .shift = compute_lr_masks_4bpp(x0, w),
            .lines = h,
            .words = wdwidth
    };
    do_blit(xosera_ptr, &p);
}

static int is_solid_pattern(const uint16_t *pattern)
{
    for (int i = 0; i < 16; i++) {
        if (pattern[i] != 0xFFFF) return 0;
    }
    return 1;
}

long CDECL c_fill_area(Virtual *vwk, long x0, long y0, long w, long h, short *pattern, long colour, long mode,
                       long interior_style)
{
    // Reject special mode. The engine will then call us in normal mode.
    if ((long) (vwk) & 1) return -1;
#ifdef FVDI_DEBUG
    dump_fill_area_params(x0, y0, w, h, colour, mode, interior_style);
#endif
    volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);
    uint16_t pf_words_per_line = vwk->real_address->screen.mfdb.wdwidth;
    long hw_color = c_get_colour(vwk, colour & 0xFFFF);
    int16_t fill_type = (int16_t)((interior_style >> 16) & 0xFFFF);
    int16_t pattern_index = (int16_t)(interior_style & 0xFFFF);

    int solid_pattern = (fill_type == 0) || (fill_type == 1) || ((fill_type == 2) && (pattern_index == 8)) ||
            is_solid_pattern((const uint16_t *) pattern);

    if (mode == MODE_XOR || solid_pattern) {
        xosera_solid_fill(xosera_ptr, x0, y0, w, h, hw_color, mode, pf_words_per_line);
    } else {
        // FIXME: May need special handling for MODE_REVERSE_TRANSPARENT
        uint16_t exp_pattern[64];
        const uint16_t vram_src_addr = 0xFFC0;
        expand_pattern_4bpp(exp_pattern, (const uint16_t *) pattern);
        copy_pattern_to_vram_4pp(xosera_ptr, vram_src_addr, exp_pattern);
        xosera_pattern_fill(xosera_ptr, x0, y0, w, h, hw_color, mode, vram_src_addr, pf_words_per_line);
    }
    return 1;
}
