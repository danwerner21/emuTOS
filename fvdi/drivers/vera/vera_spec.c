/*
 * Set-up code for the VERA fVDI driver (RetroBrew Mini-M68k).
 *
 * Copyright (C) 2026 Dan Werner
 * Based on the Xosera driver by Rob Gowin, danodus and Xark.
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

#include <osbind.h>         /* Physbase(), Supexec() */

#include "fvdi.h"
#include "driver.h"
#include "vera.h"
#include "string/memset.h"

static char red[] = {4, 11, 10, 9, 8};
static char green[] = {4, 7, 6, 5, 4};
static char blue[] = {4, 3, 2, 1, 0};
static char alpha[] = {4, 15, 14, 13, 32};
static char none[] = {0};

static Mode const mode[1] =
{
    {4, CHUNKY, {red, green, blue, alpha, none, none}, 0, 2, 2, 1}
};

char driver_name[] = "VERA driver for the RetroBrew Mini-M68k";

long CDECL (*write_pixel_r)(Virtual *vwk, MFDB *mfdb, long x, long y, long colour) = c_write_pixel;
long CDECL (*read_pixel_r)(Virtual *vwk, MFDB *mfdb, long x, long y) = c_read_pixel;
long CDECL (*line_draw_r)(Virtual *vwk, long x1, long y1, long x2, long y2, long pattern, long colour,
                          long mode) = c_line_draw;
long CDECL (*expand_area_r)(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y,
                            long w, long h, long operation, long colour) = c_expand_area;
long CDECL (*fill_area_r)(Virtual *vwk, long x, long y, long w, long h, short *pattern, long colour, long mode,
                          long interior_style) = c_fill_area;
long CDECL (*fill_poly_r)(Virtual *vwk, short points[], long n, short index[], long moves, short *pattern,
                          long colour, long mode, long interior_style) = 0;
long CDECL (*blit_area_r)(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y,
                          long w, long h, long operation) = c_blit_area;
long CDECL (*text_area_r)(Virtual *vwk, short *text, long length, long dst_x, long dst_y, short *offsets) = 0;
long CDECL (*mouse_draw_r)(Workstation *wk, long x, long y, Mouse *mouse) = c_mouse_draw;
long CDECL (*get_colour_r)(Virtual *vwk, long colour) = c_get_colour;
void CDECL (*get_colours_r)(Virtual *vwk, long colour, unsigned long *foreground,
                            unsigned long *background) = 0;
void CDECL (*set_colours_r)(Virtual *vwk, long start, long entries, unsigned short *requested,
                            Colour palette[]) = c_set_colours;

long wk_extend = 0;
short accel_s = 0;
short accel_c = A_BLIT | A_FILL | A_LINE | A_MOUSE | A_EXPAND;

const Mode *graphics_mode = &mode[0];

uint16_t screen_width = 640, screen_height = 240;
uint16_t bytes_per_line = 320;


/* Options for FVDI.SYS: "640x400" for the full-height mode */
static short mode_640x400 = 0;

static Option const options[] =
{
    {"640x400", {&mode_640x400}, 1},
};

long check_token(char *token, const char **ptr)
{
    int i;
    short normal;
    char *xtoken;

    (void)ptr;
    xtoken = token;
    switch (token[0])
    {
    case '+':
        xtoken++;
        normal = 1;
        break;
    case '-':
        xtoken++;
        normal = 0;
        break;
    default:
        normal = 1;
        break;
    }
    for (i = 0; i < (int)(sizeof(options) / sizeof(Option)); i++)
    {
        if (access->funcs.equal(xtoken, options[i].name))
        {
            switch (options[i].type)
            {
            case 0:     /* Default 1, set to 0 */
                *options[i].var.s = (short)(1 - normal);
                return 1;
            case 1:     /* Default 0, set to 1 */
                *options[i].var.s = normal;
                return 1;
            }
        }
    }
    return 0;
}

static struct vera_cookie *vera_cookie;

/* Find the 'VERA' cookie (supervisor mode) */
static struct vera_cookie *find_cookie(void)
{
    long *jar = *(long **)0x5a0;    /* _p_cookies */

    if (!jar)
        return 0;
    for ( ; jar[0]; jar += 2)
        if (jar[0] == COOKIE_VERA)
            return (struct vera_cookie *)jar[1];
    return 0;
}

/*
 * Set up the VERA: a 640-pixel wide bitmap of 4 bits per pixel at VRAM 0,
 * 240 lines (each shown twice) or 400 lines (in the middle of the 480).
 * Runs in supervisor mode.
 */
