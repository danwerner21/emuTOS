/*  memtest3.s   */
/*
	Copyright (C) 2016 John R Coffman.
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
	.text

	.globl	crlf, space
	.globl	woutD, lout, sio_put, put_string



TEST_PATTERN0	=	0x12EDB748 /* X=1 */
TEST_PATTERN1	=	0x63C1C783 /* X=1 */
TEST_PATTERN2	=	0xB38F0F83 /* X=1 */
TEST_PATTERN3	=	0x0635F570 /* X=1 */
PATTERN_SRAM	=	0x81020410 /* X=0 */
XOR_PATTERN	=	0x965AC279	/* used to randomize testing patterns */



/*
   memtest0:
   	Initializes D3, D4, D6 and falls into memtest3:   
   	
   	
   	
   	
   memtest3:
	
   Enter with:
   	D3.b  is the saved X flag; must be 0x00 or 0xFFFF
   	D4 is the LONG pattern used for the test
   	D6 is the cumulative failure count

	A0 is the highest address to test + 1
	A1 is the lowest address to test
	A6 is the return address

   Returns:
	D6 is the cumulative failure count
	    If counting from 0, then the caller must initialize D6
	D3.b is the saved X flag
	D4 is the UPDATED pattern
	
   Uses:
   	A2 is the working address register
   	A3 to save D3
   	A4 to save D4
	A6 used for the return address

   Preserves:
   	D0
   	D5
	D7
	A0
	A1
	A5
	SP
*/

	.globl	_memtest3
	.globl	_memtest0

memtest0:
	move.l	(%sp)+,%a6	/* get the return address */
_memtest0:	/* start the error count at 0 */
	clr.l	%d6		/* start a new count from zero */
	move.l	#TEST_PATTERN1,%d4
	move.l	#-1,%d3		/* X-flag is set */
	jbra	_memtest3
	
memtest3:
	move.l	(%sp)+,%a6	/* get the return address */
_memtest3:			/* entry to use no stack  */
	move.l	%a0,%d2
	sub.l	%a1,%d2		/* D2 is byte count to test */
	
	move.l	%d2,%d1		/* D1 does the counting; D2 is saved */
	move.l	%a1,%a2		/* A2 is the start address */
	
	lsr.l	#2,%d1		/* D1 is the LONG count */
	move.l	%d3,%a3		/* save X flag */
	move.l	%d4,%a4		/* save pattern */
	
	add.b	%d3,%d3		/* restore the X flag */
	br.s	mt_start3	/* start the counting */
mt_loop1:
	swap	%d1
mt_loop2:
	roxl.l	#1,%d4
	move.l	%d4,(%a2)+
mt_start3:
	dbra	%d1,mt_loop2
	swap	%d1
	dbra	%d1,mt_loop1

/* now the compare loop */
	move.l	%a4,%d4		/* original pattern */
	move.l	%a3,%d3		/* original X flag */

	move.l	%a1,%a2		/* original start address */
	move.l	%d2,%d1		/* original byte count */
	
	lsr.l	#2,%d1		/* ulterior motives for doing this shift here */
	br.s	mt_start4	/* start the count */
	
/* handle counting errors here */
mt_error1:
	subx.b	%d3,%d3		/* save the X-flag */
	add.l	#1,%d6		/* count the error */
mt_start4:
	add.b	%d3,%d3		/* restore the X-flag */
	or	#4,%ccr		/* set the Z flag */
	br.s	mt_start5	/* re-enter the loop */
	
mt_loop3:
	swap	%d1
mt_loop4:
	roxl.l	#1,%d4
	cmp.l	(%a2)+,%d4	/* compare memory to pattern */
				/* compare does not touch the X-flag */
mt_start5:
	dbne	%d1,mt_loop4	/* inner loop */
	jbne	mt_error1	/* jump on compare error */
/* no error occurred on the last iteration */
	swap	%d1
	dbra	%d1,mt_loop3	/* outer loop */

	subx.b	%d3,%d3		/* save the X-flag */
/* the error count is updated */
	jmp	(%a6)		/* return to caller */
	



/************************************************************************/
/*   below this point we may use the SRAM stack		*/
/************************************************************************/
.if !RETAIL
DEBUG = 0
.else
DEBUG = 0
.endif

