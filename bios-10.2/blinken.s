/*  blinken.s  --  stuff for blinking the lights */
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


	.text

.if CPU==68030

/*  The LED flashing stuff is below */
/*  Note:
	Everything is done in registers, hence, no memory
	may be operational yet.
*/

/*
   Enter with:
	D5 is the Red LED 'on' time in tenths of a second
	Instruction Cache enabled

   Returns:
	D5 is trashed
*/

LED_on:
	move.l	(%sp)+,%a6
_LED_on:
	mulu.w	#3000,%d5
	jbra	lon0
lon2:	swap	%d5
lon1:	reset
lon0:	dbra.w	%d5,lon1
	swap	%d5
	dbra.w	%d5,lon2
	jmp	(%a6)
	

/*
   Enter with:
	D5 is the Red LED 'off' time in tenths of a second
	  Instruction Cache enabled

   Returns:
	D5 is trashed
*/

LED_off:
	move.l	(%sp)+,%a6
_LED_off:
	mulu.l	#200000,%d5
	jbra	loff0
loff2:	swap	%d5
loff1:	nop
loff0:	dbra.w	%d5,loff1
	swap	%d5
	dbra.w	%d5,loff2
	jmp	(%a6)
	

.endif

.if CPU<68010

/* same for CPU on the Mini */
/* ***EXCEPT*** the LED colors are reversed */

BL_delay = 22000
BL_stack = 0x60		/* back in the "reserved" vector area */
BL_trap  = 9		/* trap 9 is used to return to supervisor state */
BL_vector = (32+BL_trap)*4	/* trap vector location */

/*
   Enter with:
	D5 is the Green LED 'on' time in tenths of a second
	A6 is the saved stack pointer

   Returns:
	D5 is trashed
*/
_LED_on:
	and.w	#~0x2000,%sr		/* enter user mode */
	
	mulu.w	#BL_delay,%d5
	jbra	lon0
lon2:	swap	%d5
lon1:	nop
	nop
lon0:	dbra.w	%d5,lon1
	swap	%d5
	dbra.w	%d5,lon2
	
	trap	#BL_trap	/* return via trap to supervisor mode */



/*
   Enter with:
	D5 is the Green LED 'off' time in tenths of a second

   Returns:
	D5 is trashed
*/

_LED_off:
	mulu.w	#BL_delay,%d5
	jbra	loff0
loff2:	swap	%d5
loff1:	nop
	nop
loff0:	dbra.w	%d5,loff1
	swap	%d5
	dbra.w	%d5,loff2
	jmp	(%a6)

.endif


/*  Blink
	skip if (switches) bit 5 set


   Enter with:
	D0.w	blink count
	A5	return address

   Returns:
	D0 is trashed
	D5 is trashed
	A5 used for calls, hence, trashed
	A6 ditto
*/

Blink:
	move.l	(%sp)+,%a5
_Blink:
#	btst	#5,(switches).w
#	jbne	blink9			/* skip if switch set */

	jbra	blink0
blink1:
	move.l	#3,%d5			/* 0.3 sec off */
	lea	(bld1,%pc),%a6		/* JSR LED_off */
	jbra	_LED_off
bld1:	move.l	#5,%d5			/* 0.5 sec on */
	lea	(bld2,%pc),%a6
.if CPU==68030
	jbra	_LED_on
bld2:
.else
	move.l	%a6,(BL_vector)
	move.l	%sp,%a6			/* save SSP */
	move.w	#0x60,%sp		/* use reserved traps for 3 word stack */
	jbra	_LED_on
bld2: /* return via trap #9 */
	move.l	%a6,%sp			/* restore stack pointer */
.endif
	move.l	#3,%d5	      		/* 0.3 sec off */
	lea	(bld3,%pc),%a6
	jbra	_LED_off
bld3:
blink0:
	dbra.w	%d0,blink1
blink9:
	jmp	(%a5)






/*  Access the Debug board  */
.if !RETAIL

.if 0
	int lites(int val);	/* the 8-bit light value is put out */
	int switches();		/* the 8-bit value in the switches is read */
.endif


/* device codes */ 
LITES = 0xFFFFF0FF
SWITCHES = LITES

	.globl	lites
	.globl	switches

lites:	move.b	7(%sp),(LITES)		/* move from the stack to the lights */
	rts

switches:
	clr.l	%d0
	move.b	(SWITCHES),%d0		/* return as a long int */
	ext.w	%d0
	ext.l	%d0
	rts

.endif

/* end of  blinken.s  */


