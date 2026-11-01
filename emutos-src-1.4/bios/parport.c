/*
 * parport.c - limited parallel port support
 *
 * Copyright (C) 2002-2021 The EmuTOS development team
 *
 * Authors:
 *  LVL   Laurent Vogel
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/licence.txt for details.
 */

#include "emutos.h"
#include "parport.h"
#if WITH_PRINTER
#include "asm.h"
#include "delay.h"
#include "sound.h"
#include "mfp.h"
#include "psg.h"
#include "ikbd.h"
#include "tosvars.h"
#endif
#ifdef MACHINE_MINI68K
#include "mini68k.h"
#endif

/*
 * known differences with respect to the original TOS:
 * - printer hardcopy is not done
 * - no input
 */

#ifdef MACHINE_MINI68K
/*
 * The Mini-M68k's printer port is on the VERA card, at ECB ports
 * 0xa4-0xa6, with the PC's layout: data, status (bit 7 the inverted
 * BUSY line) and control (bit 0 STROBE, 1 = line active; bit 2 INIT,
 * 0 = active; bit 3 SELECT IN).
 */
#define LPT_DATA        (*(volatile UBYTE *)0xffff80a4UL)
#define LPT_STAT        (*(volatile UBYTE *)0xffff80a5UL)
#define LPT_CTRL        (*(volatile UBYTE *)0xffff80a6UL)
#define LPT_NOT_BUSY    0x80
#define LPT_STROBE      0x01
#define LPT_INIT        0x04
#define LPT_SELECT      0x08
#define LPT_IDLE        (LPT_SELECT | LPT_INIT)

static BOOL lpt_present;    /* the VERA card is fitted */
#endif

#if WITH_PRINTER
/* timing stuff */
#define DELAY_1US       delay_loop(delay1us)
static ULONG delay1us;

static WORD printer_config;

/* timeout stuff */
#define CTL_C           ('C'-0x40)
#define SHORT_TIMEOUT   (5 * CLOCKS_PER_SEC)
#define LONG_TIMEOUT    (30 * CLOCKS_PER_SEC)
static ULONG last_timeout;
#endif

#if WITH_PRINTER
/*
 * implements xbios_21 - Set/get the desktop printer configuration word
 */
WORD setprt(WORD config)
{
    WORD old_config = printer_config;

    if (config != -1)
        printer_config = config;

    return old_config;
}

/*
 * do parallel port output
 */
#ifdef MACHINE_MINI68K
static LONG prnout(WORD c)
{
    WORD old_sr;

    old_sr = set_sr(0x2700);    /* keep the strobe pulse short */

    LPT_DATA = c;
    DELAY_1US;                  /* data valid for 500 ns before the strobe */
    LPT_CTRL = LPT_IDLE | LPT_STROBE;
    DELAY_1US;                  /* and a strobe of at least 500 ns */
    LPT_CTRL = LPT_IDLE;

    set_sr(old_sr);
    return 1L;
}
#else
static LONG prnout(WORD c)
{
    WORD old_sr;
    WORD a;

    /* disable interrupts */
    old_sr = set_sr(0x2700);

    /* read PSG multi-function register */
    a = giaccess(0, PSG_MULTI | GIACCESS_READ);

    /* set port B to output mode */
    a |= PSG_PORTB_OUTPUT;

    /* write new value in register */
    giaccess(a, PSG_MULTI | GIACCESS_WRITE);

    /* write char in port B */
    giaccess(c, PSG_PORT_B | GIACCESS_WRITE);

    /*
     * according to the Centronics spec, we must leave valid data on
     * the lines for at least 500ns before pulsing the strobe line,
     * so we leave it for 1 microsecond
     */
    DELAY_1US;

    /*
     * according to the spec, the strobe line must be pulsed low
     * for a minimum of 500ns, so we do it for 1 microsecond
     */
    offgibit(~GI_STROBE);
    DELAY_1US;
    ongibit(GI_STROBE);

    /*
     * at this point, we should wait for ACK to go low, but
     * most drivers don't bother
     */

    /* restore sr */
    set_sr(old_sr);
    return 1L;
}
#endif
#endif

void parport_init(void)
{
#if WITH_PRINTER
#ifdef MACHINE_MINI68K
    lpt_present = mini68k_vera_present();
#else
    /* set Strobe high */
    ongibit(GI_STROBE);
#endif

    /* initialize delay */
    delay1us = loopcount_1_msec / 1000;

#ifdef MACHINE_MINI68K
    if (lpt_present)
    {
        /* reset the printer, as a PC BIOS does: INIT low for 100 us */
        LPT_CTRL = LPT_SELECT;
        delay_loop(loopcount_1_msec / 10);
        LPT_CTRL = LPT_IDLE;
    }
#endif

    /* initialize other printer variables */
    printer_config = 0;     /* Setprt() default: output via parallel port */
    last_timeout = 0UL;     /* parallel port: ticks value at last timeout */
#endif
}

LONG bconin0(void)
{
    /* not implemented */
    return 0;
}

LONG bcostat0(void)
{
#ifdef MACHINE_MINI68K
    if (lpt_present && (LPT_STAT & LPT_NOT_BUSY))
        return -1;
    return 0;   /* busy, or no printer port */
#elif CONF_WITH_PRINTER_PORT
    MFP *mfp=MFP_BASE;

    if(mfp->gpip & 1) {
        return 0;   /* busy high: printer not available */
    } else {
        return -1;
    }
#else
    return 0; /* output not allowed */
#endif
}

LONG bconout0(WORD dev, WORD c)
{
#if WITH_PRINTER
    ULONG now = hz_200;

#ifdef MACHINE_MINI68K
    if (!lpt_present)
        return 0L;
#endif

    /*
     * if we didn't time out 'recently', we check if the port is available,
     * allowing a long timeout; otherwise we just time out immediately.
     * this is how Atari TOS does things.  however, waiting for the long
     * timeout because we accidentally tried to use the printer port is
     * extremely painful, so EmuTOS allows a quick out via ctrl-C.
     */
    if ((last_timeout == 0UL)                   /* first time through? */
     || (now >= (last_timeout+SHORT_TIMEOUT)))
    {
        while(hz_200 < (now+LONG_TIMEOUT))
        {
            if (bcostat0())
                return prnout(c);
            if (bconstat2())
                if ((bconin2() & 0xff) == CTL_C)
                    break;
        }
    }

    last_timeout = hz_200;
#endif
    return 0L;
}
