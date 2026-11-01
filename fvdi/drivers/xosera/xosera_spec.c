/* 
 * Initialization code for the Xosera FVDI driver.
 */

#include <osbind.h> // Currently for Xbtimer

#include "fvdi.h"
#include "driver.h"
#include "string/memset.h"
#include "xosera.h"

char red[] = {4, 11, 10, 9, 8};
char green[] = {4, 7, 6, 5, 4 };
char blue[] = {4, 3, 2, 1, 0 };
char alpha[] = { 4, 15, 14, 13, 32 };
char none[] = {0};

static Mode const mode[1] = {
        {4, CHUNKY, {red, green, blue, alpha, none, none}, 0, 2, 2, 1}
};

char driver_name[] = "Xosera driver by Rob Gowin, danodus & Xark";

long CDECL (*write_pixel_r)(Virtual *vwk, MFDB *mfdb, long x, long y, long colour) = c_write_pixel;

long CDECL (*read_pixel_r)(Virtual *vwk, MFDB *mfdb, long x, long y) = c_read_pixel;

long CDECL
(*line_draw_r)(Virtual *vwk, long x1, long y1, long x2, long y2, long pattern, long colour, long mode) = c_line_draw;

long CDECL
(*expand_area_r)(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y, long w, long h,
                 long operation, long colour) = c_expand_area;

long CDECL(*fill_area_r)(Virtual *vwk, long x, long y, long w, long h, short *pattern, long colour, long mode,
                         long interior_style) = c_fill_area;

long CDECL
(*fill_poly_r)(Virtual *vwk, short points[], long n, short index[], long moves, short *pattern, long colour, long mode,
               long interior_style) = 0;

long CDECL
(*blit_area_r)(Virtual *vwk, MFDB *src, long src_x, long src_y, MFDB *dst, long dst_x, long dst_y, long w, long h,
               long operation) = c_blit_area;

long CDECL (*text_area_r)(Virtual *vwk, short *text, long length, long dst_x, long dst_y, short *offsets) = 0;

long CDECL (*mouse_draw_r)(Workstation *wk, long x, long y, Mouse *mouse) = c_mouse_draw;

long CDECL (*get_colour_r)(Virtual *vwk, long colour) = c_get_colour;

void CDECL (*get_colours_r)(Virtual *vwk, long colour, unsigned long *foreground, unsigned long *background) = 0;

void CDECL
(*set_colours_r)(Virtual *vwk, long start, long entries, unsigned short *requested, Colour palette[]) = c_set_colours;

long wk_extend = 0;
short accel_s = 0;
short accel_c = A_BLIT | A_FILL | A_LINE | A_MOUSE | A_EXPAND;

const Mode *graphics_mode = &mode[0];

void timer_b_interrupt_handler(void);

uint16_t timer_b_sieve = 0x1111;

short enable_timer_b = 0;

static int validate_hex(const char *p)
{
    if (*p++ != '0') return 0;
    if (*p != 'x' && *p != 'X') return 0;
    p++;
    const char *allowed = "0123456789ABCDEFabcdef";
    for (const char *q = p; *q != 0; q++) {
        int found = 0;
        for (const char *a = allowed; *a; a++) {
            if (*q == *a) {
                found = 1;
                break;
            }
        }
        if (!found) return 0;
    }
    return 1;
}

static uint32_t parse_hex(const char *p)
{
    uint32_t result = 0;
    if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) p += 2;
    while (*p) {
        char ch = *p++;
        result <<= 4;
        int val;
        if (ch >= 'a') val = ch - 'a' + 10;
        else if (ch >= 'A') val = ch - 'A' + 10;
        else val = ch - '0';
        result |= val;
    }
    return result;
}

uint32_t xosera_base = 0xf80060; // Default to the value for the ROSCO board.

static long set_xosera_base(const char **ptr)
{
    char token[80];
    if ((*ptr = access->funcs.skip_space(*ptr)) == 0) {
        access->funcs.error("missing parameter for 'xosera_base' option", NULL);
    } else {
        *ptr = access->funcs.get_token(*ptr, token, 80);
        int ok = validate_hex(token);
        if (ok) xosera_base = parse_hex(token);
        else access->funcs.error("can't parse hex value for 'xosera_base' option: ", token);
    }
    return 1;
}