/*
   DRAM_tests:
   	not called; this test is jumped to; it never terminates
   	until RESET is hit
   	
   	
   Enter with:
   	memmax	is set
   	h_m_a	is set
   
   Register usage:
   	A5 is the test table pointer
   	D5 low half is pass counter (PASS)
   	   high half is error pass (EPASS)
   	D7 low half is passes without error counter
   	   high half is high word of HMA
   	
   	
   
*/
	.globl	DRAM_tests
DRAM_tests:
.if DEBUG>1
	lea	debug000,%a0
	jbsr	put_string
	move.w	debug,%d0
	jbsr	wout
	jbsr	space
	jbsr	space
	jbsr	space
	move.l	%sp,%d0
	jbsr	lout
	jbsr	crlf
	jbra	debug001
debug000:  .asciz	"\r\n\nDebug = "
debug001:
.endif
	clr.l	%d7			/* test no memory */
	move.l	#3,%d6			/* test the banks of DRAM */
	move.l	memmax,%d2		/* max memory from the bus error test */
	lsr.l	#2,%d2		/* bank size is 1/4 memmax */
.if DEBUG
	move.l	%d2,%d0		/* print out size of one memory bank */
	jbsr	lout
	jbsr	crlf
	nop
.endif
ds0:
	move.l	%d2,%d1
	swap	%d1
	mulu.w	%d6,%d1
	swap	%d1
	move.l	%d1,%a1
	clr.l	(%a1)			/* set location to zero */
	move.l	#TEST_PATTERN2,4(%a1)
	nop
.if DEBUG
	move.l	(%a1),%d0
	jbsr	lout
	jbsr	crlf
	nop
.endif
	move.l	(%a1),%d0
	jbne	ds9
	add.l	%d2,%d7
	bset	%d6,%d7
ds9:
	dbra	%d6,ds0			/* loop through 4 memory banks */

#	or.b	#1,%d7			/* must have Bank 0 */
.if DEBUG
	jbsr	crlf
	move.l	%d7,%d0
	jbsr	lout
	jbsr	space
	move.l	h_m_a,%d0
	jbsr	lout
	jbsr	crlf
.endif
	
	
	clr.w	%d7		/* zap those low bits */

.if DEBUG>2
/*debug*/ sub.l	#1,%d7 
.endif
	
	move.l	h_m_a,%d1	/* compare HMA to D7 -- they should be equal */
	cmp.l	%d1,%d7
	jbeq	ds12

	jbsr	crlf
	move.l	%d1,%d0
	jbsr	lout		/* HMA1 */
	lea	err_hma,%a0
	jbsr	put_string
	move.l	%d7,%d0
	jbsr	lout
	
	cmp.l	%d1,%d7
	jbge	ds11
	move.l	%d1,%d7
ds11:
	lea	hma2,%a0
	jbsr	put_string
	move.l	%d7,%d0
	jbsr	lout
	jbsr	crlf

ds12:
	lea	heading,%a0
	jbsr	put_string
	
	clr.l	%d5		/* EPASS = 0, PASS = 0 */
	clr.w	%d7		/* passes without error = 0 */


	move.l	#TEST_PATTERN3,%d4	/* pattern */
	move.l	#-1,%d3		/* X-flag */
	jbra	dt00

/* start the major outer loop */
dt0:
	add.w	#1,%d7		/* count passes without error */
	
	lea.l	(str2,%pc),%a0	/* "Pass #    " */
	jbsr	put_string
	move.w	%d5,%d0
	jbsr	woutD		/* print the pass number */
	lea.l	(str3,%pc),%a0	/* "Passes without error:  #" */
	jbsr	put_string
	move.w	%d7,%d0
	jbsr	woutD
	lea.l	(str4,%pc),%a0	/* "Last error at pass:  #" */
	jbsr	put_string
	move.l	%d5,%d0
	swap	%d0		/* D0.w is last error location */
	jbsr	woutD
	jbsr	crlf
dt00:
	jbsr	crlf
	lea	(dram,%pc),%a5			/* get table address */
	add.w	#1,%d5			/* increment the pass counter */
# 	move.b	#0x12,(lites).w

/* start a new test from the table entry */
dt1:
	cmp.l	#-1,(%a5)
	jbeq	dt0			/* done if we hit 0xFFFFFFFF */
		
	move.l	(%a5)+,%a1		/* get start address */
