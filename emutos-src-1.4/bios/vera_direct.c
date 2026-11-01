/*
 * vera_direct.c - direct drawing into the VERA card on the Mini-M68k
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * With CONF_WITH_VERA_DIRECT, the VERA bitmap at VRAM 0 is the screen:
 * the console and the VDI draw into it through the VERA ports, and
 * nothing is copied at the VBL. The three ST resolutions are shown as
 * 1 bpp (ST high, 640x400), 2 bpp (ST medium, 640x200) and 4 bpp (ST low,
 * 320x200) bitmaps.
 *
 * The Atari screen layout (bit planes interleaved by words) and the VERA
 * one (the bits of a pixel packed together) use the same number of bytes
 * per 16 pixels, so the offset of a 16-pixel group is the same in both.
 * In ST high, the layouts are identical, byte for byte.
 *
 * Port use: writes go through DATA1, with ADDR1 set by vd_set_write().
 * Reads go through DATA0, with ADDR0 in bank 0 and no increment: on this
 * card data reads do not advance the address, so the address is written
 * before each read (vd_read_byte(), vd_read()).
 *
 * Each drawing operation is bracketed by vd_begin() and vd_end(). While
 * one is in progress (mini68k_vera_busy), the VBL leaves the VERA alone:
 * no cursor blink, sprite or palette update until the next VBL.
 *
 * The RAM screen at v_bas_ad stays allocated (for programs that use
 * Logbase()), and serves as a scratch buffer: drawing code that is not
 * converted yet runs between vd_bounce_read(), which loads the area it
 * draws on from the VERA (converting to bit planes), and
 * vd_bounce_write(), which writes it back.
 */

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "lineavars.h"
#include "tosvars.h"            /* v_bas_ad */
#include "conout.h"
#include "intmath.h"            /* divu() */
#include "mini68k.h"
#include "vera.h"

#if CONF_WITH_VERA_DIRECT

#define MAX_ROW_BYTES   160
#define MAX_RUN         0x8000U /* longest run for vd_fill() and vd_copy() */

static ULONG row_buf[MAX_ROW_BYTES / 4];    /* one row of VERA pixels */

void vd_begin(void)
{
    mini68k_vera_busy++;
    VERA_REG(VERA_CTRL) = 0;            /* ADDRSEL = 0: ADDR0 */
}

/*
 * When the VERA is free again, an fVDI driver that owns it (see
 * mini68k_vera_take_over()) may have work waiting, such as a mouse
 * pointer move that arrived in an interrupt while we were drawing.
 */
void vd_end(void)
{
    if (--mini68k_vera_busy == 0 && mini68k_vera_cookie.release_hook)
        mini68k_vera_cookie.release_hook();
}

/*
 * Set the address of the next DATA1 write, with an increment. VRAM
 * addresses have 17 bits: a 640x240 or 640x400 16-colour screen (set by
 * an fVDI driver) is larger than 64 KB.
 */
void vd_set_write(ULONG addr, UBYTE inc)
{
    VERA_REG(VERA_CTRL) = 1;            /* ADDRSEL = 1: ADDR1 */
    VERA_REG(VERA_ADDR_L) = LOBYTE(addr);
    VERA_REG(VERA_ADDR_M) = HIBYTE(addr);
    VERA_REG(VERA_ADDR_H) = inc | ((addr >> 16) & 1);
    VERA_REG(VERA_CTRL) = 0;
}

UBYTE vd_read_byte(ULONG addr)
{
    VERA_REG(VERA_ADDR_H) = (addr >> 16) & 1;   /* no increment */
    VERA_REG(VERA_ADDR_M) = HIBYTE(addr);
    VERA_REG(VERA_ADDR_L) = LOBYTE(addr);   /* the VERA fetches the byte */
    return VERA_REG(VERA_DATA0);
}

/* vd_fill() and vd_copy() for any length: DATA1 keeps incrementing */
static void fill_long(UWORD value, ULONG count)
{
    while (count)
    {
        UWORD n = (count > MAX_RUN) ? MAX_RUN : (UWORD)count;

        vd_fill(value, n);
        count -= n;
    }
}

static void copy_long(ULONG src, ULONG count)
{
    while (count)
    {
        UWORD n = (count > MAX_RUN) ? MAX_RUN : (UWORD)count;

        vd_copy(src, n);
        src += n;
        count -= n;
    }
}