static long setup_vera(void)
{
    const int tall = (screen_height == 400);

    vera_cookie = find_cookie();
    if (vera_cookie && vera_cookie->version >= 1)
        vera_busy = vera_cookie->busy;

    v_begin();
    VREG(V_CTRL) = 0;                   /* DCSEL = 0 */
    VREG(V_DC0) = 0x00;                 /* video off while setting up */
    VREG(V_DC1) = 128;                  /* HSCALE 1:1: 640 pixels */
    VREG(V_DC2) = tall ? 128 : 64;      /* VSCALE: 480 lines, or 240 doubled */
    VREG(V_DC3) = 15;                   /* border: colour 15 (black) */

    VREG(V_CTRL) = 1 << 1;              /* DCSEL = 1: active area */
    VREG(V_DC0) = 0;                    /* HSTART */
    VREG(V_DC1) = 640 / 4;              /* HSTOP */
    VREG(V_DC2) = tall ? 40 / 2 : 0;    /* VSTART */
    VREG(V_DC3) = tall ? 440 / 2 : 480 / 2; /* VSTOP */
    VREG(V_CTRL) = 0;

    VREG(V_L0_CONFIG) = 0x06;           /* bitmap mode, 4 bpp */
    VREG(V_L0_MAPBASE) = 0;
    VREG(V_L0_TILEBASE) = 0x01;         /* bitmap at VRAM 0, 640 pixels wide */
    VREG(V_L0_HSCROLL_L) = 0;
    VREG(V_L0_HSCROLL_H) = 0;           /* palette offset 0 */
    VREG(V_L0_VSCROLL_L) = 0;
    VREG(V_L0_VSCROLL_H) = 0;
    VREG(V_L1_CONFIG) = 0;

    v_set_write(0);                     /* clear the screen to colour 0 */
    v_fill_run(0x00, (uint32_t)bytes_per_line * screen_height);
    v_set_write(VRAM_SPRITES);          /* all sprites off */
    v_fill_run(0x00, 128 * 8);
    mouse_init();

    VREG(V_DC0) = 0x51;                 /* VGA output, layer 0 and sprites */
    v_end();
    return 0;
}

/* The default palette goes to the VERA ports: supervisor mode */
static Virtual *palette_vwk;

static long setup_palette(void)
{
    Workstation *wk = palette_vwk->real_address;

    c_initialize_palette(palette_vwk, 0, wk->screen.palette.size, default_vdi_colors, wk->screen.palette.colours);
    return 0;
}

/* Tell EmuTOS (supervisor mode): it keeps away from the mode, palette and
 * sprites, and sets up its console for this screen */
static long hand_over(void)
{
    if (vera_cookie && vera_cookie->version >= 1)
    {
        vera_cookie->release_hook = mouse_apply_pending;
        vera_cookie->take_over(screen_width, screen_height, 4);
    }
    return 0;
}

long CDECL initialize(Virtual *vwk)
{
    Workstation *wk;
    Colour *default_palette;

    access->funcs.puts("Initializing the VERA driver...\r\n");

    vwk = me->default_vwk;      /* This is what we're interested in */
    wk = vwk->real_address;

    screen_width = 640;
    screen_height = mode_640x400 ? 400 : 240;
    bytes_per_line = screen_width / 2;

    wk->screen.mfdb.width = screen_width;
    wk->screen.mfdb.height = screen_height;
    wk->screen.mfdb.bitplanes = 4;
    wk->screen.mfdb.wdwidth = screen_width * 4 / 16;
    wk->screen.wrap = bytes_per_line;

    wk->screen.coordinates.max_x = screen_width - 1;
    wk->screen.coordinates.max_y = screen_height - 1;

    wk->screen.look_up_table = 1;
    wk->screen.mfdb.standard = 0;

    if (wk->screen.pixel.width > 0)     /* screen width in mm to microns per pixel */
        wk->screen.pixel.width = (wk->screen.pixel.width * 1000L) / wk->screen.mfdb.width;
    else                                /* or fixed DPI (negative) */
        wk->screen.pixel.width = 25400 / -wk->screen.pixel.width;
    if (wk->screen.pixel.height > 0)
        wk->screen.pixel.height = (wk->screen.pixel.height * 1000L) / wk->screen.mfdb.height;
    else
        wk->screen.pixel.height = 25400 / -wk->screen.pixel.height;

    /* The screen is in the VERA. The RAM screen (which EmuTOS sizes for
     * 640x400 at 16 colours) only identifies the screen in MFDBs. */
    wk->screen.mfdb.address = (void *)Physbase();

    device.address = (void *)VERA_BASE;
    device.byte_width = wk->screen.wrap;

    blit_init();
    Supexec(setup_vera);

    if (loaded_palette)
        access->funcs.copymem(loaded_palette, default_vdi_colors, 16 * 3 * sizeof(short));
    wk->screen.palette.size = 16;
    default_palette = (Colour *)access->funcs.malloc(wk->screen.palette.size * sizeof(Colour), 3);
    if (default_palette == NULL)
    {
        access->funcs.error("Can't allocate memory for the palette.\n", NULL);
        return 0;
    }
    wk->screen.palette.colours = default_palette;
    palette_vwk = vwk;
    Supexec(setup_palette);

    Supexec(hand_over);
    xbios_init();               /* Setcolor and Setpalette now come here */

    access->funcs.puts("VERA driver: 640x");
    access->funcs.puts(mode_640x400 ? "400" : "240");
    access->funcs.puts(", 16 colours.\r\n");
    return 1;
}

long CDECL setup(long type, long value)
{
    long ret = -1;

    switch (type)
    {
    case Q_NAME:
        ret = (long)driver_name;
        break;
    case S_DRVOPTION:
        ret = tokenize((char *)value);
        break;
    }

    return ret;
}

Virtual *CDECL opnwk(Virtual *UNUSED(vwk))
{
    return 0;
}

void CDECL clswk(Virtual *UNUSED(vwk))
{
}
