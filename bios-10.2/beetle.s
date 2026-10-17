/* beetle.s --	assembly language interface for the debugger  */
/*
	Copyright (C) 2011,2012 John R. Coffman.
	Licensed for hobbyist use on the N8VEM baby M68k CPU board.
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

	.globl	state
	.globl	breakpoint
	.globl	Trace
	.globl	Go

	.bss
/* array that holds the machine state; see 'debug.h' */
state:
s_d:	.ds.l	8	/* 8 data registers */
s_a:	.ds.l	7	/* 7 address registers */
s_ssp:	.ds.l	1	/* s_a[7] is the SSP (MSP) */
s_usp:	.ds.l	1	/* the User Stack Pointer, USP */
s_pc:	.ds.l	1	/* program counter (next instruction) */
s_frame: .ds.w	1	/* stack frame type (should be zero) */
s_sr:	.ds.w	1	/* SR -- status register (full) */
.if CPU>68010
s_isp:	.ds.l	1	/* ISP for the debugger */
s_msp:	.ds.l	1	/* MSP explicitly */
.endif


trace_count:		/* was popped to D0 */
trace_save:
	.ds.l	15	/* 8 data + 7 address registers */
t_ssp:	.ds.l	1	/* SSP for debugger */
	

TRACE_BIT	=	0x8000	/* T1 bit on 68020 */
TRACE_MASK	=	0xC000	/* masks T1/T0 bits on 68020 */
SUPV_BIT	=	0x2000
IPL_BITS	=	0x0700

X_BIT		=	0b10000
N_BIT		=	0b01000
Z_BIT		=	0b00100
V_BIT		=	0b00010
C_BIT		=	0b00001

	.text
Trace:
	or.w	#TRACE_BIT,s_sr		/* set Trace (T1) bit */
	move.l	#trace_trap,4*9		/* set to receive trap */
Go:
	move.l	#breakpoint_trap,4*4	/* set to receive breakpoint trap */

	jsr	install_breaks		/* install all breakpoints */

	move.l	(%sp)+,%a0		/* save return in A0 */
	move.l	(%sp)+,%d0		/* get trace count in D0 */
 /* the trace_count is in D0, and will be the function return */
	movem.l	%d0-%d7/%a0-%a7,trace_save	/* save all regs */

dispatch_user:
	move.w	s_frame,%d0		/* see if the frame is valid */
	bmi.s	du0

/* frame is valid, restore the stack pointers */
.if 0 /*CPU>68010*/
	move.l	s_msp,%d1		/* explicit restore of MSP */
	movec	%d1,%msp
	move.l	s_isp,%d1		/* explicit restore of ISP */
	movec	%d1,%isp
.endif
	move.l	s_ssp,%sp		/* set SSP */
	br.s	du1
du0:
	move.l	#0,%d0			/* frame was not created by trap or breakpoint */
/* continue the state restore */
du1:
	move.l	s_usp,%a1		/* set User USP */
	move.l	%a1,%usp		/* */

/* create the RTE frame */
.if CPU>=68010
	move.w	%d0,-(%sp)		/* RTE frame type */
.endif
	move.l	s_pc,-(%sp)		/* push User resume PC */
	move.w	s_sr,-(%sp)
	movem.l	state,%d0-%d7/%a0-%a6	/* restore User register state */
	rte		  		/* resume User program */



trace_trap:
	sub.l	#1,trace_count		/* count the instruction */
	beq.s	trace_done
	rte				/* count not expired */

breakpoint_trap:
	move.b	#1,break_taken		/* flag breakpoint */
	bra.s	common_reentry

trace_done:
	clr.b	break_taken		/* flag no breakpoint */
common_reentry:
	movem.l	%d0-%d7/%a0-%a6,state	/* save all registers */
	move.w	(%sp)+,%d0		/* grab the SR */
	and.w	#~TRACE_MASK,%d0	/* clear the T1/T0 bits */
	move.w	%d0,s_sr		/* save the program status */
	move.l	(%sp)+,s_pc		/* save the User resume point */
.if CPU>=68010
	move.w	(%sp)+,s_frame		/* save interrupt frame word */
.else
	clr.w	s_frame			/* or mark as valid so SSP is restored */
.endif
	move.l	%sp,s_ssp		/* save user SSP (ISP) */
.if CPU>68010
	movec	%isp,%d0		/* save the ISP */
	move.l	%d0,s_isp
	movec	%msp,%d0		/* save the MSP */
	move.l	%d0,s_msp
.endif
	move.l	%usp,%a1		/* save USP */
	move.l	%a1,s_usp

	movem.l	trace_save,%d0-%d7/%a0-%a7	/* restore Trace call state */
	sub.l	#4,%sp			/* push the count argument */
	move.l	%a0,-(%sp)		/* push the return address */

	jsr	remove_breaks

	rts


	.end


