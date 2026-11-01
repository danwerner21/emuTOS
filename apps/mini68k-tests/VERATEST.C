/*
 * VERATEST.C - test the VERA video card under EmuTOS on the Mini-M68k
 *
 * Build on the board with Sozobon C:
 *   cc veratest.c -o veratest.ttp
 * Run from EmuCON and choose the tests from the menu.
 *
 * The card, on the ECB bus (port p is at 0xffff8000 + p):
 *   0x80-0x9f  VERA (32 registers)
 *   0xa0-0xa1  VT82C42 keyboard/mouse controller (data, status/command)
 *   0xa4-0xa6  parallel port (data, status, control), PC compatible
 *
 * VERA register layout from the VERA programmer's reference. The tests
 * cover experiments E6-E8 of the port plan: copy speed, the 640x400 1 bpp
 * bitmap mode and the vertical blank, plus keyboard, mouse and printer.
 *
 * Under an EmuTOS with the VERA drivers (it publishes the 'VERA' cookie),
 * the tests share the card with EmuTOS and fVDI: they hold the busy flag
 * while they use the VERA ports, save the screen before the tests that
 * overwrite it and restore it afterwards (printing their results only
 * then), and borrow the keyboard controller for the keyboard test.
 */

#include <stdio.h>
#include <osbind.h>

/*
 * The Mini-M68k I/O window is 0xffff0000-0xffffffff, and the BIOS reaches
 * port p at 0xffff8000 + p (address lines A8-A15 = 0x80). A card that also
 * decodes A8-A15 expects them to be 0, at 0xffff0000 + p. Both are tried.
 */
static long io_base;

#define IO(p)   (*(unsigned char *)(io_base + (p)))

/* Read a register into an int. Do not pass IO(p) straight to printf():
 * the compiler may read it as a word, which is an address error at an
 * odd address. */
static int inb(p)
int p;
{
    unsigned char c;

    c = IO(p);
    return c & 0xff;
}

/* VERA registers */
#define VERA            0x80
#define V_ADDR_L        (VERA + 0x00)
#define V_ADDR_M        (VERA + 0x01)
#define V_ADDR_H        (VERA + 0x02)   /* bit 0: address bit 16, bits 7-4: increment */
#define V_DATA0         (VERA + 0x03)
#define V_DATA1         (VERA + 0x04)
#define V_CTRL          (VERA + 0x05)   /* bit 7: reset, bits 6-1: DCSEL, bit 0: ADDRSEL */
#define V_IEN           (VERA + 0x06)
#define V_ISR           (VERA + 0x07)
#define V_DC0           (VERA + 0x09)   /* 0x09-0x0c depend on DCSEL */
#define V_DC1           (VERA + 0x0a)
#define V_DC2           (VERA + 0x0b)
#define V_DC3           (VERA + 0x0c)
#define V_L0_CONFIG     (VERA + 0x0d)
#define V_L0_MAPBASE    (VERA + 0x0e)
#define V_L0_TILEBASE   (VERA + 0x0f)
#define V_L0_HSCROLL_L  (VERA + 0x10)
#define V_L0_HSCROLL_H  (VERA + 0x11)
#define V_L0_VSCROLL_L  (VERA + 0x12)
#define V_L0_VSCROLL_H  (VERA + 0x13)

#define INC1            0x10            /* auto-increment by 1, in V_ADDR_H */
#define VRAM_TEST_END   0x1f9c0L        /* PSG, palette and sprites follow */

/* VT82C42 (8042 compatible) */
#define KBC_DATA        0xa0
#define KBC_STAT        0xa1            /* read: status, write: command */
#define KBC_OBF         0x01            /* output buffer full: data for the CPU */
#define KBC_IBF         0x02            /* input buffer full: do not write */
#define KBC_AUX         0x20            /* the data comes from the mouse */

/* Parallel port */
#define LPT_DATA        0xa4
#define LPT_STAT        0xa5
#define LPT_CTRL        0xa6
#define CTRL_STROBE     0x01            /* PC convention: 1 = line active */
#define CTRL_AUTOLF     0x02
#define CTRL_INIT       0x04            /* 0 = init active */
#define CTRL_SELECT     0x08

/* NS32202 interrupt pending register (MF/PIC), low byte: IR0-IR7 */
#define ICU_IPND        (*(unsigned char *)0xffff8640L)

/*
 * EmuTOS's 'VERA' cookie (emutos-src-1.4/bios/mini68k.h). While *busy is
 * non-zero, EmuTOS's VBL and fVDI's mouse routine leave the VERA ports
 * alone. kbd_hold(1L) stops EmuTOS polling the keyboard controller, and
 * kbd_hold(0L) sets up the keyboard and mouse again (version 2 on).
 */
#define COOKIE_VERA     0x56455241L     /* 'VERA' */

struct vera_cookie {
    int version;
    int reserved;
    unsigned char *busy;
    long (*take_over)();
    long (*release_hook)();             /* set by fVDI's VERA driver */
    long (*kbd_hold)();
};

static struct vera_cookie *cookie;      /* 0: no EmuTOS drivers */

