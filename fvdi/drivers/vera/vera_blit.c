/*
 * Expand and blit for the VERA fVDI driver.
 *
 * Copyright (C) 2026 Dan Werner
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

#include "vera.h"
#include "driver.h"

#define MAX_ROW_BYTES   (1024 / 2 + 2)  /* up to 1024 pixels, plus a spare */

/* 8 mono pixels to the 4 VERA bytes holding them, with the nibble of
 * each set pixel all ones (first byte in the top bits) */
static uint32_t expand8[256];

static uint8_t src_row[MAX_ROW_BYTES + 2];

void blit_init(void)
{
    uint16_t i, bit;

    for (i = 0; i < 256; i++)
    {
        uint32_t v = 0;

        for (bit = 0; bit < 8; bit++)
            if (i & (0x80 >> bit))
                v |= 0xf0000000UL >> (4 * bit);
        expand8[i] = v;
    }
}

/* 8 bits of a mono row, from bit position pos (bit 0 is the top bit of
 * the first byte); positions before the row read as 0 */
static inline uint8_t get8(const uint8_t *row, long pos)
{
    uint16_t w;

    if (pos < 0)
        return row[0] >> (uint16_t)(-pos);
    row += pos >> 3;
    if ((pos & 7) == 0)
        return row[0];
    w = ((uint16_t)row[0] << 8) | row[1];
    return (uint8_t)(w >> (8 - (pos & 7)));
}

/*
 * Expand a mono form onto the screen: VDI text and mono icons. Modes:
 * replace (fg on bg), transparent (fg where set), XOR (invert where set)
 * and reverse transparent (fg where clear). Each row is built 4 bytes
 * (8 pixels, one source byte) at a time, then written whole; the old row
 * is read where it shows through (only the edges in the replace mode).
 */
long CDECL c_expand_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y,
                         long w, long h, long operation, long colour)
{
    Workstation *wk = vwk->real_address;
    uint8_t *const old = (uint8_t *)row_dst;
    uint8_t *const out = (uint8_t *)row_out;
    long hw, j;
    uint32_t fg32, bg32;
    uint16_t b1, b2, nb, n, i;
    uint8_t lmask, rmask;

    if (!is_screen(wk, dst) || is_screen(wk, src) || src->bitplanes != 1)
        return 0;       /* let the engine do it */
    if (w <= 0 || h <= 0)
        return 1;

    hw = c_get_colour(vwk, colour);
    fg32 = colour_byte(hw & 0xff) * 0x01010101UL;
    bg32 = colour_byte((hw >> 16) & 0xff) * 0x01010101UL;

    b1 = dst_x >> 1;
    b2 = (dst_x + w - 1) >> 1;
    nb = b2 - b1 + 1;
    if (nb > ROW_LONGS * 4)
        return 0;
    n = (nb + 3) >> 2;
    lmask = (dst_x & 1) ? 0x0f : 0xff;
    rmask = ((dst_x + w - 1) & 1) ? 0xff : 0xf0;
    if (nb == 1)
        lmask &= rmask;

    v_begin();
    for (j = 0; j < h; j++)
    {
        const uint8_t *row = (const uint8_t *)src->address + (src_y + j) * (src->wdwidth * 2L);
        const uint32_t line = (uint32_t)(dst_y + j) * bytes_per_line;
        long pos = src_x + (2L * b1 - dst_x);  /* source bit of the first byte's left pixel */

        if (operation == MODE_REPLACE)
        {
            if (lmask != 0xff)
                old[0] = v_read(line + b1);
            if (rmask != 0xff)
                old[nb - 1] = v_read(line + b2);
        }
        else
            v_read_run(old, line + b1, nb);

        switch (operation)
        {
        case MODE_TRANSPARENT:
            for (i = 0; i < n; i++, pos += 8)
            {
                uint32_t m = expand8[get8(row, pos)];
                row_out[i] = (row_dst[i] & ~m) | (fg32 & m);
            }
            break;
        case MODE_REVERSE_TRANSPARENT:
            for (i = 0; i < n; i++, pos += 8)
            {
                uint32_t m = expand8[get8(row, pos)];
                row_out[i] = (row_dst[i] & m) | (fg32 & ~m);
            }
            break;
        case MODE_XOR:
            for (i = 0; i < n; i++, pos += 8)
                row_out[i] = row_dst[i] ^ expand8[get8(row, pos)];
            break;
        default:    /* MODE_REPLACE */
            for (i = 0; i < n; i++, pos += 8)
            {
                uint32_t m = expand8[get8(row, pos)];
                row_out[i] = (fg32 & m) | (bg32 & ~m);
            }
            break;
        }

        out[0] = (out[0] & lmask) | (old[0] & ~lmask);
        if (nb > 1)
            out[nb - 1] = (out[nb - 1] & rmask) | (old[nb - 1] & ~rmask);

        v_set_write(line + b1);
        v_write_run(out, nb);
    }
    v_end();
    return 1;
}

