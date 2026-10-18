/*  startup.s  */
/**********************************************************************
	Copyright (C) 2011,2012,2016,2022 John R. Coffman.
	Licensed for hobbyist use on the RetroBrew 68000 CPU boards.
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
.include  "mfpic.s"		
############################################################
.include  "ppi.s"
############################################################
.include  "biostrap.s"
############################################################
CTYPEPTR=0
	.bss

############################################################
 	.comm	h_m_a,4,4
	.comm	memmax,4,4		/* KISS board DOUBLE jumper setting */
.if CTYPEPTR
	.comm __ctype_ptr,4,4
.endif
	.comm	mem_chain,4,4
	.comm	reset_code,4,4		/* used to flag Reset exception trap */
					/* which requests a full memory test */
	.comm	nvram,32,2
	.comm	debug,2,2
	.comm	uart_type,1,1		/* uart type determination */
.if 0
	.comm	buffer,512,2
.endif
############################################################


/* error stop codes:       */
ERR_SRAM_DATA_PATH_1	=	7		/* used in 'sram_test.s'  */
ERR_SRAM_DATA_PATH_2	=	6		/*    ditto		*/
ERR_SRAM_BIT_TEST	=	5		/* test every bit in SRAM */
ERR_UART_NOT_FOUND	=	4		/* cannot find MF/PIC UART */
/* never can find the UART at power-up, but it is there after a Reset  ??? */
/* explanation:  MSR is unpredictable  */


/* flag Reset exception trap into a full memory test */
FLAG_RESET	=	0x3456789A

	.text
	.globl	location_zero
	.globl	_start
	.globl	space, crlf

/* the bootstrap longwords:  */
location_zero:
.if CPU==68030
	.long	0xFFFE6000		/* Reset:  initial SSP==ISP */
.else
	.long	0x70000			/* Reset:  initial SSP */
.endif
	.long	_start			/* Reset:  initial PC  */
.if CPU==68030
	.long	bus_error
.endif

/* We want the copyright notice as near to the start of the ROM as possible */
msg_copyright:
	.ascii	"Copyright (C) 2011-2022 John R. Coffman  <johninsd@gmail.com>"
	.ascii	"\r\n"
	.ascii	"Copyright (C) 2015,2021 William R. Sowerbutts <will@sowerbutts.com>"
.ifdef WYSE
	.ascii	"\033\""		/* unlock keyboard    ESC "      */
.endif
	.asciz	"\r\n"


/* these may be moved anywhere */	
	.align	4
vector_2:
	.long	exception_2		/* Bus Error     *** */
	.long	exception_3		/* Address Error *** */
	.long	exception_4		/* Illegal Instruction */
	.long	exception_5		/* Zero Divide */
	.long	exception_6		/* CHK instruction */
	.long	exception_7		/* TRAPV instruction */
	.long	exception_8		/* Privilege violation */
	.long	exception_9		/* Trace trap */
	.long	exception_10		/* Emulation 1010 */
	.long	exception_11		/* Emulation 1111 */
	.long	exception_12		/* reserved */
	.long	exception_13		/* reserved */
	.long	exception_14		/* Format error 68010 */
	.long	exception_15		/* Uninitialized interrupt error */

vector_16:
	.globl	spurious_return		/* return from PIC interrupts */
/* the eight PIC202 interrupts are here */

	.long	spurious_return		/* 0 */
	.long	spurious_return
	.long	spurious_return		/* 2 */
	  .globl	interrupt_3_timer
	.long	interrupt_3_timer	/* handled in pic202.s */
	.long	spurious_return		/* 4 */
	.long	spurious_return
	.long	spurious_return		/* 6 */
.if 0
	  .globl	interrupt_7_semaphore
	.long	interrupt_7_semaphore	/* handled in pic202.s */
.else
	.long	spurious_return
.endif

vector_24:
/* auto-vectored interrupts (7 is NMI) */
	.long	exception_trap		/* 0 */
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap		/* 7 -- NMI */