static void find_cookie()
{
    long *jar = *(long **)0x5a0L;       /* _p_cookies */

    cookie = 0;
    if (jar == 0)
        return;
    for ( ; jar[0] != 0; jar += 2)
        if (jar[0] == COOKIE_VERA) {
            cookie = (struct vera_cookie *)jar[1];
            return;
        }
}

static void vera_hold()                 /* keep EmuTOS and fVDI off the ports */
{
    if (cookie)
        (*cookie->busy)++;
}

static void vera_release()
{
    if (cookie && --(*cookie->busy) == 0 && cookie->release_hook)
        (*cookie->release_hook)();      /* a mouse move that waited */
}

static long ticks()                     /* 200 Hz system timer */
{
    return *(long *)0x4baL;
}

static void wait_ticks(n)
long n;
{
    long end = ticks() + n;

    while (ticks() < end)
        ;
}

static int key_waiting()                /* a key on the serial console */
{
    return Bconstat(2) != 0;
}

static int get_key()
{
    return (int)(Bconin(2) & 0xff);
}

static void vera_addr(addr, inc)
long addr;
int inc;
{
    IO(V_CTRL) = 0;                     /* ADDRSEL = 0: DATA0 */
    IO(V_ADDR_L) = addr;
    IO(V_ADDR_M) = addr >> 8;
    IO(V_ADDR_H) = ((addr >> 16) & 1) | inc;
}

/*
 * Does the VERA answer at this I/O base? Its address registers must read
 * back what was written. A floating bus returns the last byte the CPU
 * fetched, so two different patterns are written to two registers.
 */
static int vera_answers(base)
long base;
{
    int i;

    io_base = base;
    IO(V_CTRL) = 0;
    for (i = 0; i < 256; i += 0x55) {
        IO(V_ADDR_L) = i;
        IO(V_ADDR_M) = i ^ 0xff;
        if (inb(V_ADDR_L) != i || inb(V_ADDR_M) != (i ^ 0xff))
            return 0;
    }
    return 1;
}

/* Find the card: return 1 and set io_base, or return 0 */
static int find_card()
{
    int found;

    vera_hold();
    found = vera_answers(0xffff8000L) ? 1 : vera_answers(0xffff0000L) ? 2 : 0;
    vera_release();

    if (found == 1)
        printf("VERA found at 0xffff8080 (ports with A8-A15 = 0x80, like the BIOS)\n");
    else if (found == 2)
        printf("VERA found at 0xffff0080 (the card decodes A8-A15 = 0)\n");
    else {
        io_base = 0xffff8000L;
        printf("VERA not found at 0xffff8080 or 0xffff0080: the tests will not work\n");
    }
    return found != 0;
}

/*
 * Saving the screen, for the tests that overwrite VRAM or change the
 * mode while EmuTOS uses the card. Everything below the PSG, palette
 * and sprite attributes is saved, with the display and layer registers.
 * Reads set the address for each byte: on the current card, data port
 * reads do not step it (see test 7).
 */
static unsigned char *screen_save;
static int reg_save[23];

static void vram_read(buf, count)       /* VRAM from address 0 */
unsigned char *buf;
long count;
{
    unsigned char *d = &IO(V_DATA0);
    long n;

    vera_addr(0L, 0);
    for (n = 0; n < count; n++) {
        if ((n & 0xff) == 0) {          /* new 256-byte page */
            IO(V_ADDR_M) = n >> 8;
            IO(V_ADDR_H) = (n >> 16) & 1;
        }
        IO(V_ADDR_L) = n;
        buf[n] = *d;
    }
}

static void vram_write(buf, count)      /* VRAM from address 0 */
unsigned char *buf;
long count;
{
    unsigned char *d = &IO(V_DATA0);

    vera_addr(0L, INC1);
    while (count-- > 0)
        *d = *buf++;
}

/* IEN, DC0-DC3 with DCSEL 0 and 1, layer 0 and 1 registers (0x0d-0x1a) */
static void regs_save()
{
    int i, n = 0;

    IO(V_CTRL) = 0;
    reg_save[n++] = inb(V_IEN);
    for (i = 0; i < 4; i++)
        reg_save[n++] = inb(V_DC0 + i);
    IO(V_CTRL) = 1 << 1;
    for (i = 0; i < 4; i++)
        reg_save[n++] = inb(V_DC0 + i);
    IO(V_CTRL) = 0;
    for (i = V_L0_CONFIG; i <= VERA + 0x1a; i++)
        reg_save[n++] = inb(i);
}

static void regs_restore()
{
    int i, n = 0;

    IO(V_CTRL) = 0;
    IO(V_IEN) = reg_save[n++];
    for (i = 0; i < 4; i++)
        IO(V_DC0 + i) = reg_save[n++];
    IO(V_CTRL) = 1 << 1;
    for (i = 0; i < 4; i++)
        IO(V_DC0 + i) = reg_save[n++];
    IO(V_CTRL) = 0;
    for (i = V_L0_CONFIG; i <= VERA + 0x1a; i++)
        IO(i) = reg_save[n++];
}

/* Under EmuTOS: hold the VERA and save the screen. Return 0 if there
 * is not enough memory (then the test must not run). Print nothing
 * between this and screen_restore(): the console draws into the VERA. */
