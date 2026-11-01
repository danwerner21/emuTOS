#ifndef INCLUDE_XOSERA_H
#define INCLUDE_XOSERA_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "fvdi.h"

#include "xosera_m68k_api.h"

// A lookup table to take a color in 4 bits and expand it to sixteen, e.g A => 0xAAAA
extern uint16_t expanded_color[];

void xosera_palette_register_write(volatile xmreg_t *xosera_ptr, uint8_t palette, uint16_t data);

/* Function prototypes. */
long CDECL c_get_colour(Virtual *vwk, long colour);

void CDECL c_get_colours(Virtual *vwk, long colour, unsigned long *foreground, unsigned long *background);

void CDECL c_set_colours(Virtual *vwk, long start, long entries, unsigned short *requested, Colour palette[]);

long CDECL c_write_pixel(Virtual *vwk, MFDB *mfdb, long x, long y, long colour);

long CDECL c_read_pixel(Virtual *vwk, MFDB *mfdb, long x, long y);

long CDECL c_line_draw(Virtual *vwk, long x1, long y1, long x2, long y2, long line_style, long colour, long mode);

long CDECL
c_expand_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y, long w, long h,
              long operation, long colour);

long CDECL
c_fill_area(Virtual *vwk, long x, long y, long w, long h, short *pattern, long colour, long mode, long interior_style);

//long CDECL (*fill_poly_r)(Virtual *vwk, short points[], long n, short index[], long moves, short *pattern, long colour, long mode, long interior_style);
long CDECL
c_blit_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y, long w, long h,
            long operation);

//long CDECL (*text_area_r)(Virtual *vwk, short *text, long length, long dst_x, long dst_y, short *offsets);
long CDECL c_mouse_draw(Workstation *wk, long x, long y, Mouse *mouse);

const char *mode2string(long mode);

const char *operation2string(long operation);

void expand_word(uint16_t *dest, uint16_t val);
static inline int is_screen(struct wk_ *wk, MFDB *mfdb)
{
    return (mfdb == NULL || mfdb->address == NULL || mfdb->address == wk->screen.mfdb.address) ? 1 : 0;
}

enum Mode {
    MODE_REPLACE = 1,
    MODE_TRANSPARENT = 2,
    MODE_XOR = 3,
    MODE_REVERSE_TRANSPARENT = 4
};

typedef struct BlitParameters {
    uint16_t control;
    uint16_t andc;
    uint16_t xor;
    uint16_t src_s;
    uint16_t mod_s;
    uint16_t dst_d;
    uint16_t mod_d;
    uint16_t shift;
    uint16_t lines;
    uint16_t words;
} BlitParameters;

static inline volatile xmreg_t *xv_prep_dyn(Device *device)
{
    return (volatile xmreg_t *) device->address;
}

static inline uint16_t compute_lr_masks_4bpp(uint16_t x0, uint16_t w)
{
    static const uint8_t fw_mask[4] = {0xF0, 0x70, 0x30, 0x10};
    static const uint8_t lw_mask[4] = {0x0F, 0x08, 0x0C, 0x0E};
    return (fw_mask[x0 & 3] | lw_mask[(x0 + w) & 3]) << 8;
}

static inline uint16_t compute_shift(uint16_t x0, uint16_t w)
{
    return compute_lr_masks_4bpp(x0, w) | (x0 & 3);
}

static inline uint16_t compute_word_width(uint16_t x0, uint16_t width)
{
    return ((width + (x0 & 3) + 3)) / 4;
}

void do_blit(volatile xmreg_t *xosera_ptr, BlitParameters *p);

void dump_fill_area_params(long x0, long y0, long w, long h, long colour, long mode, long interior_style);
void dump_MFDB(const char *name, const MFDB *m);

#ifdef __GNUC__
#  define UNUSED(x) UNUSED_ ## x __attribute__((__unused__))
#else
#  define UNUSED(x) UNUSED_ ## x
#endif

#endif
