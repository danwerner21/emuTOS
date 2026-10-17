#NO_APP
	.file	"ns202.c"
	.text
	.align	2
	.globl	icu_inpw
	.type	icu_inpw, @function
icu_inpw:
	link.w %fp,#0
	move.l 8(%fp),%a0
	moveq #0,%d0
	move.b 256(%a0),%d0
	lsl.l #8,%d0
	or.b (%a0),%d0
	unlk %fp
	rts
	.size	icu_inpw, .-icu_inpw
	.align	2
	.globl	icu_outpw
	.type	icu_outpw, @function
icu_outpw:
	link.w %fp,#0
	move.l 8(%fp),%a0
	move.l 12(%fp),%d0
	move.b %d0,(%a0)
	asr.l #8,%d0
	move.b %d0,256(%a0)
	unlk %fp
	rts
	.size	icu_outpw, .-icu_outpw
	.align	2
	.globl	ns202_init2
	.type	ns202_init2, @function
ns202_init2:
	link.w %fp,#0
	movm.l #0x38,-(%sp)
	move.w #-28608,%a4
	move.b #66,(%a4)
	move.w #-27072,%a3
	clr.b (%a3)
	pea 24299.w
	pea -26560.w
	lea icu_outpw,%a2
	jbsr (%a2)
	pea 24299.w
	pea -26048.w
	jbsr (%a2)
	move.b #55,-28096.w
	pea 24299.w
	pea -25536.w
	jbsr (%a2)
	pea 24299.w
	pea -25024.w
	jbsr (%a2)
	move.b #49,-26816.w
	move.b #15,-27584.w
	st -27328.w
	clr.b -28352.w
	lea (28,%sp),%sp
	clr.l (%sp)
	pea -30656.w
	jbsr (%a2)
	clr.l -(%sp)
	pea -29632.w
	jbsr (%a2)
	move.b #16,-32448.w
	move.b #16,-32702.w
	clr.b -29120.w
	move.l #65535,-(%sp)
	pea -31680.w
	jbsr (%a2)
	move.l #65535,-(%sp)
	pea -32192.w
	jbsr (%a2)
	move.b #2,(%a4)
	move.b #8,(%a3)
	lea (28,%sp),%sp
	move.l #65280,(%sp)
	pea -30144.w
	jbsr (%a2)
	addq.l #8,%sp
	movm.l -12(%fp),#0x1c00
	unlk %fp
	rts
	.size	ns202_init2, .-ns202_init2
	.ident	"GCC: (GNU) 4.1.1"