/* A colour index repeated over the pixels of a VERA byte */
UBYTE vd_colour_byte(UWORD colour)
{
    switch(v_planes) {
    case 4:
        return (colour & 0x0f) * 0x11;
    case 2:
        return (colour & 0x03) * 0x55;
    default:
        return (colour & 1) ? 0xff : 0x00;
    }
}

/*
 * Clip a rectangle to the screen and widen it to whole 16-pixel groups
 * (the VDI code works on words of each plane). Return the byte offset of
 * its first group in each row, and the number of bytes and groups per
 * row; FALSE if nothing is left.
 */
static BOOL clip_groups(WORD x1, WORD y1, WORD x2, WORD y2, WORD *top,
                        WORD *bottom, UWORD *left, UWORD *bytes, UWORD *groups)
{
    WORD t;

    if (x1 > x2)
    {
        t = x1; x1 = x2; x2 = t;
    }
    if (y1 > y2)
    {
        t = y1; y1 = y2; y2 = t;
    }
    if (x1 < 0)
        x1 = 0;
    if (y1 < 0)
        y1 = 0;
    if (x2 >= (WORD)V_REZ_HZ)
        x2 = V_REZ_HZ - 1;
    if (y2 >= (WORD)V_REZ_VT)
        y2 = V_REZ_VT - 1;
    if (x1 > x2 || y1 > y2)
        return FALSE;

    *top = y1;
    *bottom = y2;
    *groups = (x2 >> 4) - (x1 >> 4) + 1;
    *left = (x1 >> 4) * v_planes * 2;
    *bytes = *groups * v_planes * 2;
    return TRUE;
}

/* Load a rectangle of the screen from the VERA into the RAM screen */
void vd_bounce_read(WORD x1, WORD y1, WORD x2, WORD y2)
{
    WORD y, bottom;
    UWORD left, bytes, groups, off;

    if (!clip_groups(x1, y1, x2, y2, &y, &bottom, &left, &bytes, &groups))
        return;

    for (off = y * v_lin_wr + left; y <= bottom; y++, off += v_lin_wr)
    {
        if (v_planes == 1)
            vd_read(v_bas_ad + off, off, bytes);
        else
        {
            vd_read((UBYTE *)row_buf, off, bytes);
            mini68k_from_vera((const UBYTE *)row_buf, v_bas_ad + off, groups, v_planes);
        }
    }
}

/* Write a rectangle of the RAM screen back to the VERA */
void vd_bounce_write(WORD x1, WORD y1, WORD x2, WORD y2)
{
    WORD y, bottom;
    UWORD left, bytes, groups, off;

    if (!clip_groups(x1, y1, x2, y2, &y, &bottom, &left, &bytes, &groups))
        return;

    for (off = y * v_lin_wr + left; y <= bottom; y++, off += v_lin_wr)
    {
        vd_set_write(off, VERA_INC1);
        if (v_planes == 1)
            vd_write(v_bas_ad + off, bytes);
        else
        {
            mini68k_to_vera(v_bas_ad + off, row_buf, groups, v_planes);
            vd_write((const UBYTE *)row_buf, bytes);
        }
    }
}

/* v_clrwk: clear the whole screen to colour 0 */
void vd_clear(void)
{
    vd_begin();
    vd_set_write(0, VERA_INC1);
    fill_long(0x00, (ULONG)v_lin_wr * V_REZ_VT);
    vd_end();
}

/*
 * Pixel masks: for a byte of font data (8 pixels), the VERA bytes that
 * hold those pixels, with all the bits of each set pixel set (1, 2 or 4
 * VERA bytes, leftmost first). Returns the number of bytes.
 */
WORD vd_expand_byte(UBYTE g, UBYTE *masks)
{
    static const UBYTE nibble_2bpp[16] =    /* 4 pixels of 2 bits */
    {
        0x00, 0x03, 0x0c, 0x0f, 0x30, 0x33, 0x3c, 0x3f,
        0xc0, 0xc3, 0xcc, 0xcf, 0xf0, 0xf3, 0xfc, 0xff
    };
    static const UBYTE pair_4bpp[4] = { 0x00, 0x0f, 0xf0, 0xff };

    switch(v_planes) {
    case 4:
        masks[0] = pair_4bpp[g >> 6];
        masks[1] = pair_4bpp[(g >> 4) & 3];
        masks[2] = pair_4bpp[(g >> 2) & 3];
        masks[3] = pair_4bpp[g & 3];
        return 4;
    case 2:
        masks[0] = nibble_2bpp[g >> 4];
        masks[1] = nibble_2bpp[g & 0x0f];
        return 2;
    default:
        masks[0] = g;
        return 1;
    }
}

