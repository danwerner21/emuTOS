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

#if CONF_WITH_VERA_DIRECT

/*
 * Direct drawing helpers (see vera_direct.c). Writes go through DATA1,
 * whose address (ADDR1) the caller has set with an increment. Reads go
 * through DATA0, with ADDR0_H already set to bank 0 and no increment:
 * on this card reads do not advance the address, so the low (and, every
 * 256 bytes, the middle) address byte is written before each read.
 */
#define VERA_DATA1      0xffff8084

/* void vd_write(const UBYTE *src, UWORD count); */
        .globl  _vd_write
_vd_write:
        move.l  4(sp),a0
        move.w  8(sp),d1
        lea     VERA_DATA1,a1
        jra     write_next
write_loop:
        move.b  (a0)+,(a1)
write_next:
        dbra    d1,write_loop
        rts

/* void vd_fill(UWORD value, UWORD count); value in the low byte */
        .globl  _vd_fill
_vd_fill:
        move.w  4(sp),d0
        move.w  6(sp),d1
        lea     VERA_DATA1,a1
        jra     fill_next
fill_loop:
        move.b  d0,(a1)
fill_next:
        dbra    d1,fill_loop
        rts

/* void vd_read(UBYTE *dst, UWORD vram, UWORD count); */
        .globl  _vd_read
_vd_read:
        movem.l d2/a2,-(sp)
        move.l  8+4(sp),a0              // destination in RAM
        move.w  8+8(sp),d0              // VRAM address (bank 0)
        move.w  8+10(sp),d1             // byte count
        jeq     read_done
        subq.w  #1,d1
        lea     VERA_ADDR_L,a1
        lea     VERA_DATA0,a2
        move.w  d0,d2
        lsr.w   #8,d2
        move.b  d2,VERA_ADDR_M
read_loop:
        move.b  d0,(a1)                 // address low byte: fetches the data
        move.b  (a2),(a0)+
        addq.b  #1,d0
        jne     read_same_page
        addq.b  #1,d2                   // next 256-byte page
        move.b  d2,VERA_ADDR_M
read_same_page:
        dbra    d1,read_loop
read_done:
        movem.l (sp)+,d2/a2
        rts

/* void vd_copy(UWORD src_vram, UWORD count);
 * copy count bytes from VRAM address src_vram (bank 0) to DATA1 */
        .globl  _vd_copy
_vd_copy:
        movem.l d2/a2,-(sp)
        move.w  8+4(sp),d0              // source VRAM address
        move.w  8+6(sp),d1              // byte count
        jeq     vcopy_done
        subq.w  #1,d1
        lea     VERA_ADDR_L,a0
        lea     VERA_DATA0,a1
        lea     VERA_DATA1,a2
        move.w  d0,d2
        lsr.w   #8,d2
        move.b  d2,VERA_ADDR_M
vcopy_loop:
        move.b  d0,(a0)
        move.b  (a1),(a2)
        addq.b  #1,d0
        jne     vcopy_same_page
        addq.b  #1,d2
        move.b  d2,VERA_ADDR_M
vcopy_same_page:
        dbra    d1,vcopy_loop
vcopy_done:
        movem.l (sp)+,d2/a2
        rts

#endif /* CONF_WITH_VERA_DIRECT */

#endif /* MACHINE_MINI68K */
