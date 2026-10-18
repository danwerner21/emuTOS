#NO_APP
	.file	"fmt_dump.c"
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"D"
.LC1:
	.string	"A"
.LC2:
	.string	" A"
.LC3:
	.string	"  %s%hd %08lx"
.LC4:
	.string	"\n"
	.text
	.align	2
	.globl	print_reg_state
	.type	print_reg_state, @function
print_reg_state:
	link.w %fp,#0
	movm.l #0x3820,-(%sp)
	move.l 8(%fp),%a2
	btst #5,78(%a2)
	jbeq .L2
	move.w 64(%a2),%d0
	move.w %d0,%d1
	swap %d1
	mov.w 66(%a2),%d1
	jbra .L4
.L2:
	move.w 68(%a2),%d4
	move.w %d4,%d1
	swap %d1
	mov.w 70(%a2),%d1
.L4:
	move.l %d1,%d0
	clr.w %d0
	swap %d0
	move.w %d0,60(%a2)
	move.w %d1,62(%a2)
	clr.w %d2
	clr.w %d3
	jbra .L21
.L6:
	move.w %d2,%d1
	subq.w #8,%d1
	cmp.w #7,%d2
	jbgt .L7
	move.w %d2,%d1
	move.l #.LC0,%d0
	jbra .L9
.L7:
	move.l #.LC1,%d0
	cmp.w #11,%d2
	jbgt .L9
	move.l #.LC2,%d0
.L9:
	move.w %d2,%a0
	add.l %a0,%a0
	add.l %a0,%a0
	move.w (%a2,%a0.l),%a1
	move.w %a1,%d4
	swap %d4
	mov.w 2(%a2,%a0.l),%d4
	move.l %d4,-(%sp)
	move.w %d1,%a0
	move.l %a0,-(%sp)
	move.l %d0,-(%sp)
	pea .LC3
	jbsr cprintf
	addq.w #4,%d2
	lea (16,%sp),%sp
.L21:
	cmp.w #15,%d2
	jble .L6
	pea .LC4
	jbsr cprintf
	addq.w #1,%d3
	addq.l #4,%sp
	cmp.w #3,%d3
	jbgt .L15
	move.w %d3,%d2
	jbra .L21
.L15:
	movm.l -16(%fp),#0x41c
	unlk %fp
	rts
	.size	print_reg_state, .-print_reg_state
	.section	.rodata.str1.1
.LC5:
	.string	"PC %06lx  SR %04hx  USP %06lx"
.LC6:
	.string	"  SSP %06lx"
	.text
	.align	2
	.globl	print_state
	.type	print_state, @function
