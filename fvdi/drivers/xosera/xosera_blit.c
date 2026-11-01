/*
 * BLIT routines for Xosera, 4 bits per pixel.
 *
 * Implements FVDI driver API functions c_expand_area() and c_blit_area().
 */

#include "fvdi.h"
#include <stdint.h>
#include "xosera.h"
#include "driver.h"

#include <osbind.h>

/* #undef FVDI_DEBUG */

#define OPER_NOT_D 10

static uint16_t
screen_to_screen(volatile xmreg_t *const xosera_ptr, uint16_t src_addr, uint16_t dst_addr, uint16_t src_x,
                 uint16_t w, uint16_t h, long operation, uint16_t pf_words_per_line)
{
    uint16_t num_words = compute_word_width(src_x, w);
    uint16_t mod = pf_words_per_line - num_words;

    BlitParameters p = {
            .control = 0,
            .andc = 0,
            .xor = operation == OPER_NOT_D ? 0xFFFF : 0,
            .src_s = src_addr,
            .mod_s = mod,
            .dst_d = dst_addr,
            .mod_d = mod,
            .shift = compute_lr_masks_4bpp(src_x, w),
            .lines = h,
            .words = num_words,
    };
    do_blit(xosera_ptr, &p);
    return h * num_words;
}

static uint16_t
screen_to_screen_reverse(volatile xmreg_t *const xosera_ptr, uint16_t dst_x, uint16_t dst_y, uint16_t src_x,
                         uint16_t src_y, uint16_t w, uint16_t h, long operation, uint16_t pf_words_per_line)
{
    // Start the transfer at the highest addressed Y.
    uint16_t src_num_words = compute_word_width(src_x, w);
    uint16_t dst_num_words = compute_word_width(dst_x, w);

    BlitParameters p = {
            .control = 0,
            .andc = 0,
            .xor = operation == OPER_NOT_D ? 0xFFFF : 0,
            .src_s = (src_y + h - 1) * pf_words_per_line + (src_x >> 2),
            .mod_s = -(pf_words_per_line + src_num_words),
            .dst_d = (dst_y + h - 1) * pf_words_per_line + (dst_x >> 2),
            .mod_d = -(pf_words_per_line + dst_num_words),
            .shift = compute_lr_masks_4bpp(src_x, w),
            .lines = h,
            .words = src_num_words
    };
    do_blit(xosera_ptr, &p);
    return h * dst_num_words;
}

static uint16_t save_to_vram(volatile xmreg_t *const xosera_ptr, uint16_t vram_save_address, uint16_t src_x,
                             uint16_t src_y, uint16_t w, uint16_t h, uint16_t pf_words_per_line)
{
    uint16_t num_words = compute_word_width(src_x, w);
    PRINTF(("save_to_vram: src_s: 0x%04x, mod_s: %d, dst_d: 0x%04x, mod_d: %d, num_words = %d\n",
            src_y * pf_words_per_line + (src_x >> 2), pf_words_per_line - num_words, vram_save_address, 0, num_words));
    BlitParameters p = {
            .control = 0,
            .andc = 0x0000,
            .xor = 0x0000,
            .src_s = src_y * pf_words_per_line + (src_x >> 2),
            .mod_s = pf_words_per_line - num_words,
            .dst_d = vram_save_address,
            .mod_d = 0, /* Save to contiguous VRAM save area. */
            .shift = 0xFF00, // no need for LR masks when saving offscreen.
            .lines = h, .words = num_words
    };
    do_blit(xosera_ptr, &p);
    return h * num_words;
}

static void restore_to_screen(volatile xmreg_t *const xosera_ptr, uint16_t vram_save_address, uint16_t dst_x,
                              uint16_t dst_y, uint16_t w, uint16_t h, uint16_t src_wdwidth,
                              uint16_t pf_words_per_line)
{
    uint16_t num_words = compute_word_width(dst_x, w);
    if (num_words > src_wdwidth) src_wdwidth = num_words;
    PRINTF(("restore to screen: dst_d: 0x%04x, mod_d: %d, src_s: 0x%04x, mod_s: %d, num_words = %d, src_wdwidth = %d\n",
            dst_y * pf_words_per_line + (dst_x >> 2), pf_words_per_line - num_words, vram_save_address, src_wdwidth - num_words, num_words, src_wdwidth));
    BlitParameters p = {
            .control = 0,
            .andc = 0x0000,
            .xor = 0x0000,
            .dst_d = dst_y * pf_words_per_line + (dst_x >> 2),
            .mod_d = pf_words_per_line - num_words,
            .src_s = vram_save_address,
            .mod_s = src_wdwidth - num_words,
            .shift = compute_lr_masks_4bpp(dst_x, w),
            .lines = h, .words = num_words
    };
    do_blit(xosera_ptr, &p);

}