vector_32:
/* the TRAP call vectors */
	.long	exception_trap		/*  0 */
	.long	exception_trap
	.long	exception_trap		/*  2 -- CP/M-68 BDOS calls */
	.long	exception_trap		/*  3 -- BIOS calls for CP/M-68 */
	.long	exception_trap		/*  4 */
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap		/*  7 */
	  .globl	bios_trap_entry
	.long	bios_trap_entry		/*  8 -- put the BIOS calls here */
	.long	exception_trap		/*  9 */
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap		/* 12 */
	.long	exception_trap
	.long	exception_trap
	.long	exception_trap		/* 15 -- used by simulator */

vector_48:
/* unassigned exception traps */
.rept	16
	.long	exception_trap
.endr


/* only 64 exception vectors are defined on the MINI    */
/* a full 256 exception vectors are defined on the KISS */
.if CPU>=68020
vector_64:
/* unassigned exception traps for use by User OS */
.rept	192
	.long	exception_trap
.endr
.endif

vector_final:
# end of the exception vectors


	.globl	msg_welcome
	.globl	msg_GNU_license


msg_test1:
	.ascii	"To enter Setup type 's' during the memory test.\r\n"
	.asciz	"\rTesting, sizing, and clearing memory ..."
msg_test2:
	.asciz	"\rFound memory from "
msg_to:
	.asciz	" to "
msg_blanks:
	.asciz	"          "
.if CPU<68010
msg_low_32k_err:
	.asciz	"Memory failure between 0..32767; the system is stopped.\r\n"
.endif
msg_reset:
	.asciz	"\r\n\n     RESET exception trap requests a full memory test.\r\n"
	

	.even
space:
	move.b	#0x20,%d0
	br	sio_put
crlf:           /* issue CR + LF */
	move.b  #0x0D,%d0       /* CR is first */
	bsr     sio_put
	move.b  #0x0A,%d0       /* LF is second */
	br      sio_put


	.globl	adout, lout, wout, bout, nout, woutD
adout:
	swap	%d0
.if CPU<68020
	bsr.s	_bout
.else
	bsr.s	_wout
.endif
	swap	%d0
	br.s	_wout	
lout:
dout:
_dout:
	swap	%d0
	bsr.s	_wout
	swap	%d0
wout:
_wout:
	ror.w	#8,%d0
	bsr.s	_bout
	ror.w	#8,%d0
bout:
_bout:
	ror.b	#4,%d0
	bsr.s	_nout
	ror.b	#4,%d0
nout:
_nout:				/* write out the low nibble in ASCII */
	move.l	%d0,-(%sp)	/* push D0 */
	and.b	#0x0F,%d0	/* mask nibble */
	add.b	#0x30,%d0
	cmp.b	#0x3A,%d0	/* check for hex digit */
	blo.s	nout2
	add.b	#0x41-0x3A,%d0
nout2:
	bsr	sio_put
	move.l	(%sp)+,%d0	/* pop D0 */
	rts
.if 1
woutD:	/* put out a decimal word */
	and.l	#0x0000FFFF,%d0
	divu.w	#10,%d0			/* D0 =  R:Q */
	move.w	%d0,%d0
	jbeq	woutD1

	move.l	%d0,-(%sp)		/* save D0 */
	jbsr	woutD			/* put out the quotient */
	move.l	(%sp)+,%d0		/* restore D0 */

woutD1:
	swap	%d0			/* remainder to D0.w */
	jbra	nout			/* put out the nibble */
.endif

	
    .globl data_cache_flush
data_cache_flush:
    /* WRS: need to read the documentation here -- can we write just a single bit
       to flush the data cache, or do we need to read and preserve the other bits? */
.if CPU>=68020
    movec.l %cacr,%d0
    or.w    #CACR_CD,%d0    /* clear data cache */
    movec.l %d0,%cacr
.endif
    rts

    .globl cpu_cache_disable
cpu_cache_disable:
.if CPU>=68020
    move.l  #(CACR_CI+CACR_CD),%d0 /* disable and clear caches -- WRS: do we need to *freeze* them to disable them? */
    movec.l %d0,%cacr
.endif
    rts



_start:
	move.w  #0x2700,%sr     /* reset value of SR; insurance against
	                           a user mode jump to this location */
