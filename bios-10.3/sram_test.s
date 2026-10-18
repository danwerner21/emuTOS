/*  sram_test.s  */
/*
	Copyright (C) 2016 John R. Coffman.
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


/* This code is expected to execute in-line rather than being called */

/*  Error messages are output through the RUN/HALT KISS LEDs.

	7 blinks	data path to SRAM is corrupt
	6 blinks	ditto, by a second test
	5 blinks	failure of some one bit in SRAM

*/



.if CPU==68030
.include  "cache_def.s"

	move.l	#CACR_DIAG,%d0		/* enable instruction cache */
	movec	%d0,%cacr		/* clear & disable data cache */

SRAM_START =  0xFFFE0000
SRAM_SIZE  =  32*1024
SRAM_END1  =  SRAM_START + SRAM_SIZE

INIT_ISP   =  SRAM_END1
INIT_MSP   =  INIT_ISP - 2048

PATTERN_SRAM =	0x81020410


	lea	(SRAM_START),%a0
	move.l	#ERR_SRAM_DATA_PATH_1,%d0			/* possible error code 7 */
/* first test the data path to SRAM */
	move.l	#8-1,%d1		/* count 8 loop iterations */
	move.l	#1,%d2			/* pattern = 0b00000001 */
srt0:	move.b	%d2,(%a0)
	cmp.b	(%a0),%d2
	bne.s	error_stop			/* error if comparison fails */
	rol.b	#1,%d2		
	dbra	%d1,srt0

/* second test of the data path to SRAM */
PATT1	=	0x01041040
PATT2	=	0x80200802

	move.l	#PATT1,%d1
	move.l	#PATT2,%d2
	move.l	#ERR_SRAM_DATA_PATH_2,%d0			/* possible error code 6 */

	move.l	%d1,(%a0)+		/* store the long */
	move.l	%d2,(%a0)		/* store second long */
	sub.l	(%a0),%d2		/* result should be zero */
	sub.w	-(%a0),%d1		/* result should be zero */
	swap	%d1
	sub.w	-(%a0),%d1
	or.l	%d2,%d1			/* both longs should be zero */
	bne.s	error_stop

/* now test every bit in SRAM */	
	lea	(SRAM_START),%a1	/* lowest address */
	lea	(SRAM_END1),%a0		/* highest address + 1 */
	clr.l	%d6			/* count errors */
	clr.l	%d3			/* X-bit in pattern */
	move.l	#PATTERN_SRAM,%d4
	move.l	#9-1,%d5
	lea	(srt3,%pc),%a6
	move.l	reset_code,%a5		/* one piece of SRAM to preserve */
srt_loop:
	jmp	_memtest3
srt3:
	dbra	%d5,srt_loop

	move.l	%a5,reset_code		/* restore the reset code */
	move.l	#ERR_SRAM_BIT_TEST,%d0
	tst.l	%d6
	bne.s	error_stop		/* if any errors, SRAM is no good */






/* end of tests, just continue through */
	bra.s	srt_continue



/* put out the error code in D0 */
error_stop:
	move.l	#20,%d5
	lea	(srt0err1),%a6
	bra	_LED_off
srt0err1:
	lea	(srt0stop),%a5	/* return address */
      
/* blink 7 times, then wait; then stop */
	bra	_Blink
srt0stop:
        move.l  #30,%d5		/* wait 3 seconds after blink code */
	lea	(stop0),%a6	/* stop after delay */
	bra	_LED_off


/* set up the stack pointers for now */

srt_continue:
	move.l	#INIT_ISP,%d3
	movec.l	%d3,%isp
	move.l	#INIT_MSP,%d4	/* set MSP */
	movec.l	%d4,%msp
	and.w	#~0x1000,%sr	/* select ISP */
.endif

/* end of sram_test.s */