/*
 * Console (conout.c): character cells are 8 pixels wide (1, 2 or 4 VERA
 * bytes) and v_cel_ht rows tall. conout.c passes the cell's address in
 * the RAM screen; in the colour modes, the byte of a cell within its
 * 16-pixel group is not where the VERA has it, so convert to a VERA
 * offset.
 */
static ULONG cell_offset(const UBYTE *cell)
{
    ULONG off = cell - v_bas_ad;
    UWORD row, col;

    if (v_planes == 1)
        return off;

    row = divu(off, v_lin_wr);
    col = off - (ULONG)row * v_lin_wr;
    col = (col / (v_planes * 2)) * 2 + (col & 1);   /* character column */
    return (ULONG)row * v_lin_wr + col * v_planes;
}

/*
 * Text mode. While GEM is in text mode (fVDI's v_enter_cur, through the
 * 'VERA' cookie), the console uses a VERA tile layer instead of drawing
 * into fVDI's bitmap: a character is 2 bytes in the tile map, and a
 * scroll of the whole screen moves the layer's vertical scroll, where in
 * the 4-bit bitmap it copied 120 KB through the ports.
 *
 * Layer 1 shows a 128 x 32 map of 1 bpp tiles, 8 pixels wide and as tall
 * as the console font; each entry is a tile number (the font's byte
 * offset for the character) and an attribute byte (background colour in
 * the high nibble, foreground in the low one). The 32 map rows are a
 * ring: screen row y is map row (text_top + y) & 31. The map and the
 * tiles go in the bitmap's VRAM, which fVDI clears when it enters and
 * when it leaves text mode; the bitmap layer and the sprites are off
 * meanwhile. fVDI's register settings come back when text mode ends.
 */
#define TEXT_MAP        0x1c000L    /* 128 x 32 entries of 2 bytes */
#define TEXT_TILES      0x1e000L    /* 256 tiles of up to 16 bytes */
#define TEXT_MAP_COLS   128
#define TEXT_MAP_ROWS   32
#define TEXT_SPACE      0x20        /* the space's tile */

static BOOL text_tiles;             /* the console is on the tile layer */
static UWORD text_top;              /* map row of screen row 0 */
static UBYTE saved_dc0, saved_l1[7];    /* fVDI's settings */

#define VERA_L1_CONFIG  0x14        /* 0x14-0x1a: layer 1 registers */
#define VERA_L1_VSCROLL_L 0x19
#define VERA_L1_VSCROLL_H 0x1a

/* Map address of a cell: screen row y, column x */
static ULONG text_cell(UWORD x, UWORD y)
{
    return TEXT_MAP + ((ULONG)(((text_top + y) & (TEXT_MAP_ROWS - 1)) * TEXT_MAP_COLS + x) << 1);
}

/* The screen row and column of a cell address from conout.c */
static void text_position(const UBYTE *cell, UWORD *x, UWORD *y)
{
    ULONG off = cell - v_bas_ad;
    UWORD col;

    *y = divu(off, v_cel_wr);
    col = off - (ULONG)*y * v_cel_wr;
    if (v_planes > 1)               /* planar layout: 16-pixel groups */
        col = (col / (v_planes * 2)) * 2 + (col & 1);
    *x = col;
}

static UBYTE text_attribute(void)
{
    if (v_stat_0 & M_REVID)
        return (v_col_fg << 4) | (v_col_bg & 0x0f);
    return (v_col_bg << 4) | (v_col_fg & 0x0f);
}

static void text_scroll_register(void)
{
    UWORD pixels = text_top * v_cel_ht;

    VERA_REG(VERA_L1_VSCROLL_L) = LOBYTE(pixels);
    VERA_REG(VERA_L1_VSCROLL_H) = HIBYTE(pixels) & 0x0f;
}

/* Copy map row s to map row d (screen rows), the visible columns */
static void text_copy_row(UWORD d, UWORD s)
{
    ULONG src = text_cell(0, s);
    UWORD n = (v_cel_mx + 1) * 2;

    vd_set_write(text_cell(0, d), VERA_INC1);
    while (n--)
        VERA_REG(VERA_DATA1) = vd_read_byte(src++);
}