print_state:
	link.w %fp,#0
	move.l %a3,-(%sp)
	move.l %a2,-(%sp)
	move.l 8(%fp),%a2
	move.l %a2,-(%sp)
	jbsr print_reg_state
	move.w 68(%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 70(%a2),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.w 78(%a2),%d0
	move.l %d0,-(%sp)
	move.w 72(%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 74(%a2),%d0
	move.l %d0,-(%sp)
	pea .LC5
	lea cprintf,%a3
	jbsr (%a3)
	lea (20,%sp),%sp
	cmp.w #4095,76(%a2)
	jbne .L23
	pea .LC4
	jbsr (%a3)
	addq.l #4,%sp
	jbra .L26
.L23:
	move.w 64(%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 66(%a2),%d0
	move.l %d0,-(%sp)
	pea .LC6
	jbsr (%a3)
	pea .LC4
	jbsr (%a3)
	lea (12,%sp),%sp
.L26:
	move.l -8(%fp),%a2
	move.l -4(%fp),%a3
	unlk %fp
	rts
	.size	print_state, .-print_state
	.section	.rodata.str1.1
.LC7:
	.string	" "
	.text
	.align	2
	.globl	mid_space
	.type	mid_space, @function
mid_space:
	link.w %fp,#0
	moveq #15,%d0
	and.l 8(%fp),%d0
	moveq #8,%d1
	cmp.l %d0,%d1
	jbne .L30
	pea .LC7
	jbsr cprintf
	addq.l #4,%sp
.L30:
	unlk %fp
	rts
	.size	mid_space, .-mid_space
	.section	.rodata.str1.1
.LC8:
	.string	"%06lx: "
.LC9:
	.string	" %08lx"
.LC10:
	.string	" %04hx"
.LC11:
	.string	" %02hx"
.LC12:
	.string	"  *%s*\n"
	.text
	.align	2
	.globl	fmt_dump
	.type	fmt_dump, @function
fmt_dump:
	link.w %fp,#-20
	movm.l #0x3f38,-(%sp)
	move.l 8(%fp),%d2
	move.l 12(%fp),%d0
	move.l %d0,%d3
	add.l 16(%fp),%d3
	moveq #2,%d1
	cmp.l %d2,%d1
	jbeq .L32
	move.b #4,%d1
	cmp.l %d2,%d1
	jbeq .L34
	move.l %d0,%d5
	move.l #padL.1213+6,%d7
	moveq #1,%d2
	jbra .L36
.L32:
	moveq #-2,%d5
	and.l %d0,%d5
	addq.l #1,%d3
	moveq #-2,%d0
	and.l %d0,%d3
	move.l #padL.1213+4,%d7
.L36:
	clr.b -1(%fp)
	moveq #-16,%d1
	and.l %d5,%d1
	move.l %d1,%a2
.L37:
	lea (-17,%fp),%a0
.L38:
	move.b #46,(%a0)+
	move.l %fp,%d0
	subq.l #1,%d0
	cmp.l %a0,%d0
	jbne .L38
	move.l %a2,-(%sp)
	pea .LC8
	jbsr cprintf
	lea (16,%a2),%a4
	clr.w %d6
	addq.l #8,%sp
	jbra .L40
.L41:
	move.l %a2,-(%sp)
	jbsr mid_space
	move.l %d7,-(%sp)
	jbsr cprintf
	sub.l %a0,%a0
	addq.l #8,%sp
	jbra .L42
.L43:
	moveq #0,%d0
	move.w %d1,%d0
	move.b #32,-17(%fp,%d0.l)
.L42:
	move.w %a0,%d0
	move.w %d6,%d1
	add.w %a0,%d1
	addq.l #1,%a0
	and.l #65535,%d0
	cmp.l %d0,%d2
	jbgt .L43
	add.l %d2,%a2
	move.w %d1,%d6
.L40:
	cmp.l %a2,%d5
	jbhi .L41
	jbra .L68
.L46:
	move.l %a2,-(%sp)
	jbsr mid_space
	addq.l #4,%sp
	moveq #2,%d0
	cmp.l %d2,%d0
	jbeq .L49
	moveq #4,%d1
	cmp.l %d2,%d1
	jbeq .L50
	move.b #1,%d0
	cmp.l %d2,%d0
	jbne .L47
	jbra .L48
.L50:
	move.l (%a2),-(%sp)
	pea .LC9
	jbra .L71
.L49:
	moveq #0,%d0
	move.w (%a2),%d0
	move.l %d0,-(%sp)
	pea .LC10
	jbra .L71
.L48:
	moveq #0,%d0
	move.b (%a2),%d0
	move.l %d0,-(%sp)
	pea .LC11
.L71:
	jbsr cprintf
	addq.l #8,%sp
.L47:
	moveq #0,%d4
	jbra .L51
.L52:
	clr.w %d1
	move.b (%a2,%d0.l),%d1
	moveq #0,%d0
	move.w %d1,%d0
	move.w #-32,%a0
	add.l %d0,%a0
	moveq #94,%d0
	cmp.l %a0,%d0
	jbcs .L53
	moveq #0,%d0
	move.w %a1,%d0
	move.b %d1,-17(%fp,%d0.l)
.L53:
	addq.l #1,%d4
.L51:
	move.w %d4,%d0
	move.w %d6,%a1
	add.w %d4,%a1
	and.l #65535,%d0
	cmp.l %d0,%d2
	jbgt .L52
	add.l %d2,%a2
	move.w %a1,%d6
.L68:
	cmp.l %a2,%a4
	jbls .L69
	cmp.l %a2,%d3
	jbhi .L46
	jbra .L69
.L58:
	move.l %a2,-(%sp)
	jbsr mid_space
	move.l %d7,-(%sp)
	jbsr (%a3)
	sub.l %a0,%a0
	addq.l #8,%sp
	jbra .L59
.L60:
	moveq #0,%d0
	move.w %d1,%d0
	move.b #32,-17(%fp,%d0.l)
.L59:
	move.w %a0,%d0
	move.w %d6,%d1
	add.w %a0,%d1
	addq.l #1,%a0
	and.l #65535,%d0
	cmp.l %d0,%d2
	jbgt .L60
	add.l %d2,%a2
	move.w %d1,%d6
.L69:
	lea cprintf,%a3
	cmp.l %a2,%a4
	jbhi .L58
	pea -17(%fp)
	pea .LC12
	jbsr (%a3)
	addq.l #8,%sp
	cmp.l %a2,%d3
	jbls .L70
	jbra .L37
.L34:
	moveq #-2,%d5
	and.l %d0,%d5
	addq.l #1,%d3
	moveq #-2,%d1
	and.l %d1,%d3
	move.l #padL.1213,%d7
	jbra .L36
.L70:
	movm.l -56(%fp),#0x1cfc
	unlk %fp
	rts
	.size	fmt_dump, .-fmt_dump
	.section	.rodata
	.type	padL.1213, @object
	.size	padL.1213, 10
padL.1213:
	.string	"         "
	.ident	"GCC: (GNU) 4.1.1"