static void expand_blit(volatile xmreg_t *const xosera_ptr, uint16_t source_addr, uint16_t dst_x, uint16_t dst_y,
                        uint16_t width, uint16_t height, uint16_t exp_color, uint16_t src_wdwidth, enum Mode mode,
                        uint16_t pf_words_per_line)
{
    uint16_t wdwidth = compute_word_width(dst_x, width);

    // If the incoming color is zero, but the mode is transparent, then we need to do some special handling.
    uint16_t control = 0, andc = ~exp_color, xor = 0;
    if (mode == MODE_TRANSPARENT) {
        control |= 0x0010;
        if (exp_color == 0) {
            xor = 0xFFFF;
            andc = 0x0;
        }
    }
    BlitParameters p = {
            .control = control,
            .andc = andc,
            .xor = xor,
            .src_s = source_addr,
            .mod_s = src_wdwidth - wdwidth,
            .dst_d = dst_y * pf_words_per_line + (dst_x >> 2),
            .mod_d = pf_words_per_line - wdwidth,
            .shift = compute_shift(dst_x, width),
            .words = wdwidth,
            .lines = height,
    };
    do_blit(xosera_ptr, &p);
}


long CDECL
c_expand_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y, long w, long h,
              long operation, long colour)
{
    int src_is_screen = is_screen(vwk->real_address, src);
    int dst_is_screen = is_screen(vwk->real_address, dst);
#if 0
    static uint16_t exp_seq = 0;
    long fg = colour & 0xFFFF;
    long bg = (colour >> 16) & 0xFFFF;
    kprintf("c_expand_area()[%d]: src: is_screen? %s x: %ld, y: %ld\n", exp_seq++, src_is_screen ? "yes" : "no", src_x, src_y);
    kprintf("               dst: is_screen? %s x: %ld, y: %ld\n", dst_is_screen ? "yes" : "no", dst_x, dst_y);
    kprintf("               w: %ld, h: %ld, operation: %ld (%s), colour = 0x%08lx, fg = %ld, bg = %ld\n", w, h, operation,
            operation2string(operation), colour, fg, bg);
    kprintf("               dst_x: %ld, dst_t: %ld\n", dst_x, dst_y);
#endif

    const uint16_t vram_save_address = 0xD000; // FIXME: Do proper VRAM management here.
    if (!src_is_screen && dst_is_screen) {
        volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);
        uint16_t buffer[4];

        if (src_x != 0 || src_y != 0) return 0; /* Expect src pos to be 0,0; fallback if not. */
        xm_setw(WR_INCR, 1);
        xm_setw(WR_ADDR, vram_save_address);
        short *p = src->address;

        // Expand the incoming monochrome bitmap to 4 bits per pixel.
        for (short y = 0; y < src->height; y++) {
            for (short word = 0; word < src->wdwidth; word++) {
                uint16_t word_val = *p++;
                expand_word(buffer, word_val);
                for (int i = 0; i < 4; i++) vram_setw_next_wait(buffer[i]);
            }
        }
        // Blit the newly created off-screen pixmap to the screen
        long hw_color = c_get_colour(vwk, colour & 0xFFFF) & 0xF;
        expand_blit(xosera_ptr, vram_save_address, dst_x, dst_y, w, h, expanded_color[hw_color],
                    src->wdwidth * 4, operation, vwk->real_address->screen.mfdb.wdwidth);
        return 1;
    }
    return 0;
}
#if 0

// The code below is work in progress for handling c_expand_area() without the use of extra VRAM. This will
// evenutally be useful for 640x400x4 mode where there is only 3K of offscreen VRAM available.

long CDECL
c_expand_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y, long w, long h,
               long operation, long colour)
{
    int src_is_screen = is_screen(vwk->real_address, src);
    int dst_is_screen = is_screen(vwk->real_address, dst);
    uint16_t dest_width = compute_word_width(dst_x, w);

#if 0
    static uint16_t exp_seq = 0;
    long fg = colour & 0xFFFF;
    long bg = (colour >> 16) & 0xFFFF;
    kprintf("\nc_expand_area()[%d]: src: is_screen? %s x: %ld, y: %ld\n", exp_seq++, src_is_screen ? "yes" : "no", src_x, src_y);
    kprintf("               dst: is_screen? %s x: %ld, y: %ld\n", dst_is_screen ? "yes" : "no", dst_x, dst_y);
    kprintf("               w: %ld, h: %ld, operation: %ld (%s), colour = 0x%08lx, fg = %ld, bg = %ld\n", w, h, operation,
            operation2string(operation), colour, fg, bg);
    kprintf("               dst_x: %ld, dst_y: %ld, dest_width (words): %d\n", dst_x, dst_y, dest_width);
    dump_MFDB("src", src);
    dump_MFDB("dst", dst);
#endif
    if (!src_is_screen && dst_is_screen) {
        if (src_x != 0 || src_y != 0) return 0; /* Expect src pos to be 0,0; fallback if not. */
        volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);
        uint16_t pf_words_per_line = vwk->real_address->screen.mfdb.wdwidth;
        uint16_t buffer[4];
        //long hw_color = c_get_colour(vwk, colour);
        //long fg = expanded_color[(hw_color & 0xF)]; //, bg = expanded_color[(hw_color >> 16) & 0xF];
        uint16_t shift = compute_shift(dst_x, w);

        xm_setw(WR_INCR, 1);
        uint16_t mask = (shift >> 12) & 0xF; // start with left mask
        uint16_t right_mask = (shift >> 8) & 0xF;

        // Expand the incoming monochrome bitmap to 4 bits per pixel.
        uint16_t dest_word_count = (w + 15) / 16;
        for (long y = 0; y < h; y++) {
            uint16_t dest_word = 0;
            uint16_t dest_addr = pf_words_per_line * (dst_y + y) + (dst_x >> 2);
            xm_setw(WR_ADDR, dest_addr);
            short *p = src->address + y * src->wdwidth;
            for (uint16_t word = 0; word < dest_word_count; word++) {
                uint16_t word_val = *p++;
                expand_word(buffer, word_val);
                for (int i = 0; i < 4; i++) {
                    uint16_t val = buffer[i]; // & fg;
                    xm_setbl(SYS_CTRL, dest_word == dest_width - 1 ? right_mask : mask);
                    vram_setw_next_wait(val); // FIXME: what to do about the background color?
                    dest_word++;
                    if (dest_word == dest_width) break;
                }
                mask = 0xF;
            }
        }
        return 1;
    }
    return 0;
}
#endif
#ifdef FVDI_DEBUG