/*
 * Called through the 'VERA' cookie by fVDI: on (1) after it has cleared
 * the screen for text mode, off (0) before it goes back to graphics.
 */
void mini68k_vera_text_mode(LONG on)
{
    UWORD i, k, r;

    if (!on == !text_tiles)
        return;

    vd_begin();
    VERA_REG(VERA_CTRL) = 0;            /* DCSEL = 0 */
    if (!on)
    {
        for (i = 0; i < 7; i++)
            VERA_REG(VERA_L1_CONFIG + i) = saved_l1[i];
        VERA_REG(VERA_DC0) = saved_dc0;
        text_tiles = FALSE;
        vd_end();
        return;
    }

    saved_dc0 = VERA_REG(VERA_DC0);
    for (i = 0; i < 7; i++)
        saved_l1[i] = VERA_REG(VERA_L1_CONFIG + i);

    /* the font: tile k is the glyph at byte offset k of the font form */
    vd_set_write(TEXT_TILES, VERA_INC1);
    for (k = 0; k < 256; k++)
        for (r = 0; r < v_cel_ht; r++)
            VERA_REG(VERA_DATA1) = (k < v_fnt_wr) ? ((const UBYTE *)v_fnt_ad)[k + r * v_fnt_wr] : 0;

    /* an empty map */
    vd_set_write(TEXT_MAP, VERA_INC1);
    k = (v_col_bg << 4) | (v_col_fg & 0x0f);
    for (i = 0; i < TEXT_MAP_COLS * TEXT_MAP_ROWS; i++)
    {
        VERA_REG(VERA_DATA1) = TEXT_SPACE;
        VERA_REG(VERA_DATA1) = k;
    }

    text_top = 0;
    VERA_REG(VERA_L1_CONFIG) = 0x20;    /* 32 x 128 map, 1 bpp tiles */
    VERA_REG(VERA_L1_CONFIG + 1) = TEXT_MAP >> 9;
    VERA_REG(VERA_L1_CONFIG + 2) = ((TEXT_TILES >> 11) << 2) | ((v_cel_ht > 8) ? 0x02 : 0x00);
    VERA_REG(VERA_L1_CONFIG + 3) = 0;   /* no horizontal scroll */
    VERA_REG(VERA_L1_CONFIG + 4) = 0;
    text_scroll_register();
    VERA_REG(VERA_DC0) = (saved_dc0 & 0x0f) | 0x20;    /* layer 1 only */
    text_tiles = TRUE;
    vd_end();
}

/* Draw a character from the font (src) into the cell at dst */
void vd_cell_xfer(const UBYTE *src, const UBYTE *dst)
{
    UWORD fg, bg;
    UBYTE fgb, bgb, masks[4];
    ULONG off;
    WORD i, n, k;

    if (text_tiles)
    {
        UWORD x, y;

        text_position(dst, &x, &y);
        vd_begin();
        vd_set_write(text_cell(x, y), VERA_INC1);
        VERA_REG(VERA_DATA1) = src - (const UBYTE *)v_fnt_ad;
        VERA_REG(VERA_DATA1) = text_attribute();
        vd_end();
        return;
    }

    off = cell_offset(dst);
    if (v_stat_0 & M_REVID)
    {
        fg = v_col_bg;
        bg = v_col_fg;
    }
    else
    {
        fg = v_col_fg;
        bg = v_col_bg;
    }

    vd_begin();
    if (v_planes == 1)
    {
        /* a column of bytes: the VERA moves down a row after each */
        vd_set_write(off, VERA_INC80);
        for (i = v_cel_ht; i > 0; i--, src += v_fnt_wr)
        {
            UBYTE b = *src;

            if (bg & 1)
                b = (fg & 1) ? 0xff : ~b;
            else if (!(fg & 1))
                b = 0x00;
            VERA_REG(VERA_DATA1) = b;
        }
    }
    else
    {
        fgb = vd_colour_byte(fg);
        bgb = vd_colour_byte(bg);
        for (i = v_cel_ht; i > 0; i--, src += v_fnt_wr, off += v_lin_wr)
        {
            n = vd_expand_byte(*src, masks);
            vd_set_write(off, VERA_INC1);
            for (k = 0; k < n; k++)
                VERA_REG(VERA_DATA1) = (masks[k] & fgb) | (~masks[k] & bgb);
        }
    }
    vd_end();
}

