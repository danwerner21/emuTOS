/*
 * ppide2.S - Parallel port IDE (82C55 PPI) block transfers
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The data register loops of ppide.c, in assembler for the 68008:
 * the 82C55 addresses stay in a register, the strobe values stay in
 * data registers, and the loop is unrolled 8 times (16 bytes).
 * See ppide.c for the bus cycles.
 */

#include "asmdefs.h"

#ifdef MACHINE_MINI68K

/* 82C55 registers, relative to port A: B (+1), C (+2) and control (+3) */
#define PPI_B           1
#define PPI_C           2
#define PPI_CTRL        3

#define PPI_MODE_READ   0x92    /* mode 0, A and B in, C out */
#define PPI_MODE_WRITE  0x80    /* mode 0, all ports out */

#define PPIDE_REG_DATA  0x08
#define PPIDE_WR        0x20
#define PPIDE_RD        0x40

/******************************************************************************/
/* void ppide_read_data(volatile UBYTE *ppi, UBYTE *buffer, ULONG bufferlen,  */
/*                      WORD need_byteswap);                                  */
/******************************************************************************/

        .globl  _ppide_read_data
_ppide_read_data:
        movem.l d2-d4,-(sp)
        move.l  4*3+4(sp),a1            // ppi: port A; B, C and control follow
        move.l  4*3+8(sp),a0            // buffer
        move.l  4*3+12(sp),d3           // bufferlen
        move.w  4*3+16(sp),d4           // need_byteswap
        moveq   #PPIDE_REG_DATA+PPIDE_RD,d1 // RD asserted
        moveq   #PPIDE_REG_DATA,d2      // RD released

        move.b  #PPI_MODE_READ,PPI_CTRL(a1)
        move.b  d2,PPI_C(a1)

        move.l  d3,d0
        lsr.l   #4,d0                   // d0 = number of 16-byte blocks
        tst.w   d4
        jne     rd_swap_start

        jra     rd_next
rd_block:
        .rept   8
        move.b  d1,PPI_C(a1)            // assert RD
        move.b  PPI_B(a1),(a0)+         // IDE D8-D15 first
        move.b  (a1),(a0)+              // then IDE D0-D7
        move.b  d2,PPI_C(a1)            // release RD
        .endr
rd_next:
        subq.l  #1,d0
        jcc     rd_block

        and.w   #15,d3                  // remaining bytes, 2 per word
        lsr.w   #1,d3
        jra     rd_word_next
rd_word:
        move.b  d1,PPI_C(a1)
        move.b  PPI_B(a1),(a0)+
        move.b  (a1),(a0)+
        move.b  d2,PPI_C(a1)
rd_word_next:
        dbra    d3,rd_word
        jra     rd_done

rd_swap_start:
        jra     rd_swap_next
rd_swap_block:
        .rept   8
        move.b  d1,PPI_C(a1)            // assert RD
        move.b  (a1),(a0)+              // IDE D0-D7 first
        move.b  PPI_B(a1),(a0)+         // then IDE D8-D15
        move.b  d2,PPI_C(a1)            // release RD
        .endr
rd_swap_next:
        subq.l  #1,d0
        jcc     rd_swap_block

        and.w   #15,d3
        lsr.w   #1,d3
        jra     rd_swap_word_next
rd_swap_word:
        move.b  d1,PPI_C(a1)
        move.b  (a1),(a0)+
        move.b  PPI_B(a1),(a0)+
        move.b  d2,PPI_C(a1)
rd_swap_word_next:
        dbra    d3,rd_swap_word

rd_done:
        clr.b   PPI_C(a1)               // release the bus
        movem.l (sp)+,d2-d4
        rts

/******************************************************************************/
/* void ppide_write_data(volatile UBYTE *ppi, const UBYTE *buffer,            */
/*                       ULONG bufferlen, WORD need_byteswap);                */
/******************************************************************************/

        .globl  _ppide_write_data
_ppide_write_data:
        movem.l d2-d4,-(sp)
        move.l  4*3+4(sp),a1            // ppi: port A; B, C and control follow
        move.l  4*3+8(sp),a0            // buffer
        move.l  4*3+12(sp),d3           // bufferlen
        move.w  4*3+16(sp),d4           // need_byteswap
        moveq   #PPIDE_REG_DATA+PPIDE_WR,d1 // WR asserted
        moveq   #PPIDE_REG_DATA,d2      // WR released

        move.b  #PPI_MODE_WRITE,PPI_CTRL(a1)
        move.b  d2,PPI_C(a1)

        move.l  d3,d0
        lsr.l   #4,d0                   // d0 = number of 16-byte blocks
        tst.w   d4
        jne     wr_swap_start

        jra     wr_next
wr_block:
        .rept   8
        move.b  (a0)+,PPI_B(a1)         // IDE D8-D15 first
        move.b  (a0)+,(a1)              // then IDE D0-D7
        move.b  d1,PPI_C(a1)            // pulse WR
        move.b  d2,PPI_C(a1)
        .endr
wr_next:
        subq.l  #1,d0
        jcc     wr_block

        and.w   #15,d3                  // remaining bytes, 2 per word
        lsr.w   #1,d3
        jra     wr_word_next
wr_word:
        move.b  (a0)+,PPI_B(a1)
        move.b  (a0)+,(a1)
        move.b  d1,PPI_C(a1)
        move.b  d2,PPI_C(a1)
wr_word_next:
        dbra    d3,wr_word
        jra     wr_done

wr_swap_start:
        jra     wr_swap_next
wr_swap_block:
        .rept   8
        move.b  (a0)+,(a1)              // IDE D0-D7 first
        move.b  (a0)+,PPI_B(a1)         // then IDE D8-D15
        move.b  d1,PPI_C(a1)            // pulse WR
        move.b  d2,PPI_C(a1)
        .endr
wr_swap_next:
        subq.l  #1,d0
        jcc     wr_swap_block

        and.w   #15,d3
        lsr.w   #1,d3
        jra     wr_swap_word_next
wr_swap_word:
        move.b  (a0)+,(a1)
        move.b  (a0)+,PPI_B(a1)
        move.b  d1,PPI_C(a1)
        move.b  d2,PPI_C(a1)
wr_swap_word_next:
        dbra    d3,wr_swap_word

wr_done:
        clr.b   PPI_C(a1)               // release the bus
        movem.l (sp)+,d2-d4
        rts

#endif /* MACHINE_MINI68K */
