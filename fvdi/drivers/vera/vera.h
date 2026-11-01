/*
 * fVDI driver for the VERA video card on the RetroBrew Mini-M68k
 *
 * Copyright (C) 2026 Dan Werner
 * Based on the Xosera driver by Rob Gowin, danodus and Xark.
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

/*
 * The VERA is not memory mapped: the CPU reaches its 128 KB of video RAM
 * through a few I/O ports, and it has no blitter. So this driver does
 * all its drawing with the CPU, through the ports:
 *
 *  - writes go through DATA1, whose address (ADDR1) auto-increments;
 *  - reads go through DATA0, with the address written before each byte
 *    (on this card, reads do not advance the address).
 *
 * The screen is a 640x240 or 640x400 bitmap of 16 colours, 4 bits per
 * pixel: two pixels per byte, the leftmost in the high nibble. Rows are
 * 320 bytes, at VRAM 0.
 *
 * EmuTOS shares the VERA: its text console and its VBL also use it. They
 * coordinate through the 'VERA' cookie (see emutos-src-1.4/bios/mini68k.h):
 * the driver increments EmuTOS's busy flag while it uses the ports, and
 * tells EmuTOS when it has taken the VERA over.
 */

#ifndef VERA_DRIVER_H
#define VERA_DRIVER_H

#include <stddef.h>         /* NULL */
#include <stdint.h>
#include "fvdi.h"

/* VERA registers: ECB ports 0x80-0x9f, at 0xffff8000 + port, supervisor only */
#define VERA_BASE       0xffff8080UL
#define VREG(r)         (*(volatile uint8_t *)(VERA_BASE + (r)))

#define V_ADDR_L        0x00
#define V_ADDR_M        0x01
#define V_ADDR_H        0x02    /* bit 0: address bit 16, bits 7-4: increment */
#define V_DATA0         0x03
#define V_DATA1         0x04
#define V_CTRL          0x05    /* bits 6-1: DCSEL, bit 0: ADDRSEL */
#define V_DC0           0x09    /* 0x09-0x0c depend on DCSEL */
#define V_DC1           0x0a
#define V_DC2           0x0b
#define V_DC3           0x0c
#define V_L0_CONFIG     0x0d
#define V_L0_MAPBASE    0x0e
#define V_L0_TILEBASE   0x0f
#define V_L0_HSCROLL_L  0x10
#define V_L0_HSCROLL_H  0x11
#define V_L0_VSCROLL_L  0x12
#define V_L0_VSCROLL_H  0x13
#define V_L1_CONFIG     0x14

#define V_INC1          0x10    /* auto-increment by 1, in V_ADDR_H */

#define VRAM_POINTER    0x1f400UL   /* mouse sprite: 16x16 at 4 bpp, 128 bytes */
#define VRAM_PALETTE    0x1fa00UL   /* 256 entries of 2 bytes */
#define VRAM_SPRITES    0x1fc00UL   /* 128 sprites of 8 bytes */

/* The 'VERA' cookie: the same structure as struct mini68k_vera_cookie
 * in emutos-src-1.4/bios/mini68k.h */
#define COOKIE_VERA     0x56455241L
struct vera_cookie
{
    uint16_t version;
    uint16_t reserved;
    volatile uint8_t *busy;
    void (*take_over)(long width, long height, long planes);
    void (*release_hook)(void);
    void (*kbd_hold)(long hold);    /* version 2, for VERATEST */
    void (*text_mode)(long on);     /* version 3, called by engine/escape.c */
};

/* Screen geometry, set by initialize() */
extern uint16_t screen_width, screen_height;
extern uint16_t bytes_per_line;     /* screen_width / 2 */

/* Port access (vera_io.c). Every drawing call is bracketed by v_begin()
 * and v_end(). */
extern volatile uint8_t *vera_busy;
void v_begin(void);
void v_end(void);

static inline void v_set_write(uint32_t addr)
{
    VREG(V_CTRL) = 1;           /* ADDRSEL = 1: ADDR1 */
    VREG(V_ADDR_L) = (uint8_t)addr;
    VREG(V_ADDR_M) = (uint8_t)(addr >> 8);
    VREG(V_ADDR_H) = V_INC1 | (uint8_t)((addr >> 16) & 1);
    VREG(V_CTRL) = 0;           /* back to ADDR0, for reads */
}