/* Invert a cell (the text cursor) */
void vd_neg_cell(const UBYTE *cell)
{
    ULONG off;
    WORD i, k;

    if (text_tiles)                     /* swap the cell's colours */
    {
        UWORD x, y;
        UBYTE a;

        text_position(cell, &x, &y);
        off = text_cell(x, y) + 1;
        vd_begin();
        a = vd_read_byte(off);
        vd_set_write(off, VERA_INC1);
        VERA_REG(VERA_DATA1) = (a << 4) | (a >> 4);
        vd_end();
        return;
    }

    off = cell_offset(cell);
    vd_begin();
    if (v_planes == 1)
    {
        vd_set_write(off, VERA_INC80);
        for (i = v_cel_ht; i > 0; i--, off += v_lin_wr)
            VERA_REG(VERA_DATA1) = ~vd_read_byte(off);
    }
    else
    {
        for (i = v_cel_ht; i > 0; i--, off += v_lin_wr)
        {
            vd_set_write(off, VERA_INC1);
            for (k = 0; k < (WORD)v_planes; k++)
                VERA_REG(VERA_DATA1) = ~vd_read_byte(off + k);
        }
    }
    vd_end();
}

/* Fill cells topx-botx, topy-boty (inclusive) with the background colour */
void vd_blank_out(int topx, int topy, int botx, int boty)
{
    ULONG off = (ULONG)topy * v_cel_wr + topx * v_planes;   /* v_planes bytes per cell */
    UWORD bytes = (botx - topx + 1) * v_planes;
    UWORD rows = (boty - topy + 1) * v_cel_ht;
    UWORD fill = vd_colour_byte(v_col_bg);

    vd_begin();
    if (text_tiles)
    {
        UBYTE a = (v_col_bg << 4) | (v_col_fg & 0x0f);  /* fg: for the cursor */
        UWORD x, y;

        for (y = topy; y <= (UWORD)boty; y++)
        {
            vd_set_write(text_cell(topx, y), VERA_INC1);
            for (x = topx; x <= (UWORD)botx; x++)
            {
                VERA_REG(VERA_DATA1) = TEXT_SPACE;
                VERA_REG(VERA_DATA1) = a;
            }
        }
    }
    else if (bytes == v_lin_wr)         /* whole rows: one run */
    {
        vd_set_write(off, VERA_INC1);
        fill_long(fill, (ULONG)rows * v_lin_wr);
    }
    else
    {
        for ( ; rows > 0; rows--, off += v_lin_wr)
        {
            vd_set_write(off, VERA_INC1);
            vd_fill(fill, bytes);
        }
    }
    vd_end();
}

/*
 * Scroll: move count bytes of the screen from src to dst (whole rows, so
 * the offsets are the same in RAM and VRAM). Moving up is a single
 * ascending copy. Moving down is done a row at a time from the bottom
 * (the console moves by a whole text line, so a row is never overwritten
 * before it has been read).
 */
void vd_move(const UBYTE *dst, const UBYTE *src, ULONG count)
{
    ULONG d = dst - v_bas_ad;
    ULONG s = src - v_bas_ad;
    UWORD n;

    vd_begin();
    if (text_tiles)
    {
        UWORD dy = divu(d, v_cel_wr), sy = divu(s, v_cel_wr);
        UWORD rows = divu(count, v_cel_wr), i;

        if (rows == v_cel_my && dy + sy == 1)   /* the whole screen, a line */
        {
            text_top = (text_top + ((sy > dy) ? 1 : TEXT_MAP_ROWS - 1)) & (TEXT_MAP_ROWS - 1);
            text_scroll_register();     /* conout.c blanks the new line */
        }
        else if (dy < sy)
        {
            for (i = 0; i < rows; i++)
                text_copy_row(dy + i, sy + i);
        }
        else
        {
            for (i = rows; i > 0; i--)
                text_copy_row(dy + i - 1, sy + i - 1);
        }
    }
    else if (d < s)
    {
        vd_set_write(d, VERA_INC1);
        copy_long(s, count);
    }
    else
    {
        d += count;
        s += count;
        while (count)
        {
            n = (count > v_lin_wr) ? v_lin_wr : (UWORD)count;
            d -= n;
            s -= n;
            count -= n;
            vd_set_write(d, VERA_INC1);
            vd_copy(s, n);
        }
    }
    vd_end();
}

#endif /* CONF_WITH_VERA_DIRECT */