/* The 16 VDI logic operations, D' = f(S, D), on n longs: out holds S */
static void logic_op(uint16_t op, uint32_t *out, const uint32_t *d, uint16_t n)
{
    uint16_t i;

    switch (op & 15)
    {
    case 0:  for (i = 0; i < n; i++) out[i] = 0;                    break;
    case 1:  for (i = 0; i < n; i++) out[i] &= d[i];                break;
    case 2:  for (i = 0; i < n; i++) out[i] &= ~d[i];               break;
    case 3:                                                         break;
    case 4:  for (i = 0; i < n; i++) out[i] = ~out[i] & d[i];       break;
    case 5:  for (i = 0; i < n; i++) out[i] = d[i];                 break;
    case 6:  for (i = 0; i < n; i++) out[i] ^= d[i];                break;
    case 7:  for (i = 0; i < n; i++) out[i] |= d[i];                break;
    case 8:  for (i = 0; i < n; i++) out[i] = ~(out[i] | d[i]);     break;
    case 9:  for (i = 0; i < n; i++) out[i] = ~(out[i] ^ d[i]);     break;
    case 10: for (i = 0; i < n; i++) out[i] = ~d[i];                break;
    case 11: for (i = 0; i < n; i++) out[i] |= ~d[i];               break;
    case 12: for (i = 0; i < n; i++) out[i] = ~out[i];              break;
    case 13: for (i = 0; i < n; i++) out[i] = ~out[i] | d[i];       break;
    case 14: for (i = 0; i < n; i++) out[i] = ~(out[i] & d[i]);     break;
    default: for (i = 0; i < n; i++) out[i] = 0xffffffffUL;         break;
    }
}

/* Row access for a screen or memory form (4 bits per pixel, packed) */
static void read_row(int screen, MFDB *mfdb, long y, uint16_t first, uint16_t count, uint8_t *buf)
{
    if (screen)
        v_read_run(buf, (uint32_t)y * bytes_per_line + first, count);
    else
    {
        const uint8_t *p = (const uint8_t *)mfdb->address + y * (mfdb->wdwidth * 8L) + first;

        while (count--)
            *buf++ = *p++;
    }
}

static void write_row(int screen, MFDB *mfdb, long y, uint16_t first, uint16_t count, const uint8_t *buf)
{
    if (screen)
    {
        v_set_write((uint32_t)y * bytes_per_line + first);
        v_write_run(buf, count);
    }
    else
    {
        uint8_t *p = (uint8_t *)mfdb->address + y * (mfdb->wdwidth * 8L) + first;

        while (count--)
            *p++ = *buf++;
    }
}

/*
 * Copy a rectangle between the screen and memory forms in the device
 * format, with a logic operation. Each row is read whole before it is
 * written, so rows may overlap; they are done bottom up when the
 * destination is below the source.
 */
long CDECL c_blit_area(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y,
                       long w, long h, long operation)
{
    Workstation *wk = vwk->real_address;
    const int src_screen = is_screen(wk, src);
    const int dst_screen = is_screen(wk, dst);
    const uint16_t op = operation & 15;
    const int needs_dst = !(op == 0 || op == 3 || op == 12 || op == 15);
    uint8_t *const old = (uint8_t *)row_dst;
    uint8_t *const out = (uint8_t *)row_out;
    uint16_t sb1, db1, nb, n;
    uint8_t lmask, rmask;
    long j, y_step, y_first;

    if (!src_screen && !dst_screen)
        return 0;       /* memory to memory: let the engine do it */
    if ((!src_screen && src->bitplanes != 4) || (!dst_screen && dst->bitplanes != 4))
        return 0;
    if (w <= 0 || h <= 0)
        return 1;

    sb1 = src_x >> 1;
    db1 = dst_x >> 1;
    nb = ((dst_x + w - 1) >> 1) - db1 + 1;      /* destination bytes per row */
    if (nb > MAX_ROW_BYTES || nb > ROW_LONGS * 4)
        return 0;
    n = (nb + 3) >> 2;
    lmask = (dst_x & 1) ? 0x0f : 0xff;
    rmask = ((dst_x + w - 1) & 1) ? 0xff : 0xf0;
    if (nb == 1)
        lmask &= rmask;

    /* bottom up if the destination overlaps lower down the same form */
    if (src_screen == dst_screen && (src_screen || src->address == dst->address) && dst_y > src_y)
    {
        y_first = h - 1;
        y_step = -1;
    }
    else
    {
        y_first = 0;
        y_step = 1;
    }

    v_begin();
    for (j = y_first; j >= 0 && j < h; j += y_step)
    {
        uint16_t k;

        /* the source, lined up with the destination bytes */
        if (((src_x ^ dst_x) & 1) == 0)
            read_row(src_screen, src, src_y + j, sb1, nb, out);
        else
        {
            read_row(src_screen, src, src_y + j, sb1, nb + 1, src_row + 1);
            src_row[0] = 0;
            if (dst_x & 1)      /* source starts a pixel further left in its byte */
            {
                for (k = 0; k < nb; k++)
                    out[k] = (src_row[k] << 4) | (src_row[k + 1] >> 4);
            }
            else                /* source starts a pixel further right */
            {
                for (k = 0; k < nb; k++)
                    out[k] = (src_row[k + 1] << 4) | (src_row[k + 2] >> 4);
            }
        }

        /* the destination, where the result depends on it */
        if (needs_dst)
            read_row(dst_screen, dst, dst_y + j, db1, nb, old);
        else
        {
            if (lmask != 0xff)
                read_row(dst_screen, dst, dst_y + j, db1, 1, old);
            if (rmask != 0xff && nb > 1)
                read_row(dst_screen, dst, dst_y + j, db1 + nb - 1, 1, old + nb - 1);
        }

        logic_op(op, row_out, row_dst, n);
        out[0] = (out[0] & lmask) | (old[0] & ~lmask);
        if (nb > 1)
            out[nb - 1] = (out[nb - 1] & rmask) | (old[nb - 1] & ~rmask);

        write_row(dst_screen, dst, dst_y + j, db1, nb, out);
    }
    v_end();
    return 1;
}
