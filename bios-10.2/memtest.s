#  memtest.s
/*
	Copyright (C) 2011,2016 John R. Coffman.
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
#
#maxaddr		=	2*1024*1024
maxchip		=	32*1024
#maxcount	=	maxaddr/maxchip
chiplong	=	maxchip/4

/*
Memory test for the MINI-M68k CPU/memory board

   Enter with:
	A0 is the highest address to test + 1
	A6 is the return address
	D5 is the save of the reset_code

   Returns:
   	D5 is unchanged
	D6 is the compare failure count (>0 is okay)
	A4 is the lowest address tested (should be 0)
	A5 is the highest address okay + 1

*/

	.globl	_memtest
	
_memtest:

	clr.l	%d6

	move.l	%a0,%d2
/* assume that maxchip is 32k */
	lsr.l	#8,%d2
	lsr.l	#7,%d2		/* D2 >> 15 is count of 32K regions to test */
	sub.w	#1,%d2

	beq.s	l0
	sub.w	#1,%d2
l0:

	move.l	%a0,%a5
	move.l	#0x12EDB748,%d4

l1:
	move.w	#chiplong-1,%d3
	move.l	%a0,%a1

#	move.l	%a1,%d0
#	bsr	lout

# fill loop
l12:
	move.l	%d4,-(%a1)
	dbra.w	%d3,l12

	move.w	#chiplong-1,%d3
	move.l	%a0,%a1
# compare loop
l13:
	cmp.l	-(%a1),%d4

	dbne.w	%d3,l13
	beq.s	l19
	move.l	%a1,%a5
	add.l	#1,%d6

	lea.l	-maxchip+4(%a1),%a1
l16:
	cmp.l	(%a1)+,%d4
	dbne.w	%d3,l16
	beq.s	l19
	lea.l	-4(%a1),%a5
	add.l	#1,%d6
l19:

	lea.l	-maxchip(%a0),%a0
   	dbra.w	%d2,l1
	
	move.l	%a0,%a4
/* return A5 = highest address + 1
	  A4 = lowest address tested	*/

	jmp	(%a6)



#################################################



