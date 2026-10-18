#  n8iox.s
#	Support routines for 'n8io.c'
#
/**********************************************************************
	Copyright (C) 2012 John R. Coffman.
	Licensed for hobbyist use on the N8VEM mini-M68000 CPU board.
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
.include "biostrap.s"
#######################################################################

	.globl	_read_sector	/* (drive, lba, memaddr) */
	.globl	_write_sector	/* (drive, lba, memaddr) */
	.globl	_disk_reset	/* (drive) */
	.globl	_disk_info	/* (drive, memaddr) IDE disks only */
.if 0
	.globl	_halloc		/* high memory allocation */
	.globl	_get_hma	/* compatibility call */
	.globl	heap		/* ULONG pointer to end of BSS */

	.data
	.globl	_end
heap:	.long	_end
.endif
	.globl	bswap
	.globl	wswap

	.text

_read_sector:
	link	%a6,#0
	movem.l	%d2-%d3,-(%sp)
	move.l	8(%a6),%d1	/* drive */
	move.l	12(%a6),%d2	/* lba */
	move.l	#1,%d3		/* sector count = 1 */
	move.l	16(%a6),%a0	/* memory address */
	move.l	#disk_read,%d0	/* function code */
	trap	#bios
	movem.l	(%sp)+,%d2-%d3
	unlk	%a6
	rts

_write_sector:
	link	%a6,#0
	movem.l	%d2-%d3,-(%sp)
	move.l	8(%a6),%d1	/* drive */
	move.l	12(%a6),%d2	/* lba */
	move.l	#1,%d3		/* sector count = 1 */
	move.l	16(%a6),%a0	/* memory address */
	move.l	#disk_write,%d0	/* function code */
	trap	#bios
	movem.l	(%sp)+,%d2-%d3
	unlk	%a6
	rts

_disk_reset:
	link	%a6,#0
	move.l	8(%a6),%d1	/* drive */
	move.l	#disk_reset,%d0	/* function code */
	trap	#bios
	unlk	%a6
	rts

_disk_info:
	link	%a6,#0
	move.l	8(%a6),%d1	/* drive */
	move.l	12(%a6),%a0	/* memory address */
	move.l	#disk_info,%d0	/* function code */
	trap	#bios
	unlk	%a6
	rts

# Swap all the bytes in a long

bswap:
lswap:
	move.l	4(%sp),%d0
	ror.w	#8,%d0
	swap	%d0
	ror.w	#8,%d0
	rts

# Swap the bytes in a short
wswap:
	move.w	4+2(%sp),%d0
	ror.w	#8,%d0
	rts

.if 0
_get_hma:
	clr.l	%d1
	br.s	hma_call
_halloc:
	move.l	4(%sp),%d1
hma_call:
	move.l	#hma_alloc,%d0
	trap	#bios
	rts
.endif

	.end