static Option const options[] = {
        {"xosera_base",    {set_xosera_base}, -1},
        {"enable_timer_b", {&enable_timer_b},     1},
};

/*
 * Handle any driver specific parameters
 */
long check_token(char *token, const char **ptr)
{
    int i;
    short normal;
    char *xtoken;

    xtoken = token;
    switch (token[0]) {
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
    for (i = 0; i < (int) (sizeof(options) / sizeof(Option)); i++) {
        if (access->funcs.equal(xtoken, options[i].name)) {
            switch (options[i].type) {
                case -1:                /* Function call */
                    return (options[i].var.func)(ptr);
                case 0:                 /* Default 1, set to 0 */
                    *options[i].var.s = (short)(1 - normal);
                    return 1;
                case 1:                 /* Default 0, set to 1 */
                    *options[i].var.s = normal;
                    return 1;
                case 2:                 /* Increase */
                    *options[i].var.s += -1 + 2 * normal;
                    return 1;
                case 3:
                    if ((*ptr = access->funcs.skip_space(*ptr)) ==
                        NULL) { ;               /* *********** Error, somehow */
                    }
                    *ptr = access->funcs.get_token(*ptr, token, 80);
                    *options[i].var.s = token[0];
                    return 1;
            }
        }
    }
    return 0;
}

/*
 * Do whatever setup work might be necessary on boot up
 * and which couldn't be done directly while loading.
 * Supplied is the default fVDI virtual workstation.
 */

bool local_xosera_init(volatile xmreg_t *xosera_ptr, xosera_mode_t init_mode);

static void vbl_handler(void)
{   
    uint8_t *xosera_p = (uint8_t *)xosera_base;
    // TODO: ACK only VBL interrupt.
    volatile uint8_t cur = xosera_p[6];
    xosera_p[6] = cur & 0x10;  // Ack interrupts.
}

typedef void (*PFVOID)(void);

static void install_to_vblqueue(PFVOID handler)
{
    PFVOID **vblqueue = (PFVOID **)(0x456); /* Pointer to the VBL queue array */
    PFVOID *vbl_list = NULL;
    if (vblqueue) vbl_list = *vblqueue;
    if (vbl_list) vbl_list[1] = handler;
}

long CDECL initialize(Virtual *vwk)
{
    access->funcs.puts("Initializing Xosera driver...\r\n");

    Workstation *wk;

    vwk = me->default_vwk;        /* This is what we're interested in */
    wk = vwk->real_address;

    const short width = 640, height = 240, bits_per_pixel = 4;

    /* update the settings */
    wk->screen.mfdb.width = width;
    wk->screen.mfdb.height = height;
    wk->screen.mfdb.bitplanes = bits_per_pixel;

    wk->screen.mfdb.wdwidth = (short) (wk->screen.mfdb.width * wk->screen.mfdb.bitplanes / 16);
    wk->screen.wrap = (short) (wk->screen.mfdb.width * wk->screen.mfdb.bitplanes / 8);

    wk->screen.coordinates.max_x = (short) (wk->screen.mfdb.width - 1);
    wk->screen.coordinates.max_y = (short) (wk->screen.mfdb.height - 1);

    wk->screen.look_up_table = 1;
    wk->screen.mfdb.standard = 0;

    if (wk->screen.pixel.width > 0)  /* Starts out as screen width in millimeters. Convert to microns per pixel. */
        wk->screen.pixel.width = (wk->screen.pixel.width * 1000L) / wk->screen.mfdb.width;
    else                                   /*   or fixed DPI (negative) */
        wk->screen.pixel.width = 25400 / -wk->screen.pixel.width;
    if (wk->screen.pixel.height > 0) /* Starts out as screen height in millimeters. Convert to microns per pixel. */
        wk->screen.pixel.height = (wk->screen.pixel.height * 1000L) / wk->screen.mfdb.height;
    else                                    /*   or fixed DPI (negative) */
        wk->screen.pixel.height = 25400 / -wk->screen.pixel.height;

    // FIXME: The EmuTOS XBIOS needs to be made Xosera-aware and then made to return the correct Xosera-specific address here.
    wk->screen.mfdb.address = Physbase();

    volatile xmreg_t *const xosera_ptr = (volatile xmreg_t *const) xosera_base;
    device.address = (void *) xosera_ptr;

    // Install the vertical blank handler
    if (!enable_timer_b) install_to_vblqueue(vbl_handler);

    access->funcs.puts("Xosera: Initializing...\r\n");
    if (!local_xosera_init(xosera_ptr, 0)) {
        access->funcs.puts("Xosera: Initialization failed.\r\n");
        if (!enable_timer_b) install_to_vblqueue(NULL);
        return 0;
    }
    char str[80], buf[80];
    str[0] = 0;
    access->funcs.cat("Xosera: Configuring, using base address of 0x", str);
    access->funcs.ltoa(buf, (long) xosera_base, 16);
    access->funcs.cat(buf, str);
    access->funcs.cat(".\r\n", str);
    access->funcs.puts(str);

    uint16_t pa_gfx_ctrl = (1 << GFX_CTRL_BITMAP_B) | (GFX_4_BPP << GFX_CTRL_BPP_B) |
                           ((width <= 320 ? GFX_2X : GFX_1X) << GFX_CTRL_H_REPEAT_B) | (height <= 240 ? GFX_2X : GFX_1X);

    xreg_setw(PA_LINE_LEN, width / bits_per_pixel);
    xreg_setw(VID_RIGHT, 640); // always 640
    xreg_setw(PA_GFX_CTRL, pa_gfx_ctrl);
    xreg_setw(PB_GFX_CTRL, 0x0080); /* blank PB */
    xm_setw(WR_INCR, 1);
    xm_setw(PIXEL_X, 0); /* VRAM base is 0x0. */
    xm_setw(PIXEL_Y, width / bits_per_pixel); /* Number of words per line. */
    xm_setbh(SYS_CTRL, 0); /* Set pixel parameters. */
    xm_setbl(SYS_CTRL, 0xF);

    /*
     * This code needs more work.
     * Especially if there was no VDI started since before.
     */

    if (loaded_palette) {
        access->funcs.puts("We are loading a palette.\n");
        access->funcs.copymem(loaded_palette, default_vdi_colors, 16 * 3 * sizeof(short));
    } else {
        access->funcs.puts("We are NOT loading a palette.\n");
    }
    wk->screen.palette.size = bits_per_pixel == 4 ? 16 : 256;

    Colour *default_palette = (Colour *) access->funcs.malloc(wk->screen.palette.size * sizeof(Colour), 3);
    if (default_palette == NULL) {
        access->funcs.error("Can't allocate memory for default palette.\n", NULL);
    }
    wk->screen.palette.colours = default_palette;

    // This call is required to initialize the palette.
    c_initialize_palette(vwk, 0, wk->screen.palette.size, default_vdi_colors, wk->screen.palette.colours);

    device.byte_width = wk->screen.wrap;
    if (enable_timer_b) {
        /* This is temp hack for RobG's system until interrupts are fixed. */
        /* Setup a 240 Hz interrupt: 7.378 MHz / 200 / 154 = 240 Hz. */
        /* We will divide this by four in the handler to call 'int_vbl' sixty times a second. */
        access->funcs.puts("Xosera driver init: Installing Timer B Vertical Bank Source\n");
        Xbtimer(XB_TIMERB, 7, 154, timer_b_interrupt_handler);
    } else { 
        /* Enable Xosera vertical end interrupt. */
        xm_setbl(INT_CTRL, 0x7F); /* clear all pending interrupts */
        xm_setbh(INT_CTRL, 0x10); /* enable video interrupt */
        access->funcs.puts("Xosera driver init: Xosera video interrupt handler installed.\n");
    }
    access->funcs.puts("Xosera driver init: done.\r\n");

    return 1;
}

/*
 *
 */
long CDECL setup(long type, long value)
{
    long ret;

    ret = -1;
    switch (type) {
        case Q_NAME:
            ret = (long) driver_name;
            break;
        case S_DRVOPTION:
            ret = tokenize((char *) value);
            break;
    }

    return ret;
}

Virtual *CDECL opnwk(Virtual *UNUSED(vwk))
{
    return 0;
}

/*
 * 'Deinitialize'
 */
void CDECL clswk(Virtual *vwk)
{
    (void) vwk;
}
