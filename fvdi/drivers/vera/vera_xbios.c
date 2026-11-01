/*
 * XBIOS colour calls for the VERA fVDI driver (RetroBrew Mini-M68k).
 *
 * Copyright (C) 2026 Dan Werner
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

/*
 * Once the driver owns the VERA, EmuTOS no longer writes its palette, so
 * the driver takes over trap #14 for Setcolor (7) and Setpalette (6), as
 * a TOS program would expect on an ST: the colour numbers are hardware
 * colours, and the values are in the STe format (bit 3 of each component
 * is the low bit). Setpalette takes effect at once rather than at the
 * next VBL. All other XBIOS calls go on to the previous handler.
 */

#include <osbind.h>         /* Setexc() */

#include "vera.h"

long vera_xbios(int16_t *args);
void vera_trap14(void);

/* Kept out of the BSS, whose last bytes were found zeroed after start-up
 * (cause not yet known): a zeroed pointer here would break every XBIOS
 * call. A non-zero initial value puts it in the data section; xbios_init()
 * replaces it before the hook goes in. */
void (*vera_old_trap14)(void) = vera_trap14;

/*
 * The arguments are on the user stack, or after the exception frame when
 * the call came from supervisor mode (6 bytes on a 68000, 8 on later CPUs).
 * Registers d1-d2/a1-a2 may be changed by an XBIOS call, but the C code
 * is not told that, so they are saved anyway.
 */
__asm__(
    "    .text\n"
    "    .even\n"
    "    .globl  _vera_trap14\n"
    "_vera_trap14:\n"
    "    move.l  %usp,%a0\n"
    "    btst    #5,(%sp)\n"
    "    beq.s   1f\n"
    "    lea     6(%sp),%a0\n"
    "    tst.w   0x59e\n"
    "    beq.s   1f\n"
    "    addq.l  #2,%a0\n"
    "1:  cmp.w   #6,(%a0)\n"
    "    beq.s   2f\n"
    "    cmp.w   #7,(%a0)\n"
    "    beq.s   2f\n"
    "    move.l  _vera_old_trap14,-(%sp)\n"
    "    rts\n"
    "2:  movem.l %d1-%d2/%a1-%a2,-(%sp)\n"
    "    move.l  %a0,-(%sp)\n"
    "    jsr     _vera_xbios\n"
    "    addq.l  #4,%sp\n"
    "    movem.l (%sp)+,%d1-%d2/%a1-%a2\n"
    "    rte\n"
);

/* One STe colour component to 4 bits, as EmuTOS does it */
static uint16_t from_ste(uint16_t n)
{
    return ((n & 7) << 1) | ((n >> 3) & 1);
}

static uint16_t to_ste(uint16_t v)
{
    return ((v >> 1) & 7) | ((v & 1) << 3);
}

static uint16_t ste_to_rgb(uint16_t c)
{
    return (from_ste(c >> 8) << 8) | (from_ste(c >> 4) << 4) | from_ste(c);
}

/* Supervisor mode: args points at the function number */
long vera_xbios(int16_t *args)
{
    uint16_t i;

    if (args[0] == 7)                   /* Setcolor(num, colour) */
    {
        uint16_t num = args[1] & 0x0f;
        uint16_t old, old_ste;

        v_begin();
        old = read_hw_colour(num);
        v_end();
        old_ste = (to_ste(old >> 8) << 8) | (to_ste(old >> 4) << 4) | to_ste(old);

        if (args[2] >= 0)
            set_hw_colour(num, ste_to_rgb(args[2]));
        return old_ste & 0x0777;        /* like an ST, as EmuTOS does */
    }

    /* Setpalette(palette) */
    {
        uint32_t address = ((uint32_t)(uint16_t)args[1] << 16) | (uint16_t)args[2];
        const uint16_t *palette = (const uint16_t *)(address & ~1UL);

        if (palette)
            for (i = 0; i < 16; i++)
                set_hw_colour(i, ste_to_rgb(palette[i]));
    }
    return 0;
}

/* Take over trap #14 (works in user mode: Setexc is a BIOS call) */
void xbios_init(void)
{
    vera_old_trap14 = (void (*)(void))Setexc(46, vera_trap14);
}