static int screen_keep()
{
    long m;

    if (!cookie)
        return 1;                       /* nobody else uses the card */
    if (!screen_save) {
        m = Malloc(VRAM_TEST_END);
        if (m <= 0) {
            printf("Not enough memory to save the screen (%ld bytes)\n", VRAM_TEST_END);
            return 0;
        }
        screen_save = (unsigned char *)m;
    }
    printf("Saving the screen; it comes back after the test\n");
    vera_hold();
    regs_save();
    vram_read(screen_save, VRAM_TEST_END);
    return 1;
}

static void screen_restore()
{
    if (!cookie)
        return;
    vram_write(screen_save, VRAM_TEST_END);
    regs_restore();
    vera_release();
}

/* Empty the console's key buffer */
static void flush_keys()
{
    while (key_waiting())
        get_key();
}

/*
 * 1. VERA identity
 */
static void test_vera_id()
{
    int i, v[4], r[32];

    printf("\n");
    find_card();

    vera_hold();
    IO(V_CTRL) = 63 << 1;               /* DCSEL = 63: version */
    for (i = 0; i < 4; i++)
        v[i] = inb(V_DC0 + i);
    IO(V_CTRL) = 0;
    for (i = 0; i < 32; i++)
        r[i] = inb(VERA + i);
    vera_release();

    if (v[0] == 'V')
        printf("Firmware version: %d.%d.%d\n", v[1], v[2], v[3]);
    else
        printf("No version signature (read %02x %02x %02x %02x): older firmware?\n",
               v[0], v[1], v[2], v[3]);

    printf("Registers 00-1f (DCSEL = 0):\n");
    for (i = 0; i < 32; i++)
        printf("%02x%s", r[i], (i % 16) == 15 ? "\n" : " ");
}

/*
 * 2. VRAM: write and read back with two patterns, and time it. The
 *    results are kept and printed afterwards, since under EmuTOS the
 *    console draws into the VRAM being tested.
 */
static long pass_time[2], pass_errors[2], pass_where[2][8];

static int vram_pass(invert)
int invert;
{
    unsigned char *d = &IO(V_DATA0);
    long n, t0, errors = 0;
    unsigned char v;

    vera_addr(0L, INC1);
    t0 = ticks();
    for (n = 0; n < VRAM_TEST_END; n++) {
        v = (n ^ (n >> 8) ^ (n >> 16)) & 0xff;
        *d = invert ? ~v : v;
    }
    pass_time[invert] = ticks() - t0;

    /*
     * Read back without auto-increment, setting the address for each
     * byte: on this card, data port reads do not step the address
     * (see test 7). Writing ADDR_L makes the VERA fetch the new byte.
     */
    vera_addr(0L, 0);
    for (n = 0; n < VRAM_TEST_END; n++) {
        if ((n & 0xff) == 0) {          /* new 256-byte page */
            IO(V_ADDR_M) = n >> 8;
            IO(V_ADDR_H) = (n >> 16) & 1;
        }
        IO(V_ADDR_L) = n;
        v = (n ^ (n >> 8) ^ (n >> 16)) & 0xff;
        if (invert)
            v = ~v;
        if (*d != v) {
            if (errors < 8)
                pass_where[invert][errors] = n;
            errors++;
        }
    }
    pass_errors[invert] = errors;

    return errors == 0;
}

static void report_pass(title, invert)
char *title;
int invert;
{
    long t = pass_time[invert];
    int i;

    printf("%s\n", title);
    printf("  write %ld bytes: %ld.%02ld s\n", VRAM_TEST_END, t / 200, (t % 200) / 2);
    for (i = 0; i < 8 && i < pass_errors[invert]; i++)
        printf("  error at %05lx\n", pass_where[invert][i]);
    printf("  read back: %ld errors\n", pass_errors[invert]);
}

static void test_vram()
{
    int ok;

    printf("\nVRAM test, 0x00000-0x%05lx (overwrites the screen)\n", VRAM_TEST_END - 1);
    if (!screen_keep())
        return;
    ok = vram_pass(0);
    ok &= vram_pass(1);
    screen_restore();

    report_pass("Pattern 1:", 0);
    report_pass("Pattern 2 (inverted):", 1);
    printf("VRAM test %s\n", ok ? "PASSED" : "FAILED");
}

/*
 * 3. Test card in the planned GEM mode: 640x400 at 1 bpp,
 *    letterboxed in the 640x480 VGA picture (lines 40-439)
 */
static int card_byte(x, y)              /* x in bytes (0-79), y in lines */
int x, y;
{
    if (y == 0 || y == 399)
        return 0xff;                    /* top and bottom border */
    if (x == 0)
        return 0x80;                    /* left border */
    if (x == 1 && y >= 8 && y < 16)
        return 0xf0;                    /* bit order check: a dash in pixels 8-11 */
    if (x == 79)
        return 0x01;                    /* right border */
    if (y >= 32 && y < 96)
        return (x & 1) ? 0x00 : 0xff;   /* vertical bars, 8 pixels wide */
    if (y >= 128 && y < 272)
        return ((x >> 1) + (y >> 4)) & 1 ? 0xff : 0x00;   /* checkerboard */
    if (y >= 304 && y < 368)
        return (y & 1) ? 0xaa : 0x55;   /* fine dither */
    return 0x00;
}

