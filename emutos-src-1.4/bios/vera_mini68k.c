/*
 * vera_mini68k.c - VERA video card support for the Mini-M68k
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The VERA card sits on the ECB bus at ports 0x80-0x9f (32 registers, as
 * in the VERA programmer's reference). EmuTOS keeps its usual monochrome
 * 640x400 screen (ST high) in RAM, and this driver copies it to a VERA
 * 1 bpp bitmap of the same layout, letterboxed in the 640x480 VGA picture.
 * Bit 7 of a byte is the leftmost pixel, as on the Atari, so the bytes
 * are copied unchanged.
 *
 * For now the whole screen is copied round robin: a slice of rows at each
 * vertical blank. Copying only the rows that changed comes later.
 *
 * Only writes are used: on this card, data port reads do not advance the
 * VRAM address (the VERA does not see the end of the read, because CS and
 * RD rise together on the ECB bus).
 */

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "mini68k.h"
#include "../vdi/vdi_defs.h"     /* GCURX, GCURY: mouse position */

#ifdef MACHINE_MINI68K

#define VERA_REG(r)     (*(volatile UBYTE *)MINI68K_ECB_IO(MINI68K_VERA_PORT + (r)))

#define VERA_ADDR_L     0x00
#define VERA_ADDR_M     0x01
#define VERA_ADDR_H     0x02    /* bit 0: address bit 16, bits 7-4: increment */
#define VERA_DATA0      0x03
#define VERA_CTRL       0x05    /* bits 6-1: DCSEL, bit 0: ADDRSEL */
#define VERA_IEN        0x06
#define VERA_DC0        0x09    /* 0x09-0x0c depend on DCSEL */
#define VERA_DC1        0x0a
#define VERA_DC2        0x0b
#define VERA_DC3        0x0c
#define VERA_L0_CONFIG  0x0d
#define VERA_L0_TILEBASE 0x0f
#define VERA_L0_HSCROLL_H 0x11
#define VERA_L0_VSCROLL_L 0x12
#define VERA_L0_VSCROLL_H 0x13

#define VERA_INC1       0x10    /* auto-increment by 1, in VERA_ADDR_H */
#define VERA_PALETTE    0x1fa00L

/* The screen: 400 rows of 80 bytes, at VRAM 0 */
#define SCREEN_ROWS     400
#define ROW_BYTES       80
#define ROWS_PER_VBL    25      /* a full screen every 16 VBLs (0.32 s) */
#define POINTER_ROWS    16      /* mouse pointer height */

static BOOL vera_present;
static const UBYTE *vera_screen;    /* RAM screen shown on the VERA */
static UWORD next_row;              /* next row to copy */

/*
 * Is a VERA answering? Its address registers must read back what was
 * written (a floating bus returns the last byte the CPU fetched).
 */
static BOOL vera_detect(void)
{
    UWORD i;

    VERA_REG(VERA_CTRL) = 0;
    for (i = 0; i < 256; i += 0x55)
    {
        VERA_REG(VERA_ADDR_L) = i;
        VERA_REG(VERA_ADDR_M) = i ^ 0xff;
        if (VERA_REG(VERA_ADDR_L) != i || VERA_REG(VERA_ADDR_M) != (i ^ 0xff))
            return FALSE;
    }

    return TRUE;
}

static void vera_set_addr(ULONG addr)
{
    VERA_REG(VERA_CTRL) = 0;    /* ADDRSEL = 0: DATA0 */
    VERA_REG(VERA_ADDR_L) = LOBYTE(addr);
    VERA_REG(VERA_ADDR_M) = HIBYTE(addr);
    VERA_REG(VERA_ADDR_H) = ((addr >> 16) & 1) | VERA_INC1;
}

/*
 * Detect the VERA and set up the 640x400 1 bpp mode.
 * Return FALSE if there is no VERA: the system then runs as before,
 * on the serial console only.
 */
