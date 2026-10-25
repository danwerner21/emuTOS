/*
 * vera_mini68k2.S - VERA video card copy routine for the Mini-M68k
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

#include "asmdefs.h"

#ifdef MACHINE_MINI68K

/* VERA registers at ECB ports 0x80-0x9f */
#define VERA_ADDR_L     0xffff8080
#define VERA_ADDR_M     0xffff8081
#define VERA_ADDR_H     0xffff8082
#define VERA_DATA0      0xffff8083
#define VERA_CTRL       0xffff8085

#define VERA_INC1       0x10    /* auto-increment by 1, in VERA_ADDR_H */

/*
 * void mini68k_vera_copy(const UBYTE *src, ULONG vram, UWORD count);
 *
 * Copy count bytes (a multiple of 16) from src to VRAM address vram.
 * The 640-pixel bitmap rows are contiguous in VRAM, so any run of rows
 * is a single address setup, then a stream through the data port with
 * auto-increment.
 */
        .globl  _mini68k_vera_copy
_mini68k_vera_copy:
        move.l  4(sp),a0                // source
        move.l  8(sp),d0                // VRAM address
        move.w  12(sp),d1               // byte count
        lea     VERA_DATA0,a1

        clr.b   VERA_CTRL               // ADDRSEL = 0: DATA0
        move.b  d0,VERA_ADDR_L
        lsr.l   #8,d0
        move.b  d0,VERA_ADDR_M
        lsr.l   #8,d0
        and.b   #1,d0
        or.b    #VERA_INC1,d0
        move.b  d0,VERA_ADDR_H

        lsr.w   #4,d1                   // 16 bytes per loop
        jra     copy_next
copy_loop:
        .rept   16
        move.b  (a0)+,(a1)
        .endr
copy_next:
        dbra    d1,copy_loop
        rts

#endif /* MACHINE_MINI68K */