.ifdef WYSE
	clr.b	(-1)		/* clear the lites on the debug board */
.endif


.if CPU==68030
.include  "sram_test.s"

/* now find the setting of the DOUBLE jumper */
	move.l	#location_zero,%d0
	movec	%d0,%vbr			/* set vector base */
	move.l	%sp,%a1
	move.l	#64*1024*1024,%d7
	move.l	%d7,%a0
	move.b	(%a0),%d1		/* this will cause a bus error  */
  /* possible bus error skips */	/* if the DOUBLE jumper is not set */
	move.l	#256*1024*1024,%d7	/* change D7 if no bus error */
bus_error:
	/* D7 is set to 256Mb or 64Mb */
	move.l	%a1,%sp			/* restore SSP */

	move.l	%d7,%d0			/* set D0 for DRAM priming */
	
.include  "dram_test.s"
.endif

	move.l	#mf_sio,%d0
	lea	uart01(%pc),%a6
	jmp	_uart_find
uart01:	/* return here */
.if !RETAIL & 0
	lsl.l	#8,%d2
	move.b	%d0,%d2
	lsl.l	#8,%d2
	move.b	%d1,%d2
	move.l	%d2,-(%sp)
.endif
	move.l	%d1,-(%sp)		/* stack the uart type */
	move.l	#ERR_UART_NOT_FOUND,%d0  /* possible error code */
	tst.l	%d1
	bne.s	uart02
	lea	uart02(%pc),%a5
	jmp	_Blink
uart02:

# check for a RESET exception trap
	move.l	reset_code,%d5


.if !RETAIL
/*debug*/	move.b	#1,(-1)
.endif
.if CPU<68010
#   memmax was 0x00200000 before external memory was available
	move.l	#0x00380000,%d7		/* memmax on MINI is 3.5M */
#    but up to 380000 or 300000 with external memory     JRC 17-Sep-2022 
	lea.l	(maxchip),%a0
	lea.l	(mem_ret0,%pc),%a6
	br	_memtest
mem_ret0:
.if !RETAIL
/*debug*/	move.b	#0x11,(-1)
.endif
	move.l	%a4,%d0
	or.l	%d0,%d6
	move.l	%a5,%d0
	sub.l	#maxchip,%d0
	or.l	%d0,%d6
/*  D6 must be zero at this point else we have a memory error
 in the lowest 32K; the system is considered unusable.    */
.endif

	
# clear the C-program .BSS area
	lea.l	_end,%a0
	move.l	%a0,%d2
	lea.l	__bss_start,%a1
	sub.l	%a1,%a0
	move.l	%a0,%d0
	br.s	zap_bss
zap_loop:
	clr.b	(%a1)+
zap_bss:
	dbra	%d0,zap_loop

	move.l	%d2,mem_chain	/* for malloc */
	move.l	%d7,memmax	/* finally set memmax */
	move.l	%d5,reset_code	/* garbage or flag */
	move.l	(%sp)+,%d0
	move.b	%d0,uart_type	/* save for later */
	
/* go to fill this in */
.if CTYPEPTR
	.globl  _ctype_
	lea.l   _ctype_+1,%a0
	move.l  %a0,__ctype_ptr
.endif

/* but "main68" changes this status */
	clr.w	debug		/* no comments */

.if !RETAIL
/*debug*/	move.b	#2,(-1)
.endif
	bsr	get_nvram

.if !RETAIL
/*debug*/	move.b	#3,(-1)
.endif
	bsr	sio_init

.if !RETAIL
/* (-1)=0xFFFFFFFF address should return -1 if debug board not present */
	clr.l	%d0
	move.b	(-1),%d0
	eor.b	#0xFF,%d0
	beq.s	bg001
	eor.b	#0xFF,%d0
	and.b	#7,%d0
bg001:
	move.w	%d0,debug
.endif


.if !RETAIL
/*debug*/	move.b	#4,(-1)
.endif
	bsr	crlf

.if !RETAIL
/*debug*/	move.b	#5,(-1)
.endif
.if CPU<68010
	tst.l	%d6
	bne	low_32k_memory_error
.endif

