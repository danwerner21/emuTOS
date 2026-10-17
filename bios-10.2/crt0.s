/*  crt0.s	*/
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
.include "biostrap.s"

/*

	Runtime for standalone A.OUT files 

*/
	.text
	.even

/* Runtime execution starts here */
	.globl	begin
begin:
	pea	0.l
	pea	0.l
	pea	1.l
	jsr	main
_exit:	move.l	%d0,%d1
	move.l	#cpustop,%d0
	trap	#BIOS

	.globl	exit
exit:
	move.l	(%sp)+,%d0		/* pop the return address */
	move.l	(%sp)+,%d0		/* get the return code
	br.s	_exit
	

/* this call just brings in this module */
	.globl	__main
__main:
	rts


	.globl	_con_out
_con_out:
	move.b	4+3(%sp),%d1
	move.l	#sioput,%d0
	trap	#BIOS
	rts

	.globl	_con_in
_con_in:
	move.l	#sioget,%d0
	trap	#BIOS
	clr.l	%d0
	move.b	%d1,%d0
	rts



	.end


