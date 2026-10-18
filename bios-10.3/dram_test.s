/*  dram_test.s  */
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

/* this code executes in-line, rather than being called */

.if CPU==68030


.if 1
	move.l	#CACR_DIAG,%d6		/* enable instruction cache */
	movec	%d6,%cacr

	move.l	#2,%d5			/* 0.2 seconds */
	lea	sttd1,%a6
	jbra	_LED_off
sttd1:
#	reset

	move.l	#1,%d0
	lea	sttd2,%a5
	jbra	_Blink			/* 1 blinks before DRAM init */
sttd2:

#	move.l	#CACR_DIS,%d6		/* disable instruction cache */
#	movec	%d6,%cacr
.endif






/* prime the DRAM by doing 8 refreshes of each location */
NREFRESH = 8

/* Enter with D0 == memmax (64Mb or 256Mb) */
	lea	(0),%a0			/* start at address 0x00000000 */
	lsr.l	#2,%d0			/* divide by 4 */
	move.l	%d0,%a1			/* address increment */

	move.l	#4-1,%d1		/* 4 interations:  0M, 16M, 32M, 48M */
					/*          or:  0M, 64M, 128M, 192M */
drt0:
	move.l	#NREFRESH*4096 - 1,%d2
	move	%a0,%a2			/* A2 is the working register */
drt1:	move.l	(%a2)+,%d3		/* just do a read */
	dbra	%d2,drt1

	adda	%a1,%a0			/* new start address */
	dbra	%d1,drt0

	move	%a0,%a1			/* increment is now 64Mb, same as start address */

	move.l	#3-1,%d1		/* 3 more iterations:  64M, 128M, & 192M */
drt2:
	move.l	#NREFRESH*4096 - 1,%d2
	move	%a0,%a2			/* A2 is the working register */
drt3:	move.l	(%a2)+,%d3		/* just do a read */
	dbra	%d2,drt3

	adda	%a1,%a0			/* new start address */
	dbra	%d1,drt2

.endif   /* CPU==68030 */

