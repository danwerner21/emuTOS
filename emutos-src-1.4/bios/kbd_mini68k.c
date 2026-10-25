/*
 * kbd_mini68k.c - PS/2 keyboard and mouse for the Mini-M68k
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The VERA card carries a VT82C42 keyboard controller (8042 compatible)
 * at ECB ports 0xa0 (data) and 0xa1 (status/command), with a PS/2
 * keyboard and a PS/2 mouse. Its interrupt cannot be used on this card,
 * so the controller is polled from the 200 Hz system timer.
 *
 * Keyboard: the controller translates the keyboard codes to PC set 1.
 * Set 1 matches the Atari scancodes for the whole main block; the keypad
 * and the E0-prefixed keys are translated with tables. Typematic repeats
 * from the keyboard are dropped, since EmuTOS does its own key repeat.
 *
 * Mouse: each 3-byte PS/2 packet becomes a relative Atari mouse packet.
 * The resolution is 8 counts per mm, with the mouse's 2:1 scaling (an
 * acceleration). The report rate is set to 40 per second, so that
 * keyboard and mouse together stay well below what 200 Hz polling can
 * collect (one byte per poll, as the controller holds one byte at a
 * time).
 */

/* #define ENABLE_KDEBUG */

#include "emutos.h"
#include "mini68k.h"
#include "ikbd.h"
#include "tosvars.h"
#include "biosdefs.h"

#ifdef MACHINE_MINI68K

#define KBC_DATA_PORT   0xa0
#define KBC_STAT_PORT   0xa1    /* read: status, write: command */
#define KBC_DATA        (*(volatile UBYTE *)MINI68K_ECB_IO(KBC_DATA_PORT))
#define KBC_STAT        (*(volatile UBYTE *)MINI68K_ECB_IO(KBC_STAT_PORT))

#define KBC_OBF         0x01    /* output buffer full: data for the CPU */
#define KBC_IBF         0x02    /* input buffer full: do not write */
#define KBC_AUX         0x20    /* the data comes from the mouse */

#define CONFIG_TRANSLATE 0x40   /* configuration byte: set 2 -> set 1, no interrupts */

#define ACK             0xfa
#define SELF_TEST_OK    0xaa
#define MOUSE_RATE      40      /* reports per second */
#define MOUSE_RESOLUTION 3      /* 8 counts per mm (the default is 4) */

#define TIMEOUT_SHORT   (CLOCKS_PER_SEC / 5)
#define TIMEOUT_RESET   CLOCKS_PER_SEC      /* devices answer a reset slowly */

static BOOL kbc_ready;          /* initialised: the timer may poll it */

/* keyboard decoding state */
static BOOL extended;           /* an E0 prefix was received */
static UBYTE pause_skip;        /* bytes of the Pause key sequence to drop */
static UBYTE keys_down[128 / 8]; /* keys held, to drop typematic repeats */

/* mouse packet assembly */
static UBYTE mouse_buf[3];
static UWORD mouse_count;

/*
 * Set 1 to Atari scancodes, for codes without the E0 prefix.
 * Identical in the main block; the keypad differs. 0 = no Atari key.
 */
static const UBYTE atari_from_set1[0x59] =
{
    /* 00 */ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    /* 08 */ 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    /* 10 */ 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
    /* 18 */ 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    /* 20 */ 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
    /* 28 */ 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
    /* 30 */ 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36,
    /* 37 keypad * */ 0x66,
    /* 38 */ 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
    /* 40 */ 0x40, 0x41, 0x42, 0x43, 0x44,
    /* 45 Num Lock */ 0x00,
    /* 46 Scroll Lock */ 0x00,
    /* 47 keypad 7 8 9 - */ 0x67, 0x68, 0x69, 0x4a,
    /* 4b keypad 4 5 6 + */ 0x6a, 0x6b, 0x6c, 0x4e,
    /* 4f keypad 1 2 3 0 . */ 0x6d, 0x6e, 0x6f, 0x70, 0x71,
    /* 54 */ 0x00, 0x00,
    /* 56 ISO key */ 0x60,
    /* 57 F11: Undo */ 0x61,
    /* 58 F12: Help */ 0x62
};

