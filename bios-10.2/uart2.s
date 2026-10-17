#  uart2.s
/*
	Copyright (C) 2011,2015 John R. Coffman.
	Licensed for hobbyist use only.
***********************************************************************

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    in the file COPYING in the distribution directory along with this
    program.  If not, see <http://www.gnu.org/licenses/>.

**********************************************************************/
#

.include "mfpic.s"

dev_uart	=	0x48	/* MF/PIC UART location */

rbr		=	0	/* receive buffer register */
thr		=	0	/* transmitter holding register */
ier		=	1	/* interrupt enable register */
iir		=	2	/* interrupt ident. register */
fcr		=	2	/* FIFO control register */
lcr		=	3	/* line control register */
mcr		=	4	/* modem control register */
lsr		=	5	/* line status register */
msr		=	6	/* modem status register */
scr		=	7	/* scratch register */

dll		=	0	/* divisor latch LSByte */
dlm		=	1	/* divisor latch MSByte */

lcr_8n2		=	0x03	/* 8-data bits, no parity, 2 stop bits */
lcr_dla		=	0x80	/* divisor latch access */
divisor		=	1843200/16 / 9600		/* divisor */



	.globl	_uart_find
/***********************************************************************
*  uart_find
***********************************************************************

   Enter with:
	D0.b	device code to check

   Return:
	D1 is UART type, if present
		0	none
		1	8250
		2	16450		SCR
		3	16550		SCR
		4	16550A		FIFO-16,SCR
		5	16550C		FIFO-16,AFC,SCR
		6	16750		FIFO-64,AFC,SCR
	D2 is last register examined
	D0 is last data read

	D0, A5, A6  are used

***********************************************************************
*/
_uart_find:

	or.l	#BOARD_BASE_IO,%d0		/* form word address */
	move.l	%d0,%a5			/* reference regs from here */

	clr.l	%d1			/* no uart found */
	move.l	#ier,%d2
	move.b	ier(%a5),%d0		/* IER resets to 00 */
	jbne	fnd9e

	move.l	#iir,%d2
	move.b	iir(%a5),%d0		/* IIR resets to 01 */
	cmp.b	#01,%d0
	jbne	fnd9e

	move.l	#lcr,%d2
	move.b	lcr(%a5),%d0		/* LCR resets to 00 */
	jbne	fnd9e

	move.l	#mcr,%d2
	move.b	mcr(%a5),%d0		/* MCR resets to 00 */
	jbne	fnd9e

	move.l	#lsr,%d2
	move.b	lsr(%a5),%d0		/* LCR resets to 0x60 */
#	cmp.b	#0x60,%d0		/* but sometimes to 0x00 */
 	and.b	#~0x60,%d0		/* ignore 2 bits */
	jbne	fnd9e
.if 0
# This test is failing from time to time on the MDB -- ????
# getting 0A at power-on,  00 on reset 
	move.l	#msr,%d2
	move.b	msr(%a5),%d0		/* MSR resets to 0x?0 */
	and.b	#0x0F,%d0
	jbne	fnd9e
.endif
	move.b	%d0,%d3			/* save data in D3 */

	move.b	#0xE7,fcr(%a5)		/* enable all FIFO's */
	move.b	iir(%a5),%d0		/* IIR and FCR are the same */
	btst	#6,%d0			/* test bit 6 */
	jbeq	test16450
/* we have at least a 16550  */
	move.l	#3,%d1			/* set 16550 response */
	btst	#7,%d0
	jbeq	fnd9		/* it is a 16550 */
/* we have at least a 16550A */
	move.l	#6,%d1			/* set 16750 response */
	btst	#5,%d0			/* test bit 5 */
	jbne	fnd9		/* it is a 16750 */
	move.b	#0x20,mcr(%a5)		/* set AFC */
	move.l	#4,%d1			/* say 16550A */
	btst	#5,mcr(%a5)		/* stuck on zero? */
	jbeq	fnd9		/* it is a 16550A */
	move.l	#5,%d1
	jbra	fnd9		/* it is a 16550C */
test16450:
	move.l	#1,%d1			/* say 8250 */
	move.b	#0x2A,scr(%a5)
	clr.b	mcr(%a5)		/* disturb the data bus */
	cmp.b	#0x2A,scr(%a5)
	jbne	fnd9		/* it is an 8250 */
	move.l	#2,%d1		/* it is a 16450 */
fnd9:
	move.b	%d3,%d0
fnd9e:
	move.b	#01,fcr(%a5)		/* reset */
	clr.b	mcr(%a5)		/* reset */
	jmp	(%a6)



