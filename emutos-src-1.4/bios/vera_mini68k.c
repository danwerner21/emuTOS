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
 * in the VERA programmer's reference). EmuTOS keeps its usual Atari
 * screen in RAM, in one of the three ST resolutions, and this driver
 * copies it to a VERA bitmap at VRAM 0, letterboxed in the 640x480 VGA
 * picture (400 lines, the 200-line modes doubled):
 *
 *  ST high,   640x400, 2 colours:  VERA 1 bpp, 640 wide. Bit 7 of a byte
 *             is the leftmost pixel, as on the Atari: bytes are copied
 *             unchanged.
 *  ST medium, 640x200, 4 colours:  VERA 2 bpp, 640 wide.
 *  ST low,    320x200, 16 colours: VERA 4 bpp, 320 wide.
 *
 * In the colour modes, the Atari interleaves bit planes (one word of each
 * plane per 16 pixels) while VERA packs the bits of each pixel together,
 * so the copy converts through lookup tables. Both layouts use the same
 * number of bytes per 16 pixels, so a byte offset is the same in RAM and
 * in VRAM.
 *
 * Only the rows that changed are copied. The console (conout.c) and the
 * VDI dispatcher (vdi_main.c) mark the rows they draw on with
 * mini68k_screen_dirty(), and each VBL copies a limited number of marked
 * rows. The mouse pointer's box is copied when it moves, and a slow
 * background sweep catches programs that write to the screen directly.
 *
 * The VBL follows the VERA's VSYNC (60 Hz). The timer interrupt polls the
 * VSYNC flag, so the VERA IRQ line is not used and its jumper does not
 * matter. The VERA registers are only used from the VBL (and at startup):
 * resolution and palette changes are recorded, then applied at the next
 * VBL.
 *
 * Only writes are used: on this card, data port reads do not advance the
 * VRAM address (the VERA does not see the end of the read, because CS and
 * RD rise together on the ECB bus).
 */

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "asm.h"
#include "biosdefs.h"           /* ST_LOW, ST_MEDIUM, ST_HIGH */
#include "tosvars.h"            /* colorptr */
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
#define VERA_ISR        0x07    /* bit 0: VSYNC, write 1 to clear */
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

#define MAX_ROWS        400     /* rows in the tallest mode */
#define MAX_ROW_BYTES   160
#define POINTER_SIZE    16      /* mouse pointer: 16x16 pixels */

/*
 * The modes. Copy budgets: the colour conversion makes a byte cost about
 * 3 (medium) to 5 (low) times as much as in ST high, and colour rows are
 * twice as long. Each budget is about 8 ms of the 16.7 ms frame.
 */
struct vera_mode
{
    UBYTE hscale;           /* DC_HSCALE: 128 = 640 pixels, 64 = 320 */
    UBYTE vscale;           /* DC_VSCALE: 128 = 480 lines, 64 = 240 */
    UBYTE config;           /* L0_CONFIG: bitmap mode and colour depth */
    UBYTE tilebase;         /* L0_TILEBASE: bitmap at VRAM 0, width */
    UBYTE border;           /* border colour: Atari colour 0 or black */
    UBYTE group_bytes;      /* bytes per 16 pixels */
    UWORD row_bytes;
    UWORD rows;
    UWORD groups;           /* 16-pixel groups per row */
    UWORD rows_per_vbl;     /* copy budget */
    UWORD sweep_rows;       /* background sweep, when idle */
};

static const struct vera_mode vera_modes[3] =
{
    /* ST low: 4 bpp, 320 wide */
    { 64, 64, 0x06, 0x00, 0, 8, 160, 200, 20, 5, 2 },
    /* ST medium: 2 bpp, 640 wide */
    { 128, 64, 0x05, 0x01, 0, 4, 160, 200, 40, 8, 2 },
    /* ST high: 1 bpp, 640 wide */
    { 128, 128, 0x04, 0x01, 1, 2, 80, 400, 40, 48, 8 }
};

