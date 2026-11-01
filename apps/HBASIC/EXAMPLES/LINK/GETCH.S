* Assembler linking example

	opt	lattice

global	equr	a5
eofch	equ	-1

* The BASIC routines that we use
	xref	dcr_dest
	xref	_SXL,_SOURCES,_CHI

* The routine that we are defining
	xdef	_getch


_getch
	lea	_SOURCES(global),a0
	bsr	dcr_dest	
	move.l	_SXL(global),d0
	cmp.l	d4,d0
	bcc.s	getch_eof
	move.b	-1(a1,d0.l),_CHI+1(global)
	addq.l	#1,d0
	move.l	d0,_SXL(global)
	rts
getch_eof	move.w	#eofch,_CHI(global)
	rts