void dump_MFDB(const char *name, const MFDB *m)
{
    if (m == NULL) PRINTF(("MFDB[%s] is NULL.\n", name));
    else if (m->address == NULL) PRINTF(("MFDB[%s]: address = NULL\n", name));
    else {
        PRINTF(("MFDB[%s]: address = %p, w = %d, h = %d, wdwidth = %d, std = %d, bitp = %d\n", name, m->address, m->width,
                m->height, m->wdwidth, m->standard, m->bitplanes));
    }
}

#endif

long CDECL
c_blit_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y, long w, long h,
            long operation)
{
    int vram_save_address = 0xA000; /* FIXME: Don't hardcode this. */
    int src_is_screen = is_screen(vwk->real_address, src);
    int dst_is_screen = is_screen(vwk->real_address, dst);
    uint16_t pf_words_per_line = vwk->real_address->screen.mfdb.wdwidth;

#ifdef FVDI_DEBUG
    static uint16_t blit_seq = 0;
    kprintf("\nc_blit_area()[%d]: src: is_screen? %s x: %ld, y: %ld\n", blit_seq++, src_is_screen ? "yes" : "no", src_x, src_y);
    kprintf("               dst: is_screen? %s x: %ld, y: %ld\n", dst_is_screen ? "yes" : "no", dst_x, dst_y);
    kprintf("               w: %ld, h: %ld, operation: %ld (%s)\n", w, h, operation,
            operation2string(operation));
    dump_MFDB("src", src);
    dump_MFDB("dest", dst);
#endif
    volatile xmreg_t *const xosera_ptr = xv_prep_dyn(me->device);

    if (src_is_screen && !dst_is_screen) {
        uint16_t width = w > dst->width ? w : dst->width;
        save_to_vram(xosera_ptr, vram_save_address, src_x, src_y, width, h, pf_words_per_line);
    }
    if (src_is_screen && dst_is_screen) {
        uint16_t src_addr = src_y * pf_words_per_line + (src_x >> 2);
        uint16_t dst_addr = dst_y * pf_words_per_line + (dst_x >> 2);
        if ((dst_addr < src_addr) || operation == OPER_NOT_D) {
            screen_to_screen(xosera_ptr, src_addr, dst_addr, src_x, w, h, operation, pf_words_per_line);
        } else if (src_y != dst_y) {
            screen_to_screen_reverse(xosera_ptr, dst_x, dst_y, src_x, src_y, w, h, operation, pf_words_per_line);
        } else {
            save_to_vram(xosera_ptr, vram_save_address, src_x, src_y, w, h, pf_words_per_line);
            restore_to_screen(xosera_ptr, vram_save_address, dst_x, dst_y, w, h,
                              compute_word_width(dst_x, w), pf_words_per_line);
        }
    }
    if (!src_is_screen && dst_is_screen) {
        //uint16_t width = w > src->width ? w : src->width;
        PRINTF(("restoring screen: w = %ld, src->width = %d\n", w, src->width));

        uint16_t src_wdwidth = compute_word_width(dst_x, src->width - src_x);
        restore_to_screen(xosera_ptr, vram_save_address + (src_x >> 2), dst_x, dst_y, w, h,
                          src_wdwidth, pf_words_per_line);
    }
    if (!src_is_screen && !dst_is_screen) {
        return 0; /* fallback for now */
    }
#if 1
    PRINTF(("Press a key to continue...\n"));
    KEY_WAIT(10);
#endif
    return 1;
}