/* Atari default palette, as in screen.c (whose RGB_xxx names are only
 * defined with CONF_WITH_ATARI_VIDEO) */
static const UWORD default_palette[16] =
{
    0x0fff, 0x0f00, 0x00f0, 0x0ff0,     /* white, red, green, yellow */
    0x000f, 0x0f0f, 0x00ff, 0x0555,     /* blue, magenta, cyan, light grey */
    0x0333, 0x0f33, 0x03f3, 0x0ff3,     /* grey, light red, green, yellow */
    0x033f, 0x0f3f, 0x03ff, 0x0000      /* light blue, magenta, cyan, black */
};

/* VBL source, see mini68k_vbl_due() */
#define VBL_PROBING     0       /* waiting for the first VSYNC */
#define VBL_VSYNC       1       /* VBL at each VERA VSYNC */
#define VBL_TIMER       2       /* VBL every 4th timer tick (50 Hz) */
#define VSYNC_TIMEOUT   20      /* timer ticks (100 ms) without VSYNC */
#define TICKS_PER_VBL   4

/* The VDI's mouse form (bios/lineavars.S): hot spot x, y come first */
extern WORD mouse_cdb[];

static BOOL vera_present;
static const UBYTE *vera_screen;    /* RAM screen shown on the VERA */
static const struct vera_mode *mode;    /* mode shown on the VERA */
static WORD rez_shown;              /* its ST resolution */
static volatile WORD rez_wanted;    /* resolution set by Setscreen */
static UWORD palette[16];           /* Atari palette, 0x0RGB (STe format) */
static volatile BOOL palette_dirty; /* palette to write at the next VBL */
static UBYTE dirty[MAX_ROWS / 8];   /* rows to copy, bit 7 = first row */
static UWORD scan_row;              /* where the dirty row scan resumes */
static UWORD sweep_row;             /* next row of the background sweep */
static WORD box_x, box_y;           /* mouse pointer box last copied */
static UWORD vbl_source;            /* VBL_xxx */
static UWORD vbl_ticks;

/* Plane to packed pixel tables: bit k of a plane byte (pixel 7 - k)
 * becomes bit 2k (medium) or 4k (low) of the output, shifted by the
 * plane number. */
static UWORD medium_table[2][256];
static ULONG low_table[4][256];
static ULONG row_buf[MAX_ROW_BYTES / 4];    /* one converted row */

#define ROW_BIT(r)      (0x80 >> ((r) & 7))
#define IS_DIRTY(r)     (dirty[(r) >> 3] & ROW_BIT(r))

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

static void build_tables(void)
{
    UWORD x, k;

    for (x = 0; x < 256; x++)
    {
        UWORD s2 = 0;
        ULONG s4 = 0;

        for (k = 0; k < 8; k++)
        {
            if (x & (1 << k))
            {
                s2 |= 1U << (2 * k);
                s4 |= 1UL << (4 * k);
            }
        }
        medium_table[0][x] = s2;
        medium_table[1][x] = s2 << 1;
        for (k = 0; k < 4; k++)
            low_table[k][x] = s4 << k;
    }
}

/* Atari 4-bit colour component (STe: bit 3 is the low bit) to linear */
static UBYTE ste_to_vera(UWORD n)
{
    return ((n & 7) << 1) | ((n >> 3) & 1);
}

/* Write the 16 palette entries. VERA: GGGGBBBB, then 0000RRRR. */
static void write_palette(void)
{
    UWORD i;

    palette_dirty = FALSE;      /* before reading: a change meanwhile is kept */
    vera_set_addr(VERA_PALETTE);
    for (i = 0; i < 16; i++)
    {
        UWORD c = palette[i];
        VERA_REG(VERA_DATA0) = (ste_to_vera(c >> 4) << 4) | ste_to_vera(c);
        VERA_REG(VERA_DATA0) = ste_to_vera(c >> 8);
    }
}

