/*
 * fdc_mini68k2.S - Disk I/O V3 floppy controller data phase
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

/*
 * The data phase of floppy reads and writes, based on the SBC-386EX
 * driver for the same board (floppy/fdcpio.asm). There is no DMA: every
 * byte passes through the CPU.
 *
 * At 500 kbit/s a byte arrives (or is wanted) every 16 us, which is only
 * 128 cycles of the 8 MHz 68008, so the time from "ready" to the byte
 * being moved is what matters, above all for the first byte:
 *
 *  - Interrupts are masked for the whole data phase, including the wait
 *    for the first byte (up to a disk revolution). During that wait, an
 *    interrupt window is opened about every millisecond, so the system
 *    timer keeps time. If the first byte comes while an interrupt is
 *    being served, the sector overruns and the caller retries it.
 *
 *  - The main status register is compared with the exact value of the
 *    data phase, so one CMP/DBEQ pair both tests it and counts the
 *    timeout, and the byte is moved as soon as the loop falls through:
 *      F0  read data phase: RQM, DIO, EXEC, BUSY (a byte to collect)
 *      B0  write data phase: RQM, EXEC, BUSY (a byte wanted)
 *    The drive busy bits are clear: a seek is always completed with
 *    Sense Interrupt Status before a transfer.
 *
 *  - Anything else is only examined off the fast path: a result phase
 *    (RQM, DIO, no EXEC: masked value C0) means the controller stopped
 *    early, as explained in the original.
 *
 * WORD fdc_pio_in(volatile UBYTE *msr, UBYTE *buf, UWORD count, WORD windows);
 * WORD fdc_pio_out(volatile UBYTE *msr, const UBYTE *buf, UWORD count, WORD windows);
 *  msr is the main status register; the data register follows it.
 *  windows is the number of 1 ms interrupt windows allowed while waiting
 *  for the first byte; after them, the wait goes on with interrupts
 *  masked. When the caller knows that the first byte cannot come before
 *  a given time (between the sector IDs of a format), this keeps
 *  interrupts away from the moment it comes.
 *  Return 0 if everything moved, 1 if the controller stopped asking
 *  early, 2 if it stopped answering.
 */

#include "asmdefs.h"

#ifdef MACHINE_MINI68K

#define MSR_READ_DATA   0xf0
#define MSR_WRITE_DATA  0xb0
#define MSR_MASK        0xe0    /* RQM, DIO, EXEC */
#define MSR_RESULT      0xc0

#define WINDOW_POLLS    249     /* polls between interrupt windows, about 1 ms */
#define QUIET_POLLS     0xffff  /* polls with interrupts masked, about 0.26 s */
#define BURST_POLLS     0xffff  /* polls for the whole sector, far beyond 16 us a byte */

/*
 * Register usage, in both functions:
 *  a0 buffer, a1 main status register, a2 data register
 *  d0 scratch (off the fast path only)
 *  d1 byte count - 1 (for dbra)
 *  d2 polls left in the current interrupt window
 *  d3 polls left for the whole sector
 *  d4 exact status of the data phase
 *  d5 caller's SR, d6 SR with interrupts masked
 *  d7 interrupt windows left
 */

        .globl  _fdc_pio_in
_fdc_pio_in:
        movem.l d2-d7/a2,-(sp)
        move.l  4*7+4(sp),a1            // main status register
        lea     1(a1),a2                // data register
        move.l  4*7+8(sp),a0            // buffer
        move.w  4*7+12(sp),d1           // count
        moveq   #0,d0
        tst.w   d1
        jeq     in_exit
        subq.w  #1,d1
        moveq   #MSR_READ_DATA-256,d4   // 0xf0 (sign extension is harmless)
        move.w  #BURST_POLLS,d3

        move.w  sr,d5
        move.w  d5,d6
        or.w    #0x0700,d6
        move.w  d6,sr                   // no interrupts, except in windows

        move.w  4*7+14(sp),d7           // interrupt windows allowed
        jra     in_window_next
in_window:
        move.w  #WINDOW_POLLS,d2
in_wait1:
        cmp.b   (a1),d4
        dbeq    d2,in_wait1             // until a byte is ready, or the window ends
        jeq     in_next
        move.w  d5,sr                   // let a pending interrupt in
        move.w  d6,sr
        move.b  (a1),d0
        and.b   #MSR_MASK,d0
        cmp.b   #MSR_RESULT,d0          // ended without data?
        jeq     in_cut
in_window_next:
        dbra    d7,in_window

        move.w  #QUIET_POLLS,d2         // windows used up: wait with interrupts masked
in_wait2:
        cmp.b   (a1),d4
        dbeq    d2,in_wait2
        jeq     in_next
        jra     in_stalled              // ended without data, or no answer

in_loop:
        cmp.b   (a1),d4
        dbeq    d3,in_loop
        jne     in_stalled
in_next:
        move.b  (a2),(a0)+
        dbra    d1,in_loop
        moveq   #0,d0                   // all of it moved
        jra     in_end

in_stalled:
        move.b  (a1),d0
        and.b   #MSR_MASK,d0
        cmp.b   #MSR_RESULT,d0
        jeq     in_cut
        moveq   #2,d0                   // stopped answering
        jra     in_end
in_cut:
        moveq   #1,d0                   // stopped asking early
in_end:
        move.w  d5,sr
in_exit:
        movem.l (sp)+,d2-d7/a2
        rts

        .globl  _fdc_pio_out
_fdc_pio_out:
        movem.l d2-d7/a2,-(sp)
        move.l  4*7+4(sp),a1            // main status register
        lea     1(a1),a2                // data register
        move.l  4*7+8(sp),a0            // buffer
        move.w  4*7+12(sp),d1           // count
        moveq   #0,d0
        tst.w   d1
        jeq     out_exit
        subq.w  #1,d1
        moveq   #MSR_WRITE_DATA-256,d4  // 0xb0
        move.w  #BURST_POLLS,d3

        move.w  sr,d5
        move.w  d5,d6
        or.w    #0x0700,d6
        move.w  d6,sr

        move.w  4*7+14(sp),d7           // interrupt windows allowed
        jra     out_window_next
out_window:
        move.w  #WINDOW_POLLS,d2
out_wait1:
        cmp.b   (a1),d4
        dbeq    d2,out_wait1
        jeq     out_next
        move.w  d5,sr
        move.w  d6,sr
        move.b  (a1),d0
        and.b   #MSR_MASK,d0
        cmp.b   #MSR_RESULT,d0
        jeq     out_cut
out_window_next:
        dbra    d7,out_window

        move.w  #QUIET_POLLS,d2         // windows used up: wait with interrupts masked
out_wait2:
        cmp.b   (a1),d4
        dbeq    d2,out_wait2
        jeq     out_next
        jra     out_stalled

out_loop:
        cmp.b   (a1),d4
        dbeq    d3,out_loop
        jne     out_stalled
out_next:
        move.b  (a0)+,(a2)
        dbra    d1,out_loop
        moveq   #0,d0
        jra     out_end

out_stalled:
        move.b  (a1),d0
        and.b   #MSR_MASK,d0
        cmp.b   #MSR_RESULT,d0
        jeq     out_cut
        moveq   #2,d0
        jra     out_end
out_cut:
        moveq   #1,d0
out_end:
        move.w  d5,sr
out_exit:
        movem.l (sp)+,d2-d7/a2
        rts

#endif /* MACHINE_MINI68K */
