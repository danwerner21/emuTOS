/*
 * vdi_vera.c - VDI drawing straight into the VERA card (Mini-M68k)
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * With CONF_WITH_VERA_DIRECT, the screen is the VERA bitmap, see
 * bios/vera_direct.c: 1 bpp in ST high, 2 bpp in ST medium and 4 bpp in
 * ST low. This file has the VDI primitives that write to it directly:
 * rectangle fill (also used for horizontal lines and polygon spans) and
 * the fast path for byte-aligned text. Other primitives run on the RAM
 * screen between vd_bounce_read() and vd_bounce_write() (see their
 * callers).
 *
 * Writes go through DATA1 in sequence. Partial bytes, and the modes
 * that combine with the screen (transparent, XOR, erase), first read
 * the old byte through DATA0.
 */

#include "emutos.h"
#include "vdi_defs.h"
#include "lineavars.h"
#include "../bios/mini68k.h"
#include "../bios/vera.h"

#if CONF_WITH_VERA_DIRECT

/*
 * ST high: combine pattern byte p under mask m with the screen byte at
 * off. For WM_ERASE, the caller has inverted the pattern.
 */
static UBYTE combine_mono(WORD mode, UWORD color, UWORD off, UBYTE p, UBYTE m)
{
    UBYTE old;

    switch(mode) {
    case WM_XOR:
        return vd_read_byte(off) ^ (p & m);
    case WM_TRANS:
    case WM_ERASE:
        old = vd_read_byte(off);
        return color ? (old | (p & m)) : (old & ~(p & m));
    default:    /* WM_REPLACE */
        if (!color)
            p = 0;
        if (m == 0xff)
            return p;
        return (vd_read_byte(off) & ~m) | (p & m);
    }
}

static void rect_mono(const VwkAttrib *attr, WORD x1, WORD y1, WORD x2, WORD y2)
{
    const WORD mode = attr->wrt_mode;
    const UWORD color = attr->color & 1;
    const UWORD b1 = x1 >> 3;               /* first and last bytes */
    const UWORD b2 = x2 >> 3;
    UBYTE lmask = 0xff >> (x1 & 7);
    const UBYTE rmask = 0xff << (7 - (x2 & 7));
    UWORD row_off = y1 * v_lin_wr;
    WORD y;

    if (b1 == b2)
        lmask &= rmask;

    vd_begin();
    for (y = y1; y <= y2; y++, row_off += v_lin_wr)
    {
        UWORD pat = attr->patptr[attr->patmsk & y];
        UBYTE even, odd;            /* pattern for even and odd bytes */
        UWORD off = row_off + b1;
        UWORD b;

        if (mode == WM_ERASE)
            pat = ~pat;
        even = HIBYTE(pat);
        odd = LOBYTE(pat);

        vd_set_write(off, VERA_INC1);

        /* left byte (the only one if b1 == b2) */
        VERA_REG(VERA_DATA1) = combine_mono(mode, color, off, (b1 & 1) ? odd : even, lmask);
        if (b1 == b2)
            continue;
        off++;

        /* middle bytes */
        if (mode == WM_REPLACE || mode > WM_ERASE)
        {
            UWORD n = b2 - b1 - 1;

            if (!color)
                even = odd = 0;
            if (even == odd)
                vd_fill(even, n);   /* solid colour, or a vertical pattern */
            else
            {
                for (b = b1 + 1; b < b2; b++)
                    VERA_REG(VERA_DATA1) = (b & 1) ? odd : even;
            }
            off += n;
        }
        else
        {
            for (b = b1 + 1; b < b2; b++, off++)
                VERA_REG(VERA_DATA1) = combine_mono(mode, color, off, (b & 1) ? odd : even, 0xff);
        }

        /* right byte */
        VERA_REG(VERA_DATA1) = combine_mono(mode, color, off, (b2 & 1) ? odd : even, rmask);
    }
    vd_end();
}

/*
 * Colour modes: a VERA byte holds 2 (ST low, 4 bpp) or 4 (ST medium,
 * 2 bpp) pixels. Pattern and pixel masks are expanded to "field masks",
 * with all the bits of each selected pixel set.
 */
static UBYTE expand_pixels(UWORD bits)
{
    static const UBYTE nibble_2bpp[16] =    /* 4 pixels of 2 bits */
    {
        0x00, 0x03, 0x0c, 0x0f, 0x30, 0x33, 0x3c, 0x3f,
        0xc0, 0xc3, 0xcc, 0xcf, 0xf0, 0xf3, 0xfc, 0xff
    };
    static const UBYTE pair_4bpp[4] = { 0x00, 0x0f, 0xf0, 0xff };

    return (v_planes == 4) ? pair_4bpp[bits & 3] : nibble_2bpp[bits & 15];
}

/*
 * Combine the pattern field mask pm, under the pixel mask m, with the
 * screen byte at off. cfill is the colour in every pixel. As with the
 * bit planes: replace gives the colour where the pattern is set and
 * colour 0 elsewhere; transparent (and erase, with the pattern inverted
 * by the caller) gives the colour where the pattern is set; XOR inverts
 * the pixels where it is set.
 */
static UBYTE combine_colour(WORD mode, UBYTE cfill, UWORD off, UBYTE pm, UBYTE m)
{
    UBYTE old, p;

    switch(mode) {
    case WM_XOR:
        return vd_read_byte(off) ^ (pm & m);
    case WM_TRANS:
    case WM_ERASE:
        p = pm & m;
        old = vd_read_byte(off);
        return (old & ~p) | (p & cfill);
    default:    /* WM_REPLACE */
        p = pm & cfill;
        if (m == 0xff)
            return p;
        return (vd_read_byte(off) & ~m) | (p & m);
    }
}