/* Mark rows 0 to rows - 1 dirty (and no others) */
static void mark_all(UWORD rows)
{
    UWORD i;
    WORD old_sr = set_sr(0x2700);

    for (i = 0; i < MAX_ROWS / 8; i++)
        dirty[i] = (i < rows / 8) ? 0xff : 0;
    set_sr(old_sr);
}

/* Show the screen in the resolution set by Setscreen */
static void apply_mode(void)
{
    rez_shown = rez_wanted;
    mode = &vera_modes[rez_shown];

    VERA_REG(VERA_CTRL) = 0;    /* DCSEL = 0 */
    VERA_REG(VERA_DC1) = mode->hscale;
    VERA_REG(VERA_DC2) = mode->vscale;
    VERA_REG(VERA_DC3) = mode->border;
    VERA_REG(VERA_L0_CONFIG) = mode->config;
    VERA_REG(VERA_L0_TILEBASE) = mode->tilebase;

    scan_row = sweep_row = 0;
    mark_all(mode->rows);
}

/*
 * Detect the VERA and set up the ST high mode.
 * Return FALSE if there is no VERA: the system then runs as before,
 * on the serial console only.
 */
BOOL mini68k_vera_init(void)
{
    vera_present = vera_detect();
    KDEBUG(("VERA %s\n", vera_present ? "found" : "not found"));
    rez_wanted = ST_HIGH;
    mode = &vera_modes[ST_HIGH];
    if (!vera_present)
    {
        vbl_source = VBL_TIMER;
        return FALSE;
    }

    build_tables();

    VERA_REG(VERA_IEN) = 0;         /* VSYNC is polled, IRQ line unused */
    VERA_REG(VERA_ISR) = 0x07;      /* clear old interrupt flags */
    vbl_source = VBL_PROBING;

    VERA_REG(VERA_CTRL) = 0;        /* DCSEL = 0 */
    VERA_REG(VERA_DC0) = 0x00;      /* video off while setting up */

    VERA_REG(VERA_CTRL) = 1 << 1;   /* DCSEL = 1: active area */
    VERA_REG(VERA_DC0) = 0;         /* HSTART = 0 */
    VERA_REG(VERA_DC1) = 640 / 4;   /* HSTOP = 640 */
    VERA_REG(VERA_DC2) = 40 / 2;    /* VSTART = line 40 */
    VERA_REG(VERA_DC3) = 440 / 2;   /* VSTOP = line 440: 400 lines, centred */
    VERA_REG(VERA_CTRL) = 0;

    VERA_REG(VERA_L0_HSCROLL_H) = 0;    /* palette offset 0 */
    VERA_REG(VERA_L0_VSCROLL_L) = 0;
    VERA_REG(VERA_L0_VSCROLL_H) = 0;
    apply_mode();

    mini68k_init_palette(ST_HIGH);
    write_palette();

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
    mini68k_screen_dirty(0, MAX_ROWS - 1);
}

const UBYTE *mini68k_physbase(void)
{
    return vera_screen;
}

/* Setscreen: change the resolution, at the next VBL */
void mini68k_setrez(WORD rez)
{
    if (rez >= ST_LOW && rez <= ST_HIGH)
    {
        sshiftmod = rez;
        rez_wanted = rez;
    }
}

/* Setcolor: like an ST, return the old colour with 3 bits per component */
WORD mini68k_setcolor(WORD colorNum, WORD color)
{
    WORD old;

    colorNum &= 0x000f;
    old = palette[colorNum] & 0x0777;
    if (color >= 0)
    {
        palette[colorNum] = color & 0x0fff;
        palette_dirty = TRUE;
    }

    return old;
}

/* Default palette for a resolution, as initialise_palette_registers() */
void mini68k_init_palette(WORD rez)
{
    UWORD i;

    for (i = 0; i < 16; i++)
        palette[i] = default_palette[i];
    if (rez == ST_MEDIUM)
        palette[3] = palette[15];
    else if (rez == ST_HIGH)
        palette[1] = palette[15];
    palette_dirty = TRUE;
}

