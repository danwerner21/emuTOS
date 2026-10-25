/*
 * mini68k2.S - RetroBrew Mini-M68k specific assembler functions
 *
 * Copyright (C) 2026 The EmuTOS development team
 *
 * This file is distributed under the GPL, version 2 or at your
 * option any later version.  See doc/license.txt for details.
 */

#include "asmdefs.h"

#ifdef MACHINE_MINI68K

        .extern _vector_5ms
        .extern _int_vbl
        .extern _mini68k_rs232_poll
        .extern _mini68k_fdc_motor_tick
        .extern _mini68k_vera_vbl
        .extern _mini68k_kbd_poll

/* NS32202 End-Of-Interrupt: read "register 32" = 0xffff8040 + 32 * 0x100 */
#define ICU_EOI 0xffffa040

/******************************************************************************/
/* Interrupts                                                                 */
/******************************************************************************/

// NS32202 counter interrupt (IR3, level 2): the 200 Hz system timer.
// It also polls the console UART, and emulates a 50 Hz VBL interrupt
// because the machine has no video hardware yet.
        .globl  _mini68k_int_timer
_mini68k_int_timer:
        movem.l d0-d1/a0-a1,-(sp)

        // Call vector_5ms. As it will return with RTE, we must setup a
        // proper stack frame. The CPU is always a 68000, so no format word.
        pea     timer_5ms_ret(pc)       // Return address
        move.w  sr,-(sp)                // SR
        move.l  _vector_5ms,a0
        jmp     (a0)                    // Call the 200 Hz system timer
timer_5ms_ret:

        jbsr    _mini68k_rs232_poll     // Drain the UART receive FIFO
        jbsr    _mini68k_kbd_poll       // PS/2 keyboard and mouse

        // Acknowledge now: the VBL work below (which includes copying part
        // of the screen to the VERA) may take a few ms, and the next timer
        // interrupt must be able to come in meanwhile.
        move.b  ICU_EOI,d0

        addq.w  #1,vbl_divider          // Every 4th tick...
        cmp.w   #4,vbl_divider
        jcs     timer_no_vbl
        clr.w   vbl_divider
        tas     vbl_busy                // ...unless the previous VBL work
        jne     timer_no_vbl            //    is still running
        move.w  #0x2100,sr              // let the timer (level 2) interrupt us
        jbsr    _int_vbl                // standard VBL handler
        jbsr    _mini68k_fdc_motor_tick // floppy motor timeout
        jbsr    _mini68k_vera_vbl       // copy part of the screen to the VERA
        clr.b   vbl_busy
timer_no_vbl:

        movem.l (sp)+,d0-d1/a0-a1
        rte

// Any other NS32202 interrupt: acknowledge and ignore it.
        .globl  _mini68k_int_ignore
_mini68k_int_ignore:
        tst.b   ICU_EOI                 // Acknowledge the interrupt
        rte

/******************************************************************************/
/* BSS                                                                        */
/******************************************************************************/

        .bss
        .even

vbl_divider:
        .ds.w   1
vbl_busy:
        .ds.b   1               /* set by TAS while the VBL work runs */

#endif /* MACHINE_MINI68K */
