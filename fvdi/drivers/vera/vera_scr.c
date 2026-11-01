/*
 * Pixel read and write for the VERA fVDI driver.
 *
 * Copyright (C) 2026 Dan Werner
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

#include "vera.h"
#include "driver.h"

/* Memory forms in the device format: 4 bits per pixel, packed */
static uint8_t *memory_pixel(MFDB *mfdb, long x, long y)
{
    return (uint8_t *)mfdb->address + y * (mfdb->wdwidth * 8L) + (x >> 1);
}

/* VRAM address of a screen pixel: 16 x 16 bit multiply (mulu), not the
 * library call a 32-bit multiply needs on the 68000 */
static inline uint32_t pixel_addr(long x, long y)
{
    return (uint32_t)(uint16_t)y * bytes_per_line + ((uint16_t)x >> 1);
}

long CDECL c_write_pixel(Virtual *vwk, MFDB *mfdb, long x, long y, long colour)
{
    const uint8_t nibble = (x & 1) ? 0x0f : 0xf0;
    const uint8_t c = colour_byte(colour & 0x0f) & nibble;

    if ((long)vwk & 1)
        return -1;      /* table mode: the engine calls us for each pixel */

    if (!is_screen(vwk->real_address, mfdb))
    {
        uint8_t *p;

        if (mfdb->bitplanes != 4)
            return 0;   /* let the engine do it */
        p = memory_pixel(mfdb, x, y);
        *p = (*p & ~nibble) | c;
        return 1;
    }

    if (x < 0 || y < 0 || x >= screen_width || y >= screen_height)
        return 1;

    v_begin();
    {
        const uint32_t addr = pixel_addr(x, y);
        uint8_t old = v_read(addr);

        v_set_write(addr);
        V_PUT((old & ~nibble) | c);
    }
    v_end();
    return 1;
}

long CDECL c_read_pixel(Virtual *vwk, MFDB *mfdb, long x, long y)
{
    uint8_t b;

    if (!is_screen(vwk->real_address, mfdb))
    {
        if (mfdb->bitplanes != 4)
            return 0;
        b = *memory_pixel(mfdb, x, y);
    }
    else
    {
        if (x < 0 || y < 0 || x >= screen_width || y >= screen_height)
            return 0;
        v_begin();
        b = v_read(pixel_addr(x, y));
        v_end();
    }

    return (x & 1) ? (b & 0x0f) : (b >> 4);
}
