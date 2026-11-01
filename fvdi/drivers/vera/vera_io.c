/*
 * VERA port access for the fVDI driver.
 *
 * Copyright (C) 2026 Dan Werner
 *
 * This software is licensed under the GNU General Public License.
 * Please, see LICENSE.TXT for further information.
 */

#include "vera.h"
#include "driver.h"

/* EmuTOS's busy flag (from the 'VERA' cookie), or our own if there is no
 * cookie. While it is non-zero, EmuTOS's VBL and the mouse routine leave
 * the VERA ports alone. */
static volatile uint8_t own_busy;
volatile uint8_t *vera_busy = &own_busy;

uint32_t row_dst[ROW_LONGS];
uint32_t row_out[ROW_LONGS];

void v_begin(void)
{
    (*vera_busy)++;
    VREG(V_CTRL) = 0;           /* ADDRSEL = 0: ADDR0, for reads */
}

void v_end(void)
{
    if (--(*vera_busy) == 0)
        mouse_apply_pending();  /* a pointer move that came in meanwhile */
}

/*
 * The runs below carry all the bytes of the bigger drawing calls, so they
 * are in assembler. Arguments are all longs, on the stack; d0-d1/a0-a1
 * are free to use, as in gcc's calling convention.
 *
 * v_read_run(dst, addr, count): read count bytes from VRAM. The VERA's
 * low address byte is written before each read (on this card, reads do
 * not advance the address); the middle byte and the bank bit when the
 * run crosses into the next 256-byte page.
 */
__asm__(
    "    .text\n"
    "    .even\n"
    "    .globl  _v_read_run\n"
    "_v_read_run:\n"
    "    movem.l %d2-%d4/%a2,-(%sp)\n"
    "    move.l  20(%sp),%a0\n"             /* dst */
    "    move.l  24(%sp),%d0\n"             /* addr: low byte in d0.b */
    "    move.l  28(%sp),%d1\n"             /* count */
    "    beq.s   9f\n"
    "    lea     0xffff8080,%a1\n"          /* ADDR_L; ADDR_M, ADDR_H follow */
    "    lea     3(%a1),%a2\n"              /* DATA0 */
    "    move.l  %d0,%d2\n"
    "    swap    %d2\n"
    "    and.b   #1,%d2\n"
    "    move.b  %d2,2(%a1)\n"              /* bank, no increment */
    "    move.w  %d0,%d3\n"
    "    lsr.w   #8,%d3\n"
    "    move.b  %d3,1(%a1)\n"              /* middle byte */
    "1:  moveq   #0,%d4\n"                  /* bytes to the end of the page */
    "    move.b  %d0,%d4\n"
    "    neg.w   %d4\n"
    "    add.w   #256,%d4\n"
    "    cmp.l   %d1,%d4\n"
    "    bls.s   2f\n"
    "    move.w  %d1,%d4\n"
    "2:  sub.l   %d4,%d1\n"
    "    subq.w  #1,%d4\n"
    "3:  move.b  %d0,(%a1)\n"
    "    move.b  (%a2),(%a0)+\n"
    "    addq.b  #1,%d0\n"
    "    dbra    %d4,3b\n"
    "    tst.l   %d1\n"
    "    beq.s   9f\n"
    "    addq.b  #1,%d3\n"                  /* next page */
    "    bne.s   4f\n"
    "    addq.b  #1,%d2\n"                  /* next bank */
    "    move.b  %d2,2(%a1)\n"
    "4:  move.b  %d3,1(%a1)\n"
    "    bra.s   1b\n"
    "9:  movem.l (%sp)+,%d2-%d4/%a2\n"
    "    rts\n"
);

/*
 * v_write_run(src, count): write count bytes at the DATA1 address, set
 * by v_set_write(). v_fill_run(value, count): count copies of value.
 * Both 16 bytes to a loop.
 */
#define REP16(s)    s s s s s s s s s s s s s s s s
__asm__(
    "    .text\n"
    "    .even\n"
    "    .globl  _v_write_run\n"
    "_v_write_run:\n"
    "    move.l  4(%sp),%a0\n"
    "    move.l  8(%sp),%d0\n"
    "    lea     0xffff8084,%a1\n"          /* DATA1 */
    "    move.l  %d0,%d1\n"
    "    lsr.l   #4,%d1\n"
    "    and.w   #15,%d0\n"
    "    bra.s   2f\n"
    "1:\n"
    REP16("    move.b  (%a0)+,(%a1)\n")
    "2:  subq.l  #1,%d1\n"
    "    bcc.s   1b\n"
    "    bra.s   4f\n"
    "3:  move.b  (%a0)+,(%a1)\n"
    "4:  dbra    %d0,3b\n"
    "    rts\n"
    "\n"
    "    .globl  _v_fill_run\n"
    "_v_fill_run:\n"
    "    move.l  4(%sp),%d0\n"              /* value in d0.b */
    "    move.l  8(%sp),%d1\n"
    "    lea     0xffff8084,%a1\n"          /* DATA1 */
    "    move.l  %d1,%a0\n"                 /* the remainder, for later */
    "    lsr.l   #4,%d1\n"
    "    bra.s   2f\n"
    "1:\n"
    REP16("    move.b  %d0,(%a1)\n")
    "2:  subq.l  #1,%d1\n"
    "    bcc.s   1b\n"
    "    move.w  %a0,%d1\n"
    "    and.w   #15,%d1\n"
    "    bra.s   4f\n"
    "3:  move.b  %d0,(%a1)\n"
    "4:  dbra    %d1,3b\n"
    "    rts\n"
);