.if CPU<68020
	move.w	%a1,%d0
	and.b	#1,%d0			/* check 68000 word alignment */
	jbne	dt6			/* test must be word aligned */
.endif	
	move.l	%d7,%d0
	clr.w	%d0			/* D0 is HMA (low bits zeroed) */
	cmp.l	%d0,%a1			/* A1::hma */
	jbge	dt6			/* A1 < hma */
	move.l	(%a5),%a0		/* end address + 1 to A0 */
	cmp.l	%d0,%a0			/* end+1::hma */
	jbgt	dt6	
	
dt2:
.if 1 /* !RETAIL */
	move.l	%d4,%d0			/* show the pattern */
	jbsr	lout
	jbsr	space
	move.l	#1,%d0
	and.b	%d3,%d0
	jbsr	woutD
	jbsr	space
	jbsr	space
.endif
	move.l	%a1,%d0
	jbsr	lout			/* put out Address */
	jbsr	space
	move.l	%a0,%d0
	jbsr	lout
	jbsr	space
/* put out A or U depending on D1 */
	move.w	%a0,%d1			/* do the test in D1 */
	move.b	#0x41,%d0		/* "A" */
	and.b	#3,%d1
	jbeq	dt20
	move.b	#0x55,%d0		/* "U" */
dt20:	jbsr	sio_put


dt3:
	clr.l	%d6
	jbsr	memtest3
# 	move.b	#0x17,(lites).w

	eor.l	#XOR_PATTERN,%d4	/* avoid the power of 2 problem */	
	jbsr	passfail

	move.l	%d6,%d6			/* test error count */
	jbne	dt5
# error count was zero, so do the byte test
	lea.l	(strB,%pc),%a0
	jbsr	put_string
	
	move.l	-4(%a5),%a1		/* get address to test */
	jbsr	bytetest

	jbsr	passfail
# 	move.b	#0x18,(lites).w

dt5:
	jbsr	crlf
dt6:
	lea	8(%a5),%a5	
	jbra	dt1


.if 0
drok5:
	and.b	#0x0F,%d7
	jbne	dt1			/* skip test if error above */
	move	%a4,%a1

	jbsr	bytetest

	move.l	%d6,%d6
	jbeq	drok9

#      	move.b	%d6,(lites).w

	move.b	(switches).w,%d0
	btst	#7,%d0			/* test HOE setting */
	jbne	stop0

drok9:
	move.l	#3,%d0
	jbsr	Blink
	jbra	dt1
.endif


/* say pass or fail based on D6 */
passfail:
	movm.l	%a0/%a1,-(%sp)
	lea	(str5pass,%pc),%a0
	move.l	%d6,%d6
	jbeq	pf2
	move.w	#-1,%d7			/* reset pass counter */
###	move.l	(PASS).l,(EPASS).l	/* mark the error pass */
	move.w	%d5,%d0
	swap	%d5
	move.w	%d0,%d5
	swap	%d5

	lea	(str5fail,%pc),%a0
pf2:	jbsr	put_string
	movm.l	(%sp)+,%a0/%a1
	rts


/*  message strings:		*/
.if 0
str0:	.ascii	"\r\nSRAM present\r\n\0"
str1:	.ascii	"SRAM Btest\0"
.endif
str5pass:  .asciz  " pass"
str5fail:  .asciz  " fail"
str2:	.asciz	"\r\nPass:  "
str3:	.asciz	"     Passes without error:  "
str4:	.asciz	"     Last error at pass:  "
strB:	.asciz	"   B"
err_hma: .asciz	" <--HMA1 unequal to HMA2--> "
hma2:	.asciz	"\r\nUsing HMA = "

heading:
	.ascii	"\r\n\n"
	.ascii	"The memory tests use a 33-bit rotating bit pattern; i.e., each successive\r\n"
	.ascii	"memory word32 is written with a pattern rotated left one bit from the previous.\r\n"
	.ascii	"The 33-bit length is used to pick up shorted or open address traces.  The seed\r\n"
	.ascii	"value for each of the test lines is shown on the left, long+Xbit.\r\n"
	.ascii	"\r\n\n"
	.ascii	" 33-Bit         Address       Aligned or\r\n"
	.asciz	"Pattern+X    Start    End+1   Unaligned\r\n"