/* The same with another step: ADDR_H bits 7-4 the increment index,
 * bit 3 to count down (V_STEP_LINE: 320 bytes, one row) */
#define V_STEP_LINE     0xe0
#define V_STEP_DECR     0x08

static inline void v_set_write_step(uint32_t addr, uint8_t step)
{
    VREG(V_CTRL) = 1;
    VREG(V_ADDR_L) = (uint8_t)addr;
    VREG(V_ADDR_M) = (uint8_t)(addr >> 8);
    VREG(V_ADDR_H) = step | (uint8_t)((addr >> 16) & 1);
    VREG(V_CTRL) = 0;
}

#define V_PUT(b)    (VREG(V_DATA1) = (uint8_t)(b))

static inline uint8_t v_read(uint32_t addr)
{
    VREG(V_ADDR_H) = (uint8_t)((addr >> 16) & 1);  /* no increment */
    VREG(V_ADDR_M) = (uint8_t)(addr >> 8);
    VREG(V_ADDR_L) = (uint8_t)addr;                 /* fetches the byte */
    return VREG(V_DATA0);
}

/* In assembler (vera_io.c): all arguments are longs */
void v_read_run(uint8_t *dst, uint32_t addr, uint32_t count);
void v_write_run(const uint8_t *src, uint32_t count);  /* at ADDR1 */
void v_fill_run(uint32_t value, uint32_t count);        /* at ADDR1, low byte */

/* Colours (vera_pal.c) */
extern const uint8_t tos_colours[16];
uint8_t colour_byte(uint16_t hw_colour);    /* the colour in both pixels */
void write_hw_colour(uint16_t entry, uint16_t rgb);  /* VERA palette, 0x0RGB */
uint16_t read_hw_colour(uint16_t entry);    /* from the VERA, 0x0RGB; between v_begin() and v_end() */
void set_hw_colour(uint16_t hw, uint16_t rgb);  /* not between v_begin() and v_end() */

/* XBIOS Setcolor and Setpalette (vera_xbios.c) */
void xbios_init(void);

/* Blits (vera_blit.c) */
void blit_init(void);

/* Mouse pointer (vera_mouse.c) */
void mouse_apply_pending(void);
void mouse_init(void);              /* between v_begin() and v_end() */
void mouse_update_colours(void);    /* between v_begin() and v_end() */

static inline int is_screen(Workstation *wk, MFDB *mfdb)
{
    return mfdb == NULL || mfdb->address == NULL || mfdb->address == wk->screen.mfdb.address;
}

/* fVDI writing modes */
#define MODE_REPLACE                1
#define MODE_TRANSPARENT            2
#define MODE_XOR                    3
#define MODE_REVERSE_TRANSPARENT    4

/* Driver API functions */
long CDECL c_get_colour(Virtual *vwk, long colour);
void CDECL c_set_colours(Virtual *vwk, long start, long entries, unsigned short *requested, Colour palette[]);
long CDECL c_write_pixel(Virtual *vwk, MFDB *mfdb, long x, long y, long colour);
long CDECL c_read_pixel(Virtual *vwk, MFDB *mfdb, long x, long y);
long CDECL c_line_draw(Virtual *vwk, long x1, long y1, long x2, long y2, long pattern, long colour, long mode);
long CDECL c_expand_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y,
                         long w, long h, long operation, long colour);
long CDECL c_fill_area(Virtual *vwk, long x, long y, long w, long h, short *pattern, long colour, long mode,
                       long interior_style);
long CDECL c_blit_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y,
                       long w, long h, long operation);
long CDECL c_mouse_draw(Workstation *wk, long x, long y, Mouse *mouse);

/* Shared by fill and line drawing (vera_fill.c) */
void fill_span(uint16_t x1, uint16_t x2, uint16_t y, uint16_t pattern, uint8_t fg, uint8_t bg, long mode);

/* Row buffers for building a screen row before writing it (vera_io.c).
 * Longs, so rows can be combined 4 bytes (8 pixels) at a time. Enough for
 * 1024 pixels; the screen is at most 640. Used by one call at a time. */
#define ROW_LONGS   132
extern uint32_t row_dst[ROW_LONGS];     /* the screen row as it was */
extern uint32_t row_out[ROW_LONGS];     /* the row to write */

#ifdef __GNUC__
#  define UNUSED(x) UNUSED_ ## x __attribute__((__unused__))
#else
#  define UNUSED(x) UNUSED_ ## x
#endif

#endif