BOOL mini68k_vera_init(void)
{
    vera_present = vera_detect();
    KDEBUG(("VERA %s\n", vera_present ? "found" : "not found"));
    if (!vera_present)
        return FALSE;

    VERA_REG(VERA_IEN) = 0;         /* no interrupts yet */

    VERA_REG(VERA_CTRL) = 0;        /* DCSEL = 0 */
    VERA_REG(VERA_DC0) = 0x00;      /* video off while setting up */
    VERA_REG(VERA_DC1) = 128;       /* HSCALE 1:1, 640 pixels */
    VERA_REG(VERA_DC2) = 128;       /* VSCALE 1:1, 480 lines */
    VERA_REG(VERA_DC3) = 1;         /* border: palette entry 1 (black) */

    VERA_REG(VERA_CTRL) = 1 << 1;   /* DCSEL = 1: active area */
    VERA_REG(VERA_DC0) = 0;         /* HSTART = 0 */
    VERA_REG(VERA_DC1) = 640 / 4;   /* HSTOP = 640 */
    VERA_REG(VERA_DC2) = 40 / 2;    /* VSTART = line 40 */
    VERA_REG(VERA_DC3) = 440 / 2;   /* VSTOP = line 440: 400 lines, centred */
    VERA_REG(VERA_CTRL) = 0;

    VERA_REG(VERA_L0_CONFIG) = 0x04;    /* bitmap mode, 1 bpp */
    VERA_REG(VERA_L0_TILEBASE) = 0x01;  /* bitmap at VRAM 0, 640 pixels wide */
    VERA_REG(VERA_L0_HSCROLL_H) = 0;    /* palette offset 0 */
    VERA_REG(VERA_L0_VSCROLL_L) = 0;
    VERA_REG(VERA_L0_VSCROLL_H) = 0;

    /* Atari monochrome: 0 = white paper, 1 = black ink.
     * Palette entries are 2 bytes: GGGGBBBB, then 0000RRRR. */
    vera_set_addr(VERA_PALETTE);
    VERA_REG(VERA_DATA0) = 0xff;    /* entry 0: white */
    VERA_REG(VERA_DATA0) = 0x0f;
    VERA_REG(VERA_DATA0) = 0x00;    /* entry 1: black */
    VERA_REG(VERA_DATA0) = 0x00;

    VERA_REG(VERA_DC0) = 0x11;      /* VGA output, layer 0 only */

    return TRUE;
}

BOOL mini68k_vera_present(void)
{
    return vera_present;
}

/* Screen address hooks for screen.c (Setscreen, Physbase) */
void mini68k_setphys(const UBYTE *addr)
{
    vera_screen = addr;
    next_row = 0;
}

const UBYTE *mini68k_physbase(void)
{
    return vera_screen;
}

/* Copy rows [first, first + count), clipped to the screen */
static void copy_rows(WORD first, WORD count)
{
    ULONG offset;

    if (first < 0)
    {
        count += first;
        first = 0;
    }
    if (first + count > SCREEN_ROWS)
        count = SCREEN_ROWS - first;
    if (count <= 0)
        return;

    offset = (ULONG)first * ROW_BYTES;
    mini68k_vera_copy(vera_screen + offset, offset, count * ROW_BYTES);
}

/*
 * Called at each VBL, from the timer interrupt with lower-priority
 * interrupts allowed, after the VDI has drawn the mouse pointer.
 *
 * When the mouse has moved, the rows around its old and new positions
 * are copied, so that the pointer follows the mouse at once. Otherwise,
 * the next slice of the whole screen is copied (round robin).
 */
void mini68k_vera_vbl(void)
{
    static WORD last_x, last_y;
    WORD x, y;
    UWORD rows;
    ULONG offset;

    if (!vera_present || !vera_screen || mini68k_fdc_active)
        return;     /* the floppy needs the CPU more than the screen */

    x = GCURX;
    y = GCURY;
    if (x != last_x || y != last_y)
    {
        /* the pointer image spans at most 16 rows around its hot spot */
        WORD top = (y < last_y ? y : last_y) - POINTER_ROWS;
        WORD bottom = (y > last_y ? y : last_y) + POINTER_ROWS;

        if (bottom - top <= 4 * POINTER_ROWS)
            copy_rows(top, bottom - top);
        else
        {
            copy_rows(last_y - POINTER_ROWS, 2 * POINTER_ROWS);
            copy_rows(y - POINTER_ROWS, 2 * POINTER_ROWS);
        }
        last_x = x;
        last_y = y;
        return;
    }

    rows = SCREEN_ROWS - next_row;
    if (rows > ROWS_PER_VBL)
        rows = ROWS_PER_VBL;

    offset = (ULONG)next_row * ROW_BYTES;
    mini68k_vera_copy(vera_screen + offset, offset, rows * ROW_BYTES);

    next_row += rows;
    if (next_row >= SCREEN_ROWS)
        next_row = 0;
}

#endif /* MACHINE_MINI68K */