/* Convert groups of 16 pixels from Atari planes to VERA packed pixels */
static void convert_groups(const UBYTE *src, ULONG *dst, UWORD groups)
{
    if (rez_shown == ST_LOW)
    {
        do
        {
            dst[0] = low_table[0][src[0]] | low_table[1][src[2]]
                   | low_table[2][src[4]] | low_table[3][src[6]];
            dst[1] = low_table[0][src[1]] | low_table[1][src[3]]
                   | low_table[2][src[5]] | low_table[3][src[7]];
            dst += 2;
            src += 8;
        } while (--groups);
    }
    else    /* ST medium */
    {
        UWORD *d = (UWORD *)dst;

        do
        {
            d[0] = medium_table[0][src[0]] | medium_table[1][src[2]];
            d[1] = medium_table[0][src[1]] | medium_table[1][src[3]];
            d += 2;
            src += 4;
        } while (--groups);
    }
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
    if (first + count > (WORD)mode->rows)
        count = mode->rows - first;
    if (count <= 0)
        return;

    offset = (ULONG)first * mode->row_bytes;
    if (rez_shown == ST_HIGH)
    {
        mini68k_vera_copy(vera_screen + offset, offset, count * mode->row_bytes);
        return;
    }

    while (count--)
    {
        convert_groups(vera_screen + offset, row_buf, mode->groups);
        mini68k_vera_copy((const UBYTE *)row_buf, offset, mode->row_bytes);
        offset += mode->row_bytes;
    }
}

/* Copy the 16x16 pixel box at (left, top), clipped to the screen */
static void copy_box(WORD left, WORD top)
{
    WORD right = left + POINTER_SIZE - 1;
    WORD bottom = top + POINTER_SIZE - 1;
    WORD g, groups, bytes, row;

    if (left < 0)
        left = 0;
    if (right >= (WORD)(mode->groups * 16))
        right = mode->groups * 16 - 1;
    if (top < 0)
        top = 0;
    if (bottom >= (WORD)mode->rows)
        bottom = mode->rows - 1;
    if (left > right || top > bottom)
        return;

    g = left >> 4;
    groups = (right >> 4) - g + 1;
    bytes = groups * mode->group_bytes;

    for (row = top; row <= bottom; row++)
    {
        ULONG offset = (ULONG)row * mode->row_bytes + g * mode->group_bytes;
        const UBYTE *p = vera_screen + offset;
        WORD i;

        if (rez_shown != ST_HIGH)
        {
            convert_groups(p, row_buf, groups);
            p = (const UBYTE *)row_buf;
        }
        vera_set_addr(offset);
        for (i = 0; i < bytes; i++)
            VERA_REG(VERA_DATA0) = p[i];
    }
}

/*
 * Rows y1 to y2 (inclusive) of the screen have changed: copy them at the
 * next VBLs. Called by the console and the VDI after they have drawn.
 */
void mini68k_screen_dirty(WORD y1, WORD y2)
{
    WORD old_sr;

    if (y1 < 0)
        y1 = 0;
    if (y2 >= (WORD)vera_modes[rez_wanted].rows)
        y2 = vera_modes[rez_wanted].rows - 1;
    if (y1 > y2)
        return;

    old_sr = set_sr(0x2700);    /* the VBL clears bits */
    while (y1 <= y2 && (y1 & 7))
    {
        dirty[y1 >> 3] |= ROW_BIT(y1);
        y1++;
    }
    while (y1 + 7 <= y2)
    {
        dirty[y1 >> 3] = 0xff;
        y1 += 8;
    }
    while (y1 <= y2)
    {
        dirty[y1 >> 3] |= ROW_BIT(y1);
        y1++;
    }
    set_sr(old_sr);
}

/*
 * Copy up to budget dirty rows, in runs, starting where the previous scan
 * stopped. Return the unused budget: if it is not zero, no row is dirty.
 */