static void rect_colour(const VwkAttrib *attr, WORD x1, WORD y1, WORD x2, WORD y2)
{
    const WORD mode = attr->wrt_mode;
    const WORD ppb = 8 / v_planes;          /* pixels per VERA byte */
    const UWORD pmask = (1 << ppb) - 1;
    const UWORD period = 16 / ppb;          /* VERA bytes per pattern word */
    const UBYTE cfill = vd_colour_byte(attr->color);
    const UWORD b1 = x1 / ppb;              /* first and last bytes */
    const UWORD b2 = x2 / ppb;
    UBYTE lmask = expand_pixels(pmask >> (x1 % ppb));
    const UBYTE rmask = expand_pixels((pmask << (ppb - 1 - x2 % ppb)) & pmask);
    UWORD row_off = y1 * v_lin_wr;
    UBYTE pm[8];                            /* pattern, per byte of a word */
    WORD y;
    UWORD k;

    if (b1 == b2)
        lmask &= rmask;

    vd_begin();
    for (y = y1; y <= y2; y++, row_off += v_lin_wr)
    {
        UWORD pat = attr->patptr[attr->patmsk & y];
        UWORD off = row_off + b1;
        UWORD b;
        BOOL uniform = TRUE;

        if (mode == WM_ERASE)
            pat = ~pat;
        for (k = 0; k < period; k++)
        {
            pm[k] = expand_pixels(pat >> (16 - ppb - k * ppb));
            if (pm[k] != pm[0])
                uniform = FALSE;
        }

        vd_set_write(off, VERA_INC1);

        /* left byte (the only one if b1 == b2) */
        VERA_REG(VERA_DATA1) = combine_colour(mode, cfill, off, pm[b1 & (period - 1)], lmask);
        if (b1 == b2)
            continue;
        off++;

        /* middle bytes */
        if (mode == WM_REPLACE || mode > WM_ERASE)
        {
            UWORD n = b2 - b1 - 1;

            if (uniform)
                vd_fill(pm[0] & cfill, n);
            else
            {
                for (b = b1 + 1; b < b2; b++)
                    VERA_REG(VERA_DATA1) = pm[b & (period - 1)] & cfill;
            }
            off += n;
        }
        else
        {
            for (b = b1 + 1; b < b2; b++, off++)
                VERA_REG(VERA_DATA1) = combine_colour(mode, cfill, off, pm[b & (period - 1)], 0xff);
        }

        /* right byte */
        VERA_REG(VERA_DATA1) = combine_colour(mode, cfill, off, pm[b2 & (period - 1)], rmask);
    }
    vd_end();
}

/*
 * Fill a rectangle with the current pattern: the VERA version of
 * swblit_rect_common(), for one pattern for all planes (the caller
 * handles multi-plane patterns)
 */
void vera_rect(const VwkAttrib *attr, const Rect *rect)
{
    WORD x1 = rect->x1, x2 = rect->x2;
    WORD y1 = rect->y1, y2 = rect->y2;

    /* line-A callers may not clip: stay inside the screen */
    if (x1 < 0)
        x1 = 0;
    if (x2 >= (WORD)V_REZ_HZ)
        x2 = V_REZ_HZ - 1;
    if (y1 < 0)
        y1 = 0;
    if (y2 >= (WORD)V_REZ_VT)
        y2 = V_REZ_VT - 1;
    if (x1 > x2 || y1 > y2)
        return;

    if (v_planes == 1)
        rect_mono(attr, x1, y1, x2, y2);
    else
        rect_colour(attr, x1, y1, x2, y2);
}

/*
 * Byte-aligned text in a monospaced 8-pixel font, with no effects: the
 * VERA version of direct_screen_blit(). The string is drawn a screen row
 * at a time, so each row is one run of writes. In the colour modes, each
 * font byte (8 pixels) becomes 2 or 4 VERA bytes.
 */
void vera_text(WORD count, const WORD *str)
{
    const WORD mode = WRT_MODE;
    const WORD nb = v_planes;               /* VERA bytes per character */
    const UBYTE fgb = vd_colour_byte(TEXTFG);
    const UBYTE *font = (const UBYTE *)FBASE;
    UWORD off = DESTY * v_lin_wr + (DESTX >> 3) * nb;
    UBYTE masks[4];
    WORD row, i, k;

    vd_begin();
    for (row = DELY; row > 0; row--, off += v_lin_wr, font += FWIDTH)
    {
        UWORD o = off;

        vd_set_write(off, VERA_INC1);
        for (i = 0; i < count; i++)
        {
            vd_expand_byte(font[str[i]], masks);
            for (k = 0; k < nb; k++, o++)
            {
                UBYTE m = masks[k];

                switch(mode) {
                default:        /* WM_REPLACE: colour 0 behind */
                    VERA_REG(VERA_DATA1) = m & fgb;
                    break;
                case WM_TRANS:
                    VERA_REG(VERA_DATA1) = (vd_read_byte(o) & ~m) | (m & fgb);
                    break;
                case WM_XOR:
                    VERA_REG(VERA_DATA1) = vd_read_byte(o) ^ m;
                    break;
                case WM_ERASE:  /* colour where the glyph is clear */
                    VERA_REG(VERA_DATA1) = (vd_read_byte(o) & m) | (~m & fgb);
                    break;
                }
            }
        }
    }
    vd_end();
}

#endif /* CONF_WITH_VERA_DIRECT */
