#  test5.s
#
#	This program will execute in User Mode
#
#
.include "biostrap.s"
##################################################################


# the Makefile will locate this code at 0x1000, as required
	.text	/* at 0x1000 */
	.global	begin			/* entry point MUST be global */
begin:	lea	stack,%sp

	move.l	#msg1,%a1
	bsr	write

	move.l	#msg2,%a0
	clr.l	%d1			/* NUL terminator */
	move.l	#siostr,%d0
	trap	#BIOS

	move.l	#cpustop,%d0
	clr.l	%d1
	trap	#BIOS

	bra	begin		/* should never get here */

	.data
msg2:
	.asciz	"String I/O:  HELLO WORLD!\r\n"

msg1:
	.asciz	"Characters:  Hello World!\r\n"

	.text
write:				/* string to write is in A1 */
	move.b	(%a1)+,%d1
	cmp.b	#0,%d1
	bne	wr2
	rts
wr2:
	move.l	#sioput,%d0	/* SIOPUT call, D1 is the character */
	trap	#BIOS
	bra	write


	.bss
space:	.ds	1000
stack:


	.end	begin