static void card_checklist()
{
    printf("Check on the monitor:\n");
    printf("  - a 1-pixel border on all four sides, picture centred vertically\n");
    printf("  - near the top left, a short dash starting 8 pixels in from the border\n");
    printf("    (if it starts 12 pixels in, the bit order is reversed: MSB = right)\n");
    printf("  - vertical bars, a checkerboard and a fine grey dither, all stable\n");
}

static void test_card()
{
    unsigned char *d = &IO(V_DATA0);
    static unsigned char frame[80];
    int x, y;
    long t0, t_frame, t_copy;

    printf("\nTest card: 640x400, 1 bpp, bitmap at VRAM 0x00000\n");
    if (cookie) {
        card_checklist();
        printf("The test card stays up until you press a key.\n");
    }
    if (!screen_keep())
        return;
    flush_keys();

    IO(V_CTRL) = 0;                     /* DCSEL = 0 */
    IO(V_DC0) = 0x00;                   /* video off while setting up */
    IO(V_DC1) = 128;                    /* HSCALE 1:1, 640 pixels */
    IO(V_DC2) = 128;                    /* VSCALE 1:1, 480 lines */
    IO(V_DC3) = 0;                      /* border colour 0 */
    IO(V_CTRL) = 1 << 1;                /* DCSEL = 1: active area */
    IO(V_DC0) = 0;                      /* HSTART = 0 */
    IO(V_DC1) = 640 / 4;                /* HSTOP = 640 */
    IO(V_DC2) = 40 / 2;                 /* VSTART = line 40 */
    IO(V_DC3) = 440 / 2;                /* VSTOP = line 440 */
    IO(V_CTRL) = 0;

    IO(V_L0_CONFIG) = 0x04;             /* bitmap mode, 1 bpp */
    IO(V_L0_TILEBASE) = 0x01;           /* bitmap at VRAM 0, 640 pixels wide */
    IO(V_L0_HSCROLL_H) = 0;             /* palette offset 0: black, white */
    IO(V_L0_VSCROLL_L) = 0;
    IO(V_L0_VSCROLL_H) = 0;

    /* time a full frame copy: 400 rows of 80 bytes from RAM */
    vera_addr(0L, INC1);
    t0 = ticks();
    for (y = 0; y < 400; y++) {
        for (x = 0; x < 80; x++)
            frame[x] = card_byte(x, y);
        for (x = 0; x < 80; x++)        /* only this loop is the copy */
            *d = frame[x];
    }
    t_frame = ticks() - t0;

    IO(V_DC0) = 0x11;                   /* VGA output, layer 0 only */

    vera_addr(0L, INC1);                /* copy timing alone */
    t0 = ticks();
    for (y = 0; y < 400; y++)
        for (x = 0; x < 80; x++)
            *d = frame[x];
    t_copy = ticks() - t0;

    /* redraw the real card (the timing loop above repeated the last row) */
    vera_addr(0L, INC1);
    for (y = 0; y < 400; y++)
        for (x = 0; x < 80; x++)
            *d = card_byte(x, y);

    if (cookie) {
        get_key();
        screen_restore();
    }

    printf("Frame drawn in %ld.%02ld s (includes building the rows)\n",
           t_frame / 200, (t_frame % 200) / 2);
    printf("Copy of 32000 bytes alone: %ld.%02ld s (target: under 0.15 s in assembly)\n",
           t_copy / 200, (t_copy % 200) / 2);
    if (!cookie)
        card_checklist();
}

/*
 * 4. Vertical blank: count VSYNC flags and look for the interrupt line.
 *    Under EmuTOS, its timer interrupt takes the VSYNC flags (they are
 *    its VBL), so the test counts EmuTOS's VBLs instead.
 */
static int ipnd_seen(n)                 /* IR0-IR7 pending at any time in n ticks */
long n;
{
    long end = ticks() + n;
    int seen = 0;

    while (ticks() < end)
        seen |= ICU_IPND;
    return seen & 0xff;
}

