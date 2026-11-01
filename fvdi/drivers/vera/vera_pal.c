/*
 * Palette handling for the VERA fVDI driver.
 *
 * Copyright (C) 2026 Dan Werner
 * Based on the Xosera driver by Rob Gowin, danodus and Xark.
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

#include "vera.h"
#include "driver.h"

/* The VERA has 4 bits per colour component */
#define red_bits   4
#define green_bits 4
#define blue_bits  4

/* VDI colour index to hardware index, as on the Atari: VDI 0 (white) is
 * hardware 0, VDI 1 (black) is hardware 15 */
const uint8_t tos_colours[16] = {0, 15, 1, 2, 4, 6, 3, 5, 7, 8, 9, 10, 12, 14, 11, 13};

/*
 * The current colours are read back from the VERA's palette when needed
 * (the pointer's colours, Setcolor), rather than kept in a copy here: a
 * copy in the driver's memory was found zeroed after start-up, which
 * left the pointer black.
 */
uint16_t read_hw_colour(uint16_t entry)
{
    const uint32_t addr = VRAM_PALETTE + 2 * entry;
    uint16_t gb = v_read(addr);

    return ((uint16_t)(v_read(addr + 1) & 0x0f) << 8) | gb;
}

uint8_t colour_byte(uint16_t hw_colour)
{
    return (uint8_t)((hw_colour & 0x0f) * 0x11);
}

/* Write a VERA palette entry: GGGGBBBB, then 0000RRRR. Call between
 * v_begin() and v_end(). */
void write_hw_colour(uint16_t entry, uint16_t rgb)
{
    v_set_write(VRAM_PALETTE + 2 * entry);
    V_PUT(rgb & 0xff);
    V_PUT((rgb >> 8) & 0x0f);
}

long CDECL c_get_colour(Virtual *UNUSED(vwk), long colour)
{
    uint16_t fg_in = colour & 0xff, bg_in = (colour >> 16) & 0xff;
    uint16_t foreground, background;

    if (fg_in < 16)
        foreground = tos_colours[fg_in];
    else
        foreground = 15;
    if (bg_in < 16)
        background = tos_colours[bg_in];
    else
        background = 15;

    return ((long)background << 16) | foreground;
}

/* Set hardware colour 'hw' to 0x0RGB, and the pointer colours with it */
void set_hw_colour(uint16_t hw, uint16_t rgb)
{
    v_begin();
    write_hw_colour(hw & 0x0f, rgb & 0x0fff);
    mouse_update_colours();
    v_end();
}

static void set_colour(long vdi_index, uint16_t red, uint16_t green, uint16_t blue)
{
    if (vdi_index < 0 || vdi_index > 15)
        return;
    set_hw_colour(tos_colours[vdi_index], ((red & 0x0f) << 8) | ((green & 0x0f) << 4) | (blue & 0x0f));
}

/*
 * The light colours of the TOS 2 palette, which EmuTOS also uses, in
 * place of the darker ones of TOS 4 in default_vdi_colors[]: palette
 * index, the expected current RGB, and the replacement RGB.
 */
static const short colour_overrides[][7] =
{
    { 10, 667,   0,   0, 1000,  562,  562 },    /* light red */
    { 11,   0, 667,   0,  562, 1000,  562 },    /* light green */
    { 12,   0,   0, 667,  562,  562, 1000 },    /* light blue */
    { 13,   0, 667, 667,  562, 1000, 1000 },    /* light cyan */
    { 14, 667, 667,   0, 1000, 1000,  562 },    /* light yellow */
    { 15, 667,   0, 667, 1000,  562, 1000 },    /* light magenta */
};

void CDECL c_set_colours(Virtual *UNUSED(vwk), long start, long entries, unsigned short *requested,
                         Colour palette[])
{
    unsigned short component;
    long i;

    if ((long)requested & 1)            /* New entries, 16-bit components */
    {
        requested = (unsigned short *)((long)requested & 0xfffffffeL);
        for (i = 0; i < entries; i++)
        {
            Colour *c = &palette[start + i];

            requested++;                /* First word is reserved */
            component = *requested++;
            c->vdi.red = component;
            c->hw.red = component >> (16 - red_bits);
            component = *requested++;
            c->vdi.green = component;
            c->hw.green = component >> (16 - green_bits);
            component = *requested++;
            c->vdi.blue = component;
            c->hw.blue = component >> (16 - blue_bits);
            c->real = tos_colours[(start + i) & 0x0f];
            set_colour(start + i, c->hw.red, c->hw.green, c->hw.blue);
        }
        return;
    }

    /* VDI components, 0 to 1000 */
    for (i = 0; i < (long)(sizeof(colour_overrides) / sizeof(colour_overrides[0])); i++)
    {
        long index = colour_overrides[i][0];

        if (index >= start && index < start + entries)
        {
            unsigned short *rgb = &requested[(index - start) * 3];

            if (rgb[0] == (unsigned short)colour_overrides[i][1] && rgb[1] == (unsigned short)colour_overrides[i][2]
             && rgb[2] == (unsigned short)colour_overrides[i][3])
            {
                rgb[0] = colour_overrides[i][4];
                rgb[1] = colour_overrides[i][5];
                rgb[2] = colour_overrides[i][6];
            }
        }
    }

    for (i = 0; i < entries; i++)
    {
        Colour *c = &palette[start + i];

        component = *requested++;
        c->vdi.red = component;
        c->hw.red = (short)((component * ((1L << red_bits) - 1) + 500L) / 1000);
        component = *requested++;
        c->vdi.green = component;
        c->hw.green = (short)((component * ((1L << green_bits) - 1) + 500L) / 1000);
        component = *requested++;
        c->vdi.blue = component;
        c->hw.blue = (short)((component * ((1L << blue_bits) - 1) + 500L) / 1000);
        c->real = tos_colours[(start + i) & 0x0f];
        set_colour(start + i, c->hw.red, c->hw.green, c->hw.blue);
    }
}
