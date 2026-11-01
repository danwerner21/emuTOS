/*
 * ZSMPLAY.C - play ZSM chiptunes on the VERA's PSG
 *
 * Build on the board with Sozobon C:
 *   cc zsmplay.c -o zsmplay.ttp
 * Usage:
 *   zsmplay tune.zsm       play once
 *   zsmplay -l tune.zsm    play in a loop
 * Any key stops it.
 *
 * ZSM is the Commander X16's music format (Zsound): a stream of writes
 * to the VERA's PSG registers and to the X16's YM2151 FM chip, with
 * delays between them, usually 60 ticks a second. The PSG writes go
 * straight to the VERA, so tunes get all 16 voices and every waveform.
 * There is no YM2151 here: FM parts are skipped, so PSG-only tunes are
 * the ones to choose. PCM parts are skipped too.
 *
 * Under EmuTOS with the VERA drivers, the player holds the 'VERA'
 * cookie's busy flag while it writes, so EmuTOS and fVDI leave the
 * ports alone. EmuTOS's own sounds (the bell, the key click) use voices
 * 0-3; the key click is turned off while a tune plays.
 */

#include <stdio.h>
#include <osbind.h>

static long io_base = 0xffff8000L;      /* ECB port p at io_base + p */

#define IO(p)           (*(unsigned char *)(io_base + (p)))
#define V_ADDR_L        0x80
#define V_ADDR_M        0x81
#define V_ADDR_H        0x82
#define V_DATA0         0x83
#define V_CTRL          0x85
#define VERA_PSG        0x1f9c0L        /* 16 voices of 4 bytes */

/* EmuTOS's 'VERA' cookie (emutos-src-1.4/bios/mini68k.h) */
#define COOKIE_VERA     0x56455241L

struct vera_cookie {
    int version;
    int reserved;
    unsigned char *busy;
    long (*take_over)();
    long (*release_hook)();
    long (*kbd_hold)();
};

static struct vera_cookie *cookie;

static unsigned char *file;
static long file_size;
static long data_start, loop_point;
static int tick_hz;

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

static void vera_hold()
{
    if (cookie)
        (*cookie->busy)++;
}

static void vera_release()
{
    if (cookie && --(*cookie->busy) == 0 && cookie->release_hook)
        (*cookie->release_hook)();
}

/* Write PSG register r (0-63: voice r / 4, byte r % 4) */
static void psg_write(r, v)
int r, v;
{
    long addr = VERA_PSG + r;

    IO(V_CTRL) = 0;                     /* ADDRSEL = 0: DATA0 */
    IO(V_ADDR_L) = addr;
    IO(V_ADDR_M) = addr >> 8;
    IO(V_ADDR_H) = (addr >> 16) & 1;    /* no increment */
    IO(V_DATA0) = v;
}

static void silence()
{
    int v;

    vera_hold();
    for (v = 0; v < 16; v++)
        psg_write(v * 4 + 2, 0);        /* volume 0, no output */
    vera_release();
}

static long ticks()                     /* 200 Hz system timer */
{
    return *(long *)0x4baL;
}

static long get24(p)                    /* little-endian */
unsigned char *p;
{
    return ((long)p[2] << 16) | ((long)p[1] << 8) | p[0];
}

/* Read the whole file into memory; 0 on failure */
static int load(name)
char *name;
{
    int fd;
    long m;

    fd = Fopen(name, 0);
    if (fd < 0) {
        printf("Can't open %s\n", name);
        return 0;
    }
    file_size = Fseek(0L, fd, 2);
    Fseek(0L, fd, 0);
    m = Malloc(file_size);
    if (file_size <= 0 || m <= 0) {
        printf("Not enough memory for %ld bytes\n", file_size);
        Fclose(fd);
        return 0;
    }
    file = (unsigned char *)m;
    if (Fread(fd, file_size, file) != file_size) {
        printf("Read error\n");
        Fclose(fd);
        return 0;
    }
    Fclose(fd);
    return 1;
}

/*
 * The 16-byte header: "zm", version, loop point (24-bit offset from the
 * start of the file, 0 = none), PCM header offset, FM channel mask, PSG
 * channel mask (16 bits), tick rate in Hz (16 bits), 2 reserved.
 */
static int parse()
{
    unsigned int psg_mask;
    int fm_mask, v, n;

    if (file_size < 17 || file[0] != 'z' || file[1] != 'm') {
        printf("Not a ZSM file\n");
        return 0;
    }
    loop_point = get24(file + 3);
    fm_mask = file[9];
    psg_mask = file[10] | (file[11] << 8);
    tick_hz = file[12] | (file[13] << 8);
    data_start = 16;
    if (tick_hz <= 0 || tick_hz > 200)
        tick_hz = 60;
    if (loop_point < data_start || loop_point >= file_size)
        loop_point = 0;

    for (n = 0, v = 0; v < 16; v++)
        if (psg_mask & (1 << v))
            n++;
    printf("ZSM version %d, %d Hz, %d PSG voices%s\n", file[2], tick_hz, n,
           loop_point ? ", loops" : "");
    if (psg_mask == 0) {
        printf("This tune uses only the YM2151 FM chip, which this machine doesn't have\n");
        return 0;
    }
    if (fm_mask)
        printf("Its YM2151 FM parts will be silent (no FM chip here)\n");
    return 1;
}

main(argc, argv)
int argc;
char *argv[];
{
    long ssp, start, due, pos;
    int loop = 0, arg = 1, cmd, n, conterm, stop = 0;
    char *conterm_p = (char *)0x484L;

    if (argc > 1 && argv[1][0] == '-' && (argv[1][1] | 0x20) == 'l') {
        loop = 1;
        arg = 2;
    }
    if (arg >= argc) {
        printf("Usage: zsmplay [-l] tune.zsm   (-l: loop; any key stops)\n");
        return 1;
    }
    if (!load(argv[arg]) || !parse())
        return 1;

    ssp = Super(0L);                    /* the ECB I/O space is supervisor only */
    find_cookie();
    conterm = *conterm_p;
    *conterm_p &= ~1;                   /* no key click over the music */
    silence();

    printf("Playing%s; press a key to stop\n", loop ? " in a loop" : "");
    while (Bconstat(2))
        Bconin(2);

    pos = data_start;
    due = 0;                            /* in 1/tick_hz of 200 Hz ticks */
    start = ticks();
    while (!stop) {
        if (Bconstat(2)) {
            Bconin(2);
            break;
        }
        /* the next commands are due at tick due * 200 / tick_hz */
        if ((ticks() - start) * tick_hz < due * 200L)
            continue;

        /* run commands up to the next delay */
        vera_hold();
        for (;;) {
            if (pos >= file_size) {
                cmd = 0x80;             /* a file cut short ends there */
            } else
                cmd = file[pos++];
            if (cmd < 0x40) {           /* PSG register write */
                psg_write(cmd, file[pos++]);
            } else if (cmd == 0x40) {   /* extension: skip its bytes */
                n = file[pos++] & 0x3f;
                pos += n;
            } else if (cmd < 0x80) {    /* YM2151 writes: register/value pairs */
                pos += 2 * (cmd & 0x3f);
            } else if (cmd == 0x80) {   /* end of the data */
                if (!loop) {
                    stop = 1;
                    break;
                }
                pos = loop_point ? loop_point : data_start;
            } else {                    /* delay of 1-127 ticks */
                due += cmd & 0x7f;
                break;
            }
        }
        vera_release();
    }

    silence();
    *conterm_p = conterm;
    Super(ssp);
    return 0;
}