static void test_vsync()
{
    long end, count = 0;
    int before, during;

    if (cookie) {
        printf("\nVertical blank: EmuTOS's VBL (_frclock), counted for 2 seconds\n");
        count = *(long *)0x466L;
        wait_ticks(400L);
        count = *(long *)0x466L - count;
        printf("%ld VBLs in 2 s: %ld.%ld Hz (60: VERA VSYNC; 50: timer fallback)\n",
               count, count / 2, (count % 2) * 5);
    } else {
        printf("\nVertical blank (VSYNC), polled for 2 seconds\n");
        IO(V_ISR) = 0x01;               /* clear a pending VSYNC */
        end = ticks() + 400;
        while (ticks() < end) {
            if (IO(V_ISR) & 0x01) {
                count++;
                IO(V_ISR) = 0x01;       /* acknowledge */
            }
        }
        printf("%ld VSYNCs in 2 s: %ld.%ld Hz (expected 60)\n",
               count, count / 2, (count % 2) * 5);
    }

    /*
     * The interrupt line: watch the pending register with the VSYNC
     * interrupt off, then on. EmuTOS may clear the flag within 5 ms,
     * so it is sampled continuously.
     */
    IO(V_IEN) = 0x00;
    before = ipnd_seen(20L);
    IO(V_IEN) = 0x01;                   /* enable the VSYNC interrupt */
    during = ipnd_seen(20L);
    IO(V_IEN) = 0x00;
    IO(V_ISR) = 0x01;

    printf("NS32202 pending IR0-IR7: %02x before, %02x with VERA IRQ active\n",
           before, during);
    if ((during & ~before) != 0)        /* other inputs, like the timer, come and go */
        printf("The VERA interrupt reaches the NS32202 (new bits: %02x)\n",
               during & ~before);
    else
        printf("No change seen: IRQ line not wired, or not on IR0-IR7\n");
}

/*
 * 5. Keyboard controller, keyboard and mouse
 */
static int kbc_wait_write()
{
    long end = ticks() + 100;

    while (ticks() < end)
        if (!(IO(KBC_STAT) & KBC_IBF))
            return 1;
    return 0;
}

static int kbc_read(timeout)            /* returns -1 on timeout */
long timeout;
{
    long end = ticks() + timeout;

    while (ticks() < end)
        if (IO(KBC_STAT) & KBC_OBF)
            return IO(KBC_DATA);
    return -1;
}

static void kbc_command(cmd)
int cmd;
{
    if (kbc_wait_write())
        IO(KBC_STAT) = cmd;
}

static void kbc_write_data(v)
int v;
{
    if (kbc_wait_write())
        IO(KBC_DATA) = v;
}

static void kbc_flush()
{
    while (kbc_read(10L) >= 0)
        ;
}

/* Wait for a given byte, skipping others (such as the keyboard's
 * power-up AA still waiting). Return it, the last other byte, or -1. */
static int kbc_expect(want, timeout)
int want;
long timeout;
{
    long end = ticks() + timeout;
    int v, last = -1;

    while (ticks() < end)
        if (IO(KBC_STAT) & KBC_OBF) {
            v = inb(KBC_DATA);
            if (v == want)
                return v;
            last = v;
        }
    return last;
}

static void expect(what, got, want)
char *what;
int got, want;
{
    if (got < 0)
        printf("  %s: no answer\n", what);
    else
        printf("  %s: %02x %s\n", what, got, got == want ? "OK" : "(unexpected)");
}

static void test_keyboard()
{
    int v, n, packet[3], stat;

    if (cookie) {
        if (cookie->version < 2) {
            printf("\nThis EmuTOS can't lend the keyboard controller (VERA cookie version %d;\n",
                   cookie->version);
            printf("version 2 is needed): build a newer EmuTOS for this test\n");
            return;
        }
        (*cookie->kbd_hold)(1L);        /* EmuTOS stops polling the controller */
    }
    flush_keys();

    printf("\nVT82C42 keyboard controller at 0xa0/0xa1, status %02x\n", inb(KBC_STAT));
    kbc_flush();

    kbc_command(0xaa);                  /* controller self-test */
    expect("Controller self-test (55)", kbc_expect(0x55, 200L), 0x55);
    kbc_command(0xab);                  /* keyboard interface test */
    expect("Keyboard interface test (00)", kbc_expect(0x00, 100L), 0x00);
    kbc_command(0xa9);                  /* mouse interface test */
    expect("Mouse interface test (00)", kbc_expect(0x00, 100L), 0x00);

    kbc_command(0x60);                  /* configuration: polled, translation on */
    kbc_write_data(0x40);
    kbc_command(0xae);                  /* enable keyboard */
    kbc_command(0xa8);                  /* enable mouse */
    kbc_flush();                        /* bytes held while they were disabled */

    kbc_write_data(0xff);               /* reset keyboard */
    expect("Keyboard reset ack (fa)", kbc_expect(0xfa, 200L), 0xfa);
    expect("Keyboard self-test (aa)", kbc_expect(0xaa, 400L), 0xaa);

    kbc_command(0xd4);                  /* next byte to the mouse */
    kbc_write_data(0xff);               /* reset mouse */
    expect("Mouse reset ack (fa)", kbc_expect(0xfa, 200L), 0xfa);
    expect("Mouse self-test (aa)", kbc_expect(0xaa, 400L), 0xaa);
    expect("Mouse ID (00)", kbc_expect(0x00, 100L), 0x00);
    kbc_command(0xd4);
    kbc_write_data(0xf4);               /* enable mouse reporting */
    expect("Mouse enable ack (fa)", kbc_expect(0xfa, 200L), 0xfa);

    printf("Press keys on the PS/2 keyboard and move the mouse.\n");
    printf("Press Esc on the PS/2 keyboard, or any key on the serial console, to stop.\n");
    n = 0;
    while (!key_waiting()) {
        stat = IO(KBC_STAT);
        if (!(stat & KBC_OBF))
            continue;
        v = IO(KBC_DATA);
        if (stat & KBC_AUX) {
            packet[n++] = v;
            if (n == 3) {               /* buttons, dx, dy */
                printf("Mouse: buttons %d%d%d dx %4d dy %4d\n",
                       packet[0] & 1, (packet[0] >> 2) & 1, (packet[0] >> 1) & 1,
                       (packet[0] & 0x10) ? packet[1] - 256 : packet[1],
                       (packet[0] & 0x20) ? packet[2] - 256 : packet[2]);
                n = 0;
            }
        } else {
            printf("Key: scancode %02x (%s)\n", v, (v & 0x80) ? "release" : "press");
            if (v == 0x81)              /* Esc released */
                break;
        }
    }
    flush_keys();

    kbc_command(0xd4);
    kbc_write_data(0xf5);               /* disable mouse reporting */
    kbc_flush();

    if (cookie) {
        printf("Giving the keyboard and mouse back to EmuTOS\n");
        (*cookie->kbd_hold)(0L);        /* sets them up again */
    }
}