.if 0
str5:	.ascii	"\r\nMF/PIC UART is\0"
	.align	4
strU:
	.ascii	" ???   \0"	/* 0 */
	.ascii	" 8250  \0"	/* 1 */
	.ascii	" 16450 \0"	/* 2 */
	.ascii	" 16550 \0"
	.ascii	" 16550A\0"	/* 4 */
	.ascii	" 16550C\0"
	.ascii	" 16750 \0"	/* 6 */
.endif

	.bss
#	.comm	PASS,4,4
#	.comm	EPASS,4,4
.if !RETAIL
	.comm	debug,2,2
.endif	
	
	
	.text
	.align 4
dram:
.if CPU<68020
	.long	0x00000000
	.long	0x00008000	/* lowest 32K */
	.long	1

	.long	0x00008000
	.long	0x00080000	/* to 512k */
	.long	2
	
	.long	0x00000002	/* unaligned */
	.long	0x0007fffe
	.long	3
	
	.long	0x00080000	/* second 512K */
	.long	0x00100000
	.long	4
	
	.long	0x00070002
	.long	0x000BFFFE
	.long	5
	
	.long	0x00100000	/* third 512K */
	.long	0x00180000
	.long	6
	
	.long	0x00180000
	.long	0x00200000
	.long	7
	
	.long	0x0017002E
	.long	0x001C1002
	.long	8
	
	.long	2
	.long	0x001ffffe
	.long	9
.else		
	

dram16:
	.long	0x00000000		/* lowest 64K */
	.long	0x00010000
	.long	00
	
	.long	0x00010000
	.long	0x01000000		/* 16 meg */
	.long	10			/* display */

	.long	0x00000000+2
	.long	0x01000000-2		/* 16 meg */
	.long	10			/* display */

	.long	0x00000000+1
	.long	0x01000000-3		/* 16 meg */
	.long	10			/* display */

	.long	0x00000000+3
	.long	0x01000000-1		/* 16 meg */
	.long	10			/* display */

	.long	0x01000000
	.long	0x02000000
	.long	11
	
	.long	0x01000000-254
	.long	0x02000000-254
	.long	11
	
	.long	0x01000000-255
	.long	0x02000000-255
	.long	11
	
	.long	0x01000000-253
	.long	0x02000000-253
	.long	11
	
	.long	0x02000000
	.long	0x03000000
	.long	12
	
	.long	0x02000000-254
	.long	0x03000000-254
	.long	12
	
	.long	0x02000000-255
	.long	0x03000000-255
	.long	12
	
	.long	0x02000000-253
	.long	0x03000000-253
	.long	12
	
	.long	0x03000000
	.long	0x04000000		/* now at 64Mb */
	.long	13
	
	.long	0x03000000-254
	.long	0x04000000-254		/* now at 64Mb */
	.long	13
	
	.long	0x03000000-255
	.long	0x04000000-255		/* now at 64Mb */
	.long	13
	
	.long	0x03000000-253
	.long	0x04000000-253		/* now at 64Mb */
	.long	13
	
	.long	0x04000000
	.long	0x08000000
	.long	14
	
	.long	0x04000000-253
	.long	0x08000000-253
	.long	14
	
	.long	0x04000000-254
	.long	0x08000000-254
	.long	14
	
	.long	0x04000000-255
	.long	0x08000000-255
	.long	14
	
	.long	0x08000000
	.long	0x0C000000
	.long	15
	
	.long	0x08000000-253
	.long	0x0C000000-253
	.long	15
	
	.long	0x08000000-254
	.long	0x0C000000-254
	.long	15
	
	.long	0x08000000-255
	.long	0x0C000000-255
	.long	15
	
	.long	0x0C000000
	.long	0x10000000		/* full 256Mb */
	.long	16

	.long	0x0C000000-253
	.long	0x10000000-253		/* full 256Mb */
	.long	16

	.long	0x0C000000-254
	.long	0x10000000-254		/* full 256Mb */
	.long	16

	.long	0x0C000000-255
	.long	0x10000000-255		/* full 256Mb */
	.long	16


.endif	/* if 0 */

	.long	-1			/* end marker */
	.long	-1			/* end marker */
	.long	-1			/* end marker */
	.long	-1			/* end marker */