/*  Put out the initial Welcome Message */

	lea	msg_welcome,%a0
	bsr	put_string
	lea	msg_copyright,%a0
	bsr	put_string

.if !RETAIL
/*debug*/	move.b	#6,(-1)
.endif

	move.l	memmax,%d7
	jbsr	size_ram
	move.l	%d0,h_m_a


	lea	reset_code,%a4
	move.l	(%a4),%d5	/* code when we started */
	move.l	#FLAG_RESET,%d0
	move.l	%d0,(%a4)

	cmp.l	%d0,%d5 /* check for a restart during the mem clear */
	jbne	no_big_memtest

	clr.l	(%a4)		/* defeat a second reset */
	lea	msg_reset,%a0
	jbsr	put_string
/* put the call to the big memory test program here */

	jbsr	DRAM_tests		/* this is in 'memtest3.s'  */
	
no_big_memtest:

	lea	msg_GNU_license,%a0
	bsr	put_string

	lea	msg_test1(%pc),%a0
	bsr	put_string



/* Set up the Exception Vectors */


.if !RETAIL
/*debug*/	move.b	#6,(-1)
.endif
	lea	location_zero(%pc),%a1
	clr.l	%d0
	move.l	%d0,%a2
	move.l	(%a1)+,(%a2)+
	move.l	(%a1),(%a2)+
	
	lea	vector_2(%pc),%a1
n_vectors	=	(vector_final - vector_2) / 4
	move.w	#n_vectors-2-1,%d1
set_vector:
	move.l	(%a1)+,(%a2)+
	dbra	%d1,set_vector
.if CPU>=68020
	movec	%d0,%vbr
.endif


	
/* KISS:  A2 is the address beyond the exception vectors */
/* MINI:  need to set A2 beyond the .BSS  */
.if CPU<68020
	lea.l	(_end),%a2
.endif
	move.l	h_m_a,%d3	/* get highest address */
	sub.l	%a2,%d3		/* D3 is byte count in RAM */
	lsr.l	#2,%d3		/* D3 is long count in RAM */
	jbra	zz2
	
zz0:	swap	%d3
zz1:	clr.l	(%a2)+
zz2:	dbra	%d3,zz1	
	swap	%d3
	dbra	%d3,zz0

	
/* moved from up above */
	lea	msg_test2(%pc),%a0
	bsr	put_string
	clr.l	%d0
	jbsr	adout
	lea	msg_to(%pc),%a0
	bsr	put_string
	move.l	h_m_a,%d0
	bsr	adout
	lea	msg_blanks(%pc),%a0
	bsr	put_string
	bsr	crlf

	clr.l	(%a4)		/* clear the reset_code */
	

/* now initialize the NS32202 interrupt controller (PIC) */
	.globl	ns202_init2
	bsr	ns202_init2
     	and.w	#~0x0700,%sr	/* enable interrupts */
.if !RETAIL
/*debug*/	move.b	#7,(-1)
.endif

	bsr	sio_get
	move.l	%d0,-(%sp)	/* push argument, possible an 's' */
	.globl	setup
	bsr	setup
	add.l	#4,%sp		/* discard argument */

	.globl	configure
	bsr	configure	/* go configure based on NVRAM */
	
	.globl	main68
	bsr	main68
/* any return from MAIN comes here */
      	.globl	_exit
_exit:
	move.l	%d0,-(%sp)
__exit:				/* return code is at top of stack */
	pea	fmt9(%pc)
	bsr	cprintf
	add.l	#8,%sp
/* now STOP, we are all done here */
stop0:	stop	#0x2701
	br.s	stop0		/* loop on NMI */
/* only a hardware RESET gets us beyond here */

     	.globl	exit
exit:	add.l	#4,%sp		/* remove return address */
	br.s	__exit		/* leave return code on stack */


fmt9:
	.ascii	"\nExit/stop code = 0x%02x\n"
	.asciz	"System shutdown. Re-boot required.\n"


	.even
exception_2:
	move.w	#2,-(%sp)
	br	exception_AB	/* now same as 'br exception' */
exception_3:
	move.w	#3,-(%sp)
	br	exception_AB	/* now same as 'br exception' */
