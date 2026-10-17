#NO_APP
	.file	"prettydump.c"
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"%08lx "
.LC1:
	.string	"   "
.LC2:
	.string	" %02x"
.LC3:
	.string	"  %s"
.LC4:
	.string	"\n%08lx "
.LC5:
	.string	"\n"
.LC6:
	.string	"  %s\n"
	.text
	.align	2
	.globl	pretty_dump_memory
	.type	pretty_dump_memory, @function
pretty_dump_memory:
	link.w %fp,#-20
	movm.l #0x3c30,-(%sp)
	move.l 8(%fp),%d4
	move.l 12(%fp),%d5
	move.l %d4,%d2
	lea (-17,%fp),%a0
.L2:
	move.b #32,(%a0)+
	move.l %fp,%d0
	subq.l #1,%d0
	cmp.l %a0,%d0
	jbne .L2
	clr.b -1(%fp)
	moveq #-16,%d0
	and.l %d4,%d0
	move.l %d0,-(%sp)
	pea .LC0
	jbsr cprintf
	moveq #0,%d3
	addq.l #8,%sp
	jbra .L4
.L5:
	pea .LC1
	jbsr cprintf
	addq.l #1,%d3
	addq.l #4,%sp
.L4:
	moveq #15,%d0
	and.l %d4,%d0
	cmp.l %d3,%d0
	jbhi .L5
	lea -17(%fp,%d3.l),%a2
	jbra .L29
.L8:
	move.l %d2,%a0
	move.b (%a0),%d1
	move.b %d1,%d0
	add.b #-32,%d0
	cmp.b #94,%d0
	jbhi .L9
	move.b %d1,(%a2)
	jbra .L11
.L9:
	move.b #46,(%a2)
.L11:
	move.l %d2,%a0
	addq.l #1,%d2
	moveq #0,%d0
	move.b (%a0)+,%d0
	move.l %d0,-(%sp)
	pea .LC2
	lea cprintf,%a3
	jbsr (%a3)
	subq.l #1,%d5
	moveq #15,%d0
	and.l %d2,%d0
	addq.l #8,%sp
	jbne .L12
	lea (-17,%fp),%a2
	move.l %a2,-(%sp)
	pea .LC3
	jbsr (%a3)
	addq.l #8,%sp
	tst.l %d5
	jbeq .L14
	move.l %d2,-(%sp)
	pea .LC4
	jbsr (%a3)
	addq.l #8,%sp
	jbra .L29
.L14:
	pea .LC5
	jbsr (%a3)
	addq.l #4,%sp
	jbra .L21
.L12:
	addq.l #1,%a2
.L29:
	tst.l %d5
	jbne .L8
	moveq #15,%d0
	and.l %d0,%d2
	moveq #16,%d3
	sub.l %d2,%d3
	moveq #0,%d2
	jbra .L18
.L19:
	pea .LC1
	jbsr (%a0)
	move.b #32,(%a2,%d2.l)
	addq.l #1,%d2
	addq.l #4,%sp
.L18:
	lea cprintf,%a0
	cmp.l %d2,%d3
	jbgt .L19
	pea -17(%fp)
	pea .LC6
	jbsr (%a0)
	addq.l #8,%sp
.L21:
	movm.l -44(%fp),#0xc3c
	unlk %fp
	rts
	.size	pretty_dump_memory, .-pretty_dump_memory
	.ident	"GCC: (GNU) 4.1.1"