static WORD copy_dirty_rows(WORD budget)
{
    UWORD rows = mode->rows;    /* a multiple of 8 */
    UWORD row = scan_row;
    UWORD scanned = 0;

    while (budget > 0 && scanned < rows)
    {
        WORD first, count;
        WORD old_sr;

        if ((row & 7) == 0 && dirty[row >> 3] == 0)
        {
            row += 8;           /* 8 clean rows */
            scanned += 8;
        }
        else if (!IS_DIRTY(row))
        {
            row++;
            scanned++;
        }
        else
        {
            /* Clear the run before copying it: rows drawn on meanwhile
             * are marked again, and copied at a later VBL. */
            first = row;
            count = 0;
            old_sr = set_sr(0x2700);
            while (row < rows && count < budget && IS_DIRTY(row))
            {
                dirty[row >> 3] &= ~ROW_BIT(row);
                row++;
                count++;
            }
            set_sr(old_sr);

            copy_rows(first, count);
            budget -= count;
            scanned += count;
        }

        if (row >= rows)
            row = 0;
    }

    scan_row = row;
    return budget;
}

/*
 * Called at each VBL, from the timer interrupt with lower-priority
 * interrupts allowed, after the VDI has drawn the mouse pointer.
 *
 * A resolution or palette change is applied first. When the mouse has
 * moved, the pointer's old and new boxes are copied, so that it follows
 * the mouse at once. Then the dirty rows are copied, within the mode's
 * budget. When nothing is dirty, the background sweep copies a few rows.
 */
void mini68k_vera_vbl(void)
{
    const UWORD *new_palette;
    WORD left, top;

    if (!vera_present || !vera_screen || mini68k_fdc_active)
        return;     /* the floppy needs the CPU more than the screen */

    if (rez_shown != rez_wanted)
    {
        apply_mode();
        palette_dirty = TRUE;
    }

    /* Setpalette: like the Atari VBL, load the palette from colorptr */
    new_palette = (const UWORD *)((ULONG)colorptr & ~1UL);
    if (new_palette)
    {
        UWORD i;

        colorptr = NULL;
        for (i = 0; i < 16; i++)
            palette[i] = new_palette[i] & 0x0fff;
        palette_dirty = TRUE;
    }
    if (palette_dirty)
        write_palette();

    left = GCURX - mouse_cdb[0];
    top = GCURY - mouse_cdb[1];
    if (left != box_x || top != box_y)
    {
        copy_box(box_x, box_y);
        copy_box(left, top);
        box_x = left;
        box_y = top;
    }

    if (copy_dirty_rows(mode->rows_per_vbl) > 0)
    {
        copy_rows(sweep_row, mode->sweep_rows);
        sweep_row += mode->sweep_rows;
        if (sweep_row >= mode->rows)
            sweep_row = 0;
    }
}

/*
 * Called by the timer interrupt at each tick (200 Hz): is it time for a
 * VBL? The VBL follows the VERA VSYNC flag. If no VSYNC is seen soon
 * after startup (no VERA, or one that does not set the flag), fall back
 * to a 50 Hz VBL from the timer.
 */
BOOL mini68k_vbl_due(void)
{
    if (vbl_source != VBL_TIMER)
    {
        if (VERA_REG(VERA_ISR) & 0x01)
        {
            VERA_REG(VERA_ISR) = 0x01;  /* clear the VSYNC flag */
            vbl_source = VBL_VSYNC;
            return TRUE;
        }
        if (vbl_source == VBL_VSYNC || ++vbl_ticks < VSYNC_TIMEOUT)
            return FALSE;
        vbl_source = VBL_TIMER;
        vbl_ticks = 0;
    }

    if (++vbl_ticks < TICKS_PER_VBL)
        return FALSE;
    vbl_ticks = 0;
    return TRUE;
}

#endif /* MACHINE_MINI68K */