exception_4:
	move.w	#4,-(%sp)
	br	exception
exception_5:
	move.w	#5,-(%sp)
	br	exception
exception_6:
	move.w	#6,-(%sp)
	br	exception
exception_7:
	move.w	#7,-(%sp)
	br	exception
exception_8:
	move.w	#8,-(%sp)
	br	exception
exception_9:
	move.w	#9,-(%sp)
	br	exception
exception_10:
	move.w	#10,-(%sp)
	br	exception
exception_11:
	move.w	#11,-(%sp)
	br	exception
exception_12:
	move.w	#12,-(%sp)
	br	exception
exception_13:
	move.w	#13,-(%sp)
	br	exception
exception_14:
	move.w	#14,-(%sp)
	br	exception
exception_15:
	move.w	#15,-(%sp)
	br	exception


msg_ident2:
	.asciz	"2  Memory Write"	/* only way Bus Error is generated */
	.asciz	"3 Address Error"	/* must be 15 chars + NULL */
	.asciz	"4 Illegal Instr"
	.asciz	"5  Zero Divide "
	.asciz	"6 CHK Instruct "
	.asciz	"7 TRAPV Instruc"
	.asciz	"8 Privilege Ins"
	.asciz	"9 Trace Trap	"
	.asciz	"10 1010 Emulat "
	.asciz	"11 1111 Emulat "
	.asciz	"12 unknown trap"
	.asciz	"13 unknown trap"
.if CPU<68010
	.asciz	"14 Format Error"
.else
	.asciz	"14 unknown trap"
.endif
	.asciz	"15 unknown trap"

msg_except2:
	.asciz	"\r\nException "

msg_addr:
	.asciz  "  ADDR "
msg_instr:
	.asciz  "  IR "
msg_funct:
	.asciz  "  FC "


	.even
exception_AB:
exception:
	or      #0x0700,%sr             /* disable all but NMI */
.if 1	/* code new */
/*  machine state save to area defined in 'beetle.s' -- with variations  */
	movem.l	%d0-%d7/%a0-%a6,state	/* save all registers but A7/SSP */
	lea	msg_except2(%pc),%a0
	bsr	put_string		/* write "Exception "		*/
	lea	msg_ident2-32(%pc),%a0
	move.w	(%sp)+,%d3		/* *** new line--get trap no. from stack */
	move.w	%d3,s_trap_no		/* save for later */
	lsl	#4,%d3			/* index by 16 byte increments	*/
	add.l	%d3,%a0			
	bsr	put_string		/* write "# XXXXXXXXXXXXX"	*/
	cmp.w	#4*16,%d3
	bcc	skip_2_3
/* must clear additional information on the stack */
	move.w	(%sp)+,%d7		/* retrieve function code */
	lea	msg_addr(%pc),%a0
	bsr	put_string
	move.l	(%sp)+,%d0		/* address */
	bsr	adout
	lea	msg_instr(%pc),%a0
	bsr	put_string
	move.w	(%sp)+,%d0		/* instruction */
	bsr	wout
	lea	msg_funct(%pc),%a0
	bsr	put_string
	move.w	%d7,%d0			/* function code */
	and.w	#0x1F,%d0		/* only bits 4..0 matter */
	bsr	bout
skip_2_3:
	bsr	crlf

.if 1	/* grab */
	move.w 	(%sp)+,%d4		/* get the SR */
/*	and.w	#~TRACE_MASK,%d4	/* clear the T1/T0 bits */
	move.w	%d4,s_sr
	move.l	(%sp)+,s_pc		/* set the user's return point */
.if CPU>=68010
	move.w	(%sp)+,s_frame		/* save interrupt frame word */
.else
	clr.w	s_frame			/* or mark as valid so SSP is restored */
.endif
	move.l	%sp,s_ssp		/* save SSP (ISP) */
	move.l	%usp,%a1		/* save USP */
	move.l	%a1,s_usp

.else	/* grab */
	/* the grab using " ...,(%a0)+ " was here */
.endif /* grab */