/* Set 1 codes with the E0 prefix */
static UBYTE atari_from_extended(UBYTE code)
{
    switch (code)
    {
    case 0x1c: return 0x72;     /* keypad Enter */
    case 0x1d: return 0x1d;     /* right Control */
    case 0x35: return 0x65;     /* keypad / */
    case 0x38: return 0x38;     /* right Alt */
    case 0x47: return 0x47;     /* Home: Clr/Home */
    case 0x48: return 0x48;     /* up */
    case 0x49: return 0x62;     /* Page Up: Help */
    case 0x4b: return 0x4b;     /* left */
    case 0x4d: return 0x4d;     /* right */
    case 0x50: return 0x50;     /* down */
    case 0x51: return 0x61;     /* Page Down: Undo */
    case 0x52: return 0x52;     /* Insert */
    case 0x53: return 0x53;     /* Delete */
    default: return 0x00;       /* including the fake shifts E0 2A / E0 36 */
    }
}

static void keyboard_byte(UBYTE code)
{
    UBYTE make = code & 0x7f;
    UBYTE atari;
    UBYTE mask;

    if (pause_skip)                 /* Pause: E1 1D 45 E1 9D C5 */
    {
        pause_skip--;
        return;
    }
    if (code == 0xe1)
    {
        pause_skip = 2;
        return;
    }
    if (code == 0xe0)
    {
        extended = TRUE;
        return;
    }
    if (code == 0x00 || code == 0xff || code == ACK || code == 0xfe)
        return;                     /* overrun, acknowledge, resend */

    if (extended)
        atari = atari_from_extended(make);
    else
        atari = (make < ARRAY_SIZE(atari_from_set1)) ? atari_from_set1[make] : 0;
    extended = FALSE;
    if (!atari)
        return;

    mask = 1 << (atari & 7);
    if (code & 0x80)                /* release */
    {
        keys_down[atari >> 3] &= ~mask;
        kbd_int(atari | 0x80);
    }
    else if (!(keys_down[atari >> 3] & mask))   /* new press, not a repeat */
    {
        keys_down[atari >> 3] |= mask;
        kbd_int(atari);
    }
}

static WORD clamp(WORD v)
{
    if (v > 127)
        return 127;
    if (v < -128)
        return -128;
    return v;
}

static void mouse_byte(UBYTE b)
{
    WORD dx, dy;
    SBYTE packet[3];

    /* the first byte of a packet always has bit 3 set: resynchronise */
    if (mouse_count == 0 && !(b & 0x08))
        return;

    mouse_buf[mouse_count++] = b;
    if (mouse_count < 3)
        return;
    mouse_count = 0;

    dx = mouse_buf[1];
    dy = mouse_buf[2];
    if (mouse_buf[0] & 0x10)        /* 9-bit two's complement */
        dx -= 256;
    if (mouse_buf[0] & 0x20)
        dy -= 256;

    /* Atari: 0xf8 header, bit 1 = left button, bit 0 = right button,
     * and y grows downwards (it grows upwards on PS/2) */
    packet[0] = 0xf8 | ((mouse_buf[0] & 0x01) ? 0x02 : 0)
                     | ((mouse_buf[0] & 0x02) ? 0x01 : 0);
    packet[1] = clamp(dx);
    packet[2] = clamp(-dy);
    call_mousevec(packet);
}

/*
 * Called from the 200 Hz timer interrupt
 */
void mini68k_kbd_poll(void)
{
    int i;

    if (!kbc_ready)
        return;

    for (i = 0; i < 4; i++)
    {
        UBYTE stat = KBC_STAT;
        UBYTE data;

        if (!(stat & KBC_OBF))
            break;
        data = KBC_DATA;
        if (stat & KBC_AUX)
            mouse_byte(data);
        else
            keyboard_byte(data);
    }
}