/*
 * 6. Parallel port (PC conventions: control bits 0, 1 and 3 are inverted
 *    on the cable, status bit 7 is the inverted BUSY line)
 */
static void show_status()
{
    int s = IO(LPT_STAT);

    printf("  status %02x: %s %s %s %s %s\n", s,
           (s & 0x80) ? "ready" : "BUSY",
           (s & 0x40) ? "ack-idle" : "ACK",
           (s & 0x20) ? "PAPER-OUT" : "paper",
           (s & 0x10) ? "selected" : "not-selected",
           (s & 0x08) ? "no-error" : "ERROR");
}

static void test_lpt()
{
    int i, v, ok, c;
    static char line[] = "Hello from EmuTOS on the Mini-M68k!\r\n";
    char *p;
    long end;

    printf("\nParallel port at 0xa4-0xa6\n");

    ok = 1;
    for (i = 0; i < 256; i += 0x11) {
        IO(LPT_DATA) = i;
        if (IO(LPT_DATA) != i)
            ok = 0;
    }
    printf("  data register read-back: %s\n", ok ? "OK" : "different (output-only port?)");

    IO(LPT_CTRL) = CTRL_SELECT;         /* init active */
    wait_ticks(2L);
    IO(LPT_CTRL) = CTRL_SELECT | CTRL_INIT;
    v = IO(LPT_CTRL) & 0x0f;
    printf("  control read-back: %x %s\n", v,
           v == (CTRL_SELECT | CTRL_INIT) ? "OK" : "(expected c)");
    wait_ticks(20L);                    /* let the printer finish its init */
    show_status();

    printf("Send a test line to the printer? (y/n) ");
    c = get_key();
    printf("%c\n", c);
    if ((c | 0x20) != 'y')
        return;

    for (p = line; *p; p++) {
        end = ticks() + 400;            /* 2 s per character */
        while (!(IO(LPT_STAT) & 0x80) && ticks() < end)
            ;
        if (!(IO(LPT_STAT) & 0x80)) {
            printf("  printer stays busy\n");
            show_status();
            return;
        }
        IO(LPT_DATA) = *p;
        IO(LPT_CTRL) = CTRL_SELECT | CTRL_INIT | CTRL_STROBE;
        IO(LPT_CTRL) = CTRL_SELECT | CTRL_INIT;
    }
    printf("  sent\n");
    show_status();
}

/*
 * 8. Printer handshake: send a line with each STROBE polarity, and watch
 *    the status after every byte for the printer's answer (BUSY going
 *    active, or an ACK pulse). A printer that takes a byte shows one of
 *    them; if neither ever shows, it never saw a strobe. The lines end
 *    with a form feed, so a page printer prints them too.
 */
static int lpt_send(s, idle, pulse, answers)
char *s;
int idle, pulse;
int *answers;
{
    int i, st, seen;
    long end;

    IO(LPT_CTRL) = idle;
    wait_ticks(2L);
    *answers = 0;
    for ( ; *s; s++) {
        end = ticks() + 400;            /* 2 s per character */
        while (!(IO(LPT_STAT) & 0x80) && ticks() < end)
            ;
        if (!(IO(LPT_STAT) & 0x80))
            return 0;                   /* stays busy */
        IO(LPT_DATA) = *s;
        IO(LPT_CTRL) = pulse;
        IO(LPT_CTRL) = idle;
        seen = 0;
        for (i = 0; i < 2000; i++) {    /* some ms */
            st = inb(LPT_STAT);
            if ((st & 0xc0) != 0xc0)    /* BUSY or ACK active */
                seen = 1;
        }
        *answers += seen;
    }
    return 1;
}