.if CPU>68010
	movec	%isp,%a1		/* save the ISP */
	move.l	%a1,s_isp
	movec	%msp,%a1		/* save the MSP */
	move.l	%a1,s_msp
.endif
/*	the Trap No. has already been saved */
.if !RETAIL
	clr.l	-(%sp)			/* debug68(0) */
	bsr	debug68			/* enter the debugger */
.else
	pea	state
	bsr	print_state		/* version is in debug.c for now */
.endif
	add	#4,%sp
	move.w	s_trap_no,%d0
	br	_exit



.endif	/* code new */




exception_trap:
/*	former write to the Lites here */
	move.w  #63,%d0
	br      _exit
exception_stop:
	move.w  #0,-(%sp)       /* pad exception code to long */
	br      __exit

.if CPU<68010
low_32k_memory_error:
	lea	msg_low_32k_err(%pc),%a0
	bsr	put_string
	br	exception_trap
.endif

# Swap all the bytes in a long

	.even
	.globl	bswap
bswap:
lswap:
	move.l	4(%sp),%d0
	ror.w	#8,%d0
	swap	%d0
	ror.w	#8,%d0
	rts

# Swap the bytes in a short
	.even
	.globl	wswap
wswap:
	move.w	4+2(%sp),%d0
	ror.w	#8,%d0
	rts

/* Run in User/Supervisor Mode
/*
/*	void _run_us_mode(word supvmode, (void*)pc, long usp, long ssp);
		mode == 0 user mode
		mode >= 1 supervisor mode
		
*/
	.globl	_run_us_mode	
_run_us_mode:
	movem.l	(%sp)+,%d0-%d2/%a0-%a1	/* get return + all the arguments */
	move.l	%a1,%sp			/* set new SSP */
	move.l	%a0,%usp		/* set new USP */
.if CPU>=68010
	move.w	#0,-(%sp)		/* stack frame type 0 */
.endif
	move.l	%d2,-(%sp)		/* starting address */
	move.w	%d1,%d0			/* test D0 result */
	beq.s	_user_mode
	move.w	#0x2000,%d0		/* set supervisor mode */
_user_mode:
	move.w	%d0,-(%sp)		/* S_bit = "mode", CCR = 0	*/
/* now clear everything */
	clr.l	%d0
	clr.l	%d1
	clr.l	%d2
	clr.l	%d3
	clr.l	%d4
	clr.l	%d5
	clr.l	%d6
	clr.l	%d7
	move.l	%d7,%a0
	move.l	%d7,%a1
	move.l	%d7,%a2
	move.l	%d7,%a3
	move.l	%d7,%a4
	move.l	%d7,%a5
	move.l	%d7,%a6
	rte				/* load SR + PC  */
/* user mode program must terminate with an EXIT bios call */
	


.if 0
/* the below is for debugging */

dwdump:
	move.b	#' ',%d0
	bsr	sio_put
	move.l	(%a0)+,%d0
	bsr	dout
	rts

	.globl	stackdump
stackdump:
	move.l	%d0,-(%sp)
	move.l	%a0,-(%sp)

	lea	12(%sp),%a0
	move	%a0,%d0
	bsr	dout
	move.b	#':',%d0
	bsr	sio_put

	bsr	dwdump
	bsr	dwdump
	bsr	dwdump
	bsr	dwdump
	bsr	dwdump
	bsr	dwdump
	bsr	crlf

	move.l	(%sp)+,%a0
	move.l	(%sp)+,%d0
	rts

	.globl	regdump
regdump:
	movm.l	%d0/%d1/%a0/%a1,-(%sp)

	movm.l	%d0-%d7/%a0-%a7,-(%sp)
	move.w	%sr,%d0
	movm.l	%d0,-(%sp)
	pea	fmtregs(%pc)
	bsr	cprintf
	add.l	#4*18,%sp

	movm.l	(%sp)+,%d0/%d1/%a0/%a1
	rts

.endif	



############################################################
############################################################
############################################################
############################################################
############################################################
.if CPU<68010
.include  "memtest.s"
.endif



		
############################################################
.include  "size_ram.s"
############################################################








		
############################################################
.include  "blinken.s"
############################################################

	.end