#################################################
#################################################
#################################################

/*
   Enter with:
	A1 is the address to test
	A6 is the return address

   Returns:
	D6 is the compare failure count

*/
	.text
	.align 4

bytetest:
	clr.l	%d6

	move.l	#0x01020408,(%a1)
	nop

	cmp.b	#0x01,0(%a1)
	jbeq	bt1
	add	#1,%d6
bt1:
	cmp.b	#0x02,1(%a1)
	jbeq	bt2
	add	#2,%d6
bt2:
	cmp.b	#0x04,2(%a1)
	jbeq	bt4
	add	#4,%d6
bt4:
	cmp.b	#0x08,3(%a1)
	jbeq	bt8
	add	#8,%d6
bt8:
	cmp.w	#0x0408,2(%a1)
	jbeq	bw2
	add	#32,%d6
bw2:
	cmp.w	#0x0102,(%a1)
	jbeq	bw1
	add	#16,%d6
bw1:
.if CPU>68010
	cmp.w	#0x0204,1(%a1)		/* unaligned word access on 68000 */
.else
	move.b	1(%a1),%d0
	lsl.w	#8,%d0
	move.b	2(%a1),%d0
	cmp.w	#0x0204,%d0
.endif
	jbeq	bw3
	add	#64,%d6
bw3:
#	move.b	#0x10,(%a1)		/* usual */
	move.b	#0x10,0(%a1)		/* does this hiccup on the 68008? */
	cmp.l	#0x10020408,(%a1)
	jbeq	bb1
	add	#1,%d6
bb1:
	move.b	#0x20,1(%a1)
	cmp.l	#0x10200408,(%a1)
	jbeq	bb2
	add	#2,%d6
bb2:
	move.b	#0x30,2(%a1)
	cmp.l	#0x10203008,(%a1)
	jbeq	bb3
	add	#4,%d6
bb3:
	move.b	#0x80,3(%a1)
	cmp.l	#0x10203080,(%a1)
	jbeq	bb4
	add	#8,%d6
bb4:
.if CPU>68010
	move.w	#0x0204,1(%a1)		/* unaligned word access on 68000 */
.else
	move.b	#0x02,1(%a1)
	move.b	#0x04,2(%a1)
.endif
	cmp.l	#0x10020480,(%a1)
	jbeq	bb5
	add	#64,%d6
bb5:
	move.w	#0x1122,0(%a1)
	cmp.l	#0x11220480,(%a1)
	jbeq	bb6
	add	#16,%d6
bb6:
	move.w	#0x3344,2(%a1)
	cmp.l	#0x11223344,(%a1)
	jbeq	bb7
	add	#32,%d6
bb7:


/* the sulfuric acid test */
	movm.l	%d0-%d7/%a0-%a6,-(%sp)

	movm.l	%d0-%d7/%a0-%a6,2(%a1)	/* pound into memory */

	movm.l	2(%a1),%d0-%d7/%a0-%a6	/* retrieve from mem. */

	cmp.l	(%sp),%d0
	jbne	err6
	cmp.l	4(%sp),%d1
	jbne	err6
	cmp.l	8(%sp),%d2
	jbne	err6
	cmp.l	12(%sp),%d3
	jbne	err6
	cmp.l	16(%sp),%d4
	jbne	err6
	cmp.l	20(%sp),%d5
	jbne	err6
	cmp.l	24(%sp),%d6
	jbne	err6
	cmp.l	28(%sp),%d7
	jbne	err6
	cmp.l	32(%sp),%a0
	jbne	err6

	lea	36(%sp),%a0
	cmp.l	(%a0)+,%a1
	jbne	err6
	cmp.l	(%a0)+,%a2
	jbne	err6
	cmp.l	(%a0)+,%a3
	jbne	err6
	cmp.l	(%a0)+,%a4
	jbne	err6
	cmp.l	(%a0)+,%a5
	jbne	err6
	cmp.l	(%a0)+,%a6
	jbne	err6

	movm.l	(%sp)+,%d0-%d7/%a0-%a6	/* restore */
	jbra	noerr7	
err6:
	movm.l	(%sp)+,%d0-%d7/%a0-%a6	/* restore */
	add.b	#128,%d6		/* set error code */
noerr7:
	rts
	
	
#################################################