static void test_lpt_handshake()
{
    static char line_pc[] = "Strobe polarity A (PC)\r\n\f";
    static char line_inv[] = "Strobe polarity B (inverted)\r\n\f";
    int n, ok;

    printf("\nPrinter handshake (the printer must be online)\n");
    show_status();

    ok = lpt_send(line_pc, CTRL_SELECT | CTRL_INIT, CTRL_SELECT | CTRL_INIT | CTRL_STROBE, &n);
    printf("  A, PC polarity: %s, answered %d of %d bytes\n",
           ok ? "sent" : "printer stays busy", n, (int)sizeof(line_pc) - 1);

    ok = lpt_send(line_inv, CTRL_SELECT | CTRL_INIT | CTRL_STROBE, CTRL_SELECT | CTRL_INIT, &n);
    printf("  B, inverted:    %s, answered %d of %d bytes\n",
           ok ? "sent" : "printer stays busy", n, (int)sizeof(line_inv) - 1);

    IO(LPT_CTRL) = CTRL_SELECT | CTRL_INIT;     /* back to the PC idle state */
    show_status();
}

/*
 * 9. Printer pins, for measuring on the DB-25 with nothing connected:
 *    fixed states one key at a time (the status is ignored), then the
 *    strobe pulsing continuously, for a scope.
 */
static void lpt_step(what, data, ctrl)
char *what;
int data, ctrl;
{
    IO(LPT_DATA) = data;
    IO(LPT_CTRL) = ctrl;
    printf("  %s\n    (data %02x, control %x; a key for the next step) ", what, data, ctrl);
    get_key();
    printf("\n");
}

static void test_lpt_pins()
{
    int c;

    printf("\nPrinter pins (DB-25; 1 STROBE, 2-9 D0-D7, 14 AUTOFEED, 16 INIT, 17 SELECT IN)\n");
    printf("  status %02x (with nothing connected the inputs may float)\n", inb(LPT_STAT));

    lpt_step("1. idle (PC): pin 1 high, 14 high, 16 high, 17 low; data 2-9 low",
             0x00, CTRL_SELECT | CTRL_INIT);
    lpt_step("2. data 55: pins 2, 4, 6, 8 high (D0, D2, D4, D6), 3, 5, 7, 9 low",
             0x55, CTRL_SELECT | CTRL_INIT);
    lpt_step("3. data aa: pins 3, 5, 7, 9 high, 2, 4, 6, 8 low",
             0xaa, CTRL_SELECT | CTRL_INIT);
    lpt_step("4. STROBE active: pin 1 low (the rest as in step 1)",
             0x00, CTRL_SELECT | CTRL_INIT | CTRL_STROBE);
    lpt_step("5. AUTOFEED active: pin 14 low",
             0x00, CTRL_SELECT | CTRL_INIT | CTRL_AUTOLF);
    lpt_step("6. INIT active: pin 16 low",
             0x00, CTRL_SELECT);
    lpt_step("7. SELECT IN inactive: pin 17 high",
             0x00, CTRL_INIT);

    printf("  8. strobe pulsing on pin 1, data counting on 2-9 (a key to stop)\n");
    for (c = 0; !key_waiting(); c++) {
        IO(LPT_DATA) = c;
        IO(LPT_CTRL) = CTRL_SELECT | CTRL_INIT | CTRL_STROBE;
        IO(LPT_CTRL) = CTRL_SELECT | CTRL_INIT;
    }
    get_key();

    IO(LPT_DATA) = 0;
    IO(LPT_CTRL) = CTRL_SELECT | CTRL_INIT;     /* back to idle */
    printf("  done\n");
}

/*
 * 7. VRAM access diagnostic: single addresses against auto-increment,
 *    to find out whether each data port access steps the address by one
 */
static void show16(title, v)
char *title;
int v[];
{
    int i;

    printf("%s\n   ", title);
    for (i = 0; i < 16; i++)
        printf(" %02x", v[i]);
    printf("\n");
}

static void test_vram_diag()
{
    int i, a[16], b[16], c[16], d[3], keep[16];

    printf("\nVRAM access diagnostic, addresses 0-15 (each line should count up)\n");

    /* the 16 bytes are the top left of the screen: keep them */
    vera_hold();
    for (i = 0; i < 16; i++) {
        vera_addr((long)i, 0);
        keep[i] = inb(V_DATA0);
    }

    /* A: no auto-increment, one address at a time */
    for (i = 0; i < 16; i++) {
        vera_addr((long)i, 0);
        IO(V_DATA0) = 0x10 + i;
    }
    for (i = 0; i < 16; i++) {
        vera_addr((long)i, 0);
        a[i] = inb(V_DATA0);
    }

    /* B: write with auto-increment, read one address at a time */
    vera_addr(0L, INC1);
    for (i = 0; i < 16; i++)
        IO(V_DATA0) = 0x20 + i;
    for (i = 0; i < 16; i++) {
        vera_addr((long)i, 0);
        b[i] = inb(V_DATA0);
    }

    /* C: read with auto-increment what B wrote */
    vera_addr(0L, INC1);
    for (i = 0; i < 16; i++)
        c[i] = inb(V_DATA0);

    /* D: where did the address end up after 16 auto-increment reads? */
    d[0] = inb(V_ADDR_H) & 1;
    d[1] = inb(V_ADDR_M);
    d[2] = inb(V_ADDR_L);

    for (i = 0; i < 16; i++) {
        vera_addr((long)i, 0);
        IO(V_DATA0) = keep[i];
    }
    vera_release();

    show16("A. 10-1f written and read one address at a time:", a);
    show16("B. 20-2f written with auto-increment, read one address at a time:", b);
    show16("C. the same bytes read with auto-increment:", c);
    printf("D. address after the 16 reads of C: %02x%02x%02x (expected 000010)\n",
           d[0], d[1], d[2]);

    printf("If A is wrong: VRAM data path. If only B is wrong: writes step wrongly.\n");
    printf("If only C or D is wrong: reads step wrongly (e.g. a doubled RD pulse).\n");
}

