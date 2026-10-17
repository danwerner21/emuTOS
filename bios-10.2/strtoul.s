#NO_APP
	.file	"strtoul.c"
	.text
	.align	2
	.type	ndigit, @function
ndigit:
	link.w %fp,#0
	move.b 11(%fp),%d1
	move.b %d1,%d0
	add.b #-48,%d0
	cmp.b #9,%d0
	jbls .L4
	move.b %d1,%d0
	add.b #-65,%d0
	cmp.b #25,%d0
	jbhi .L5
	add.b #10,%d0
	jbra .L4
.L5:
	move.b %d1,%d0
	add.b #-97,%d0
	cmp.b #25,%d0
	jbls .L7
	st %d0
	jbra .L4
.L7:
	move.b %d1,%d0
	add.b #-87,%d0
.L4:
	ext.w %d0
	ext.l %d0
	unlk %fp
	rts
	.size	ndigit, .-ndigit
	.globl	__udivsi3
	.globl	__umodsi3
	.globl	__mulsi3
	.align	2
	.globl	strtoul
	.type	strtoul, @function
strtoul:
	link.w %fp,#0
	movm.l #0x3e3c,-(%sp)
	move.l 8(%fp),%d4
	move.l 12(%fp),%a5
	move.l 16(%fp),%d3
	clr.l errno
	move.l %d4,%a2
	jbra .L11
.L12:
	addq.l #1,%a2
.L11:
	move.b (%a2),%d0
	cmp.b #32,%d0
	jbeq .L12
	cmp.b #9,%d0
	jbeq .L12
	cmp.b #45,%d0
	jbne .L15
	addq.l #1,%a2
	st %d6
	jbra .L17
.L15:
	cmp.b #43,%d0
	jbeq .L18
	clr.b %d6
	jbra .L17
.L18:
	addq.l #1,%a2
	moveq #1,%d6
.L17:
	move.b (%a2),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	lea ndigit,%a4
	jbsr (%a4)
	addq.l #4,%sp
	move.b %d0,%d2
	tst.l %d3
	jbne .L20
	tst.b %d0
	jbeq .L22
	move.b #10,%d3
	jbra .L24
.L22:
	lea (1,%a2),%a3
	move.b (%a3),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr (%a4)
	addq.l #4,%sp
	cmp.b #33,%d0
	jbne .L25
	lea (1,%a3),%a2
	move.b (%a2),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr (%a4)
	addq.l #4,%sp
	move.b %d0,%d2
	moveq #16,%d3
	jbra .L24
.L25:
	moveq #8,%d3
	jbra .L24
.L20:
	moveq #16,%d0
	cmp.l %d3,%d0
	jbne .L24
	tst.b %d2
	jbne .L24
	lea (1,%a2),%a3
	move.b (%a3),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr (%a4)
	addq.l #4,%sp
	cmp.b #33,%d0
	jbne .L24
	move.l %a3,%a2
.L24:
	and.l #255,%d2
	cmp.l %d2,%d3
	jbgt .L30
	move.l %d4,%d0
	subq.l #1,%d0
	moveq #1,%d1
	move.l %d1,errno
	moveq #0,%d2
	jbra .L32
.L30:
	move.l %d3,-(%sp)
	pea -1.w
	jbsr __udivsi3
	addq.l #8,%sp
	move.l %d0,%a3
	move.l %d3,-(%sp)
	pea -1.w
	jbsr __umodsi3
	addq.l #8,%sp
	move.b %d0,%d5
	jbra .L50
.L34:
	moveq #0,%d4
	move.b %d0,%d4
	cmp.l %d4,%d3
	jble .L35
	cmp.l %d2,%a3
	jbhi .L37
	jbne .L35
	cmp.b %d0,%d5
	jbcs .L35
.L37:
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	jbsr __mulsi3
	addq.l #8,%sp
	move.l %d0,%d2
	add.l %d4,%d2
	jbra .L50
.L35:
	moveq #1,%d0
	move.l %d0,errno
	addq.l #1,%a2
	moveq #0,%d2
.L50:
	addq.l #1,%a2
	move.b (%a2),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr ndigit
	addq.l #4,%sp
	cmp.b #-1,%d0
	jbne .L34
	move.l %a2,%d0
	subq.l #1,%d0
	tst.b %d6
	jbge .L32
	neg.l %d2
.L32:
	cmp.w #0,%a5
	jbeq .L42
	addq.l #1,%d0
	move.l %d0,(%a5)
.L42:
	move.l %d2,%d0
	movm.l -36(%fp),#0x3c7c
	unlk %fp
	rts
	.size	strtoul, .-strtoul
	.align	2
	.globl	atoi
	.type	atoi, @function
atoi:
	link.w %fp,#0
	clr.l -(%sp)
	clr.l -(%sp)
	move.l 8(%fp),-(%sp)
	jbsr strtoul
	unlk %fp
	rts
	.size	atoi, .-atoi
	.comm	errno,4,4
	.ident	"GCC: (GNU) 4.1.1"