/*
 * Initialisation, with interrupts enabled (timeouts use the system timer)
 */

static WORD kbc_read(LONG timeout)  /* return the byte, or -1 on timeout */
{
    LONG end = hz_200 + timeout;

    while (hz_200 < end)
        if (KBC_STAT & KBC_OBF)
            return KBC_DATA;

    return -1;
}

/*
 * Wait for a given byte, dropping anything else, such as the self-test
 * result a keyboard sends at power-up, which the controller holds until
 * its interface is enabled. The controller's AUX status bit is not used
 * here: it is reliable for mouse movement data, but replies to commands
 * sent to the mouse may not have it.
 */
static BOOL kbc_expect(UBYTE wanted, LONG timeout)
{
    LONG end = hz_200 + timeout;

    while (hz_200 < end)
    {
        if ((KBC_STAT & KBC_OBF) && KBC_DATA == wanted)
            return TRUE;
    }

    return FALSE;
}

static BOOL kbc_wait_write(void)
{
    LONG end = hz_200 + TIMEOUT_SHORT;

    while (hz_200 < end)
        if (!(KBC_STAT & KBC_IBF))
            return TRUE;

    return FALSE;
}

static void kbc_command(UBYTE cmd)
{
    if (kbc_wait_write())
        KBC_STAT = cmd;
}

static void kbc_write(UBYTE data)
{
    if (kbc_wait_write())
        KBC_DATA = data;
}

static void kbc_flush(void)
{
    while (kbc_read(CLOCKS_PER_SEC / 50) >= 0)
        ;
}

/* send a byte to the mouse, and check its acknowledge */
static BOOL mouse_send(UBYTE b)
{
    kbc_command(0xd4);              /* next data byte goes to the mouse */
    kbc_write(b);
    return kbc_expect(ACK, TIMEOUT_SHORT);
}

void mini68k_kbd_init(void)
{
    BOOL kbd_ok, mouse_ok;

    kbc_ready = FALSE;
    if (!mini68k_vera_present())    /* the controller is on the VERA card */
        return;

    kbc_flush();
    kbc_command(0xaa);              /* controller self-test */
    if (kbc_read(TIMEOUT_SHORT) != 0x55)
    {
        KINFO(("Keyboard controller not answering\n"));
        return;
    }

    kbc_command(0x60);              /* configuration byte */
    kbc_write(CONFIG_TRANSLATE);
    kbc_command(0xae);              /* enable the keyboard interface */
    kbc_command(0xa8);              /* enable the mouse interface */
    kbc_flush();                    /* bytes held while they were disabled */

    kbc_write(0xff);                /* reset the keyboard */
    kbd_ok = kbc_expect(ACK, TIMEOUT_SHORT)
          && kbc_expect(SELF_TEST_OK, TIMEOUT_RESET);
    kbc_flush();                    /* anything late from the keyboard */

    mouse_ok = mouse_send(0xff)     /* reset the mouse */
            && kbc_expect(SELF_TEST_OK, TIMEOUT_RESET)
            && kbc_expect(0x00, TIMEOUT_SHORT);     /* mouse ID */

    /* The settings are optional: whatever happens, enable the reports */
    mouse_send(0xf3);               /* report rate */
    mouse_send(MOUSE_RATE);
    mouse_send(0xe8);               /* resolution */
    mouse_send(MOUSE_RESOLUTION);
    mouse_send(0xe7);               /* 2:1 scaling: fast moves go further */
    mouse_ok = mouse_send(0xf4) && mouse_ok;    /* enable reports */

    KDEBUG(("PS/2 keyboard %s, mouse %s\n",
            kbd_ok ? "OK" : "not found", mouse_ok ? "OK" : "not found"));

    kbc_flush();
    extended = FALSE;
    pause_skip = 0;
    mouse_count = 0;
    kbc_ready = TRUE;               /* from now on, the timer polls it */
}

#endif /* MACHINE_MINI68K */