/*
 * p. Mouse pointer: palette entries 0-31, sprite 0's attributes, and its
 *    image (read only). The fVDI driver's pointer uses entries 17
 *    (outline) and 18 (arrow), with its image at VRAM 0x1f400.
 */
static int vram_byte(addr)
long addr;
{
    vera_addr(addr, 0);
    return inb(V_DATA0);
}

static void test_pointer()
{
    static int pal[64], spr[8], img[32];
    long image;
    int i;

    vera_hold();
    for (i = 0; i < 64; i++)
        pal[i] = vram_byte(0x1fa00L + i);
    for (i = 0; i < 8; i++)
        spr[i] = vram_byte(0x1fc00L + i);
    image = ((long)(spr[1] & 0x0f) << 13) | ((long)spr[0] << 5);
    for (i = 0; i < 32; i++)
        img[i] = vram_byte(image + i);
    vera_release();

    printf("\nPalette entries 0-31 (0x0RGB):\n");
    for (i = 0; i < 32; i++)
        printf("%2d:%x%02x%s", i, pal[2 * i + 1] & 0x0f, pal[2 * i],
               (i % 8) == 7 ? "\n" : "  ");
    printf("Sprite 0: %02x %02x %02x %02x %02x %02x %02x %02x\n",
           spr[0], spr[1], spr[2], spr[3], spr[4], spr[5], spr[6], spr[7]);
    printf("  image at %05lx, %s, x %d, y %d, z %d, %dx%d, palette offset %d\n",
           image, (spr[1] & 0x80) ? "8 bpp" : "4 bpp",
           spr[2] | ((spr[3] & 3) << 8), spr[4] | ((spr[5] & 3) << 8),
           (spr[6] >> 2) & 3, 8 << ((spr[7] >> 4) & 3), 8 << ((spr[7] >> 6) & 3),
           spr[7] & 0x0f);
    printf("  image rows 0-3:\n");
    for (i = 0; i < 32; i++)
        printf("%02x%s", img[i], (i % 8) == 7 ? "\n" : " ");

    /* Under fVDI, the XBIOS colour calls go to its VERA driver, which
     * answers from its own copy of the colours (ST format, 0x0RGB) */
    printf("XBIOS Setcolor(n, -1), 0-15:\n");
    for (i = 0; i < 16; i++)
        printf("%2d:%03x%s", i, (int)xbios(7, i, -1) & 0x0fff, (i % 8) == 7 ? "\n" : "  ");
}

static void reset_vera()
{
    int c;

    if (cookie) {
        printf("\nEmuTOS is using the card: after a reset the screen stays blank\n");
        printf("until you restart EmuTOS. Reset anyway? (y/n) ");
        c = get_key();
        printf("%c\n", c);
        if ((c | 0x20) != 'y')
            return;
    }
    vera_hold();
    IO(V_CTRL) = 0x80;                  /* reset */
    wait_ticks(2L);
    IO(V_CTRL) = 0;
    vera_release();
    printf("\nVERA reset\n");
}

main()
{
    long ssp;
    int c;

    ssp = Super(0L);                    /* the ECB I/O space is supervisor only */
    find_cookie();
    find_card();
    if (cookie)
        printf("Sharing the card with EmuTOS (VERA cookie version %d)\n", cookie->version);
    else
        printf("No VERA cookie: the tests take the card over\n");

    for (;;) {
        printf("\nVERA card test\n");
        printf("  1  VERA identity and registers\n");
        printf("  2  VRAM test and speed\n");
        printf("  3  Test card (640x400, 1 bpp)\n");
        printf("  4  Vertical blank and interrupt line\n");
        printf("  5  Keyboard and mouse (VT82C42)\n");
        printf("  6  Parallel port\n");
        printf("  7  VRAM access diagnostic (auto-increment)\n");
        printf("  8  Printer handshake (strobe polarity)\n");
        printf("  9  Printer pins (for measuring, nothing connected)\n");
        printf("  p  Mouse pointer: palette and sprite 0\n");
        printf("  r  Reset VERA\n");
        printf("  q  Quit\n");
        printf("Choice: ");
        c = get_key();
        printf("%c\n", c);

        switch (c) {
        case '1': test_vera_id(); break;
        case '2': test_vram(); break;
        case '3': test_card(); break;
        case '4': test_vsync(); break;
        case '5': test_keyboard(); break;
        case '6': test_lpt(); break;
        case '7': test_vram_diag(); break;
        case '8': test_lpt_handshake(); break;
        case '9': test_lpt_pins(); break;
        case 'p': case 'P': test_pointer(); break;
        case 'r': case 'R': reset_vera(); break;
        case 'q': case 'Q':
            Super(ssp);
            return 0;
        }
    }
}
