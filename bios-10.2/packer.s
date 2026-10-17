#NO_APP
	.file	"packer.c"
	.text
	.align	2
	.globl	_uval
	.type	_uval, @function
_uval:
	link.w %fp,#0
	move.b 15(%fp),%d1
	moveq #0,%d0
	move.b %d1,%d0
	move.l 8(%fp),%a0
	add.l %d0,%a0
	moveq #0,%d0
	jbra .L2
.L3:
	lsl.l #8,%d0
	or.b -(%a0),%d0
.L2:
	subq.b #1,%d1
	cmp.b #-1,%d1
	jbne .L3
	unlk %fp
	rts
	.size	_uval, .-_uval
	.align	2
	.globl	unpack
	.type	unpack, @function
unpack:
	link.w %fp,#0
	movm.l #0x2038,-(%sp)
	move.l 8(%fp),%a4
	move.l 12(%fp),%a2
	move.l 16(%fp),%d2
	move.l %d2,%a3
	jbra .L7
.L8:
	cmp.b #99,%d0
	jbeq .L11
	jbgt .L14
	cmp.b #98,%d0
	jbne .L9
	jbra .L10
.L14:
	cmp.b #100,%d0
	jbeq .L12
	cmp.b #119,%d0
	jbne .L9
	jbra .L13
.L11:
	move.b (%a2)+,(%a3)+
	jbra .L9
.L10:
	moveq #0,%d0
	move.b (%a2)+,%d0
	lsl.l #8,%d0
	move.w %d0,(%a3)+
	jbra .L9
.L13:
	moveq #0,%d0
	move.b (%a2)+,%d0
	move.l %a2,%a0
	lsl.l #8,%d0
	addq.l #1,%a2
	or.b (%a0),%d0
	move.l %d0,-(%sp)
	jbsr wswap
	move.w %d0,(%a3)+
	jbra .L17
.L12:
	moveq #0,%d0
	move.b (%a2)+,%d0
	move.l %a2,%a0
	lsl.l #8,%d0
	or.b (%a0)+,%d0
	lsl.l #8,%d0
	or.b (%a0)+,%d0
	lsl.l #8,%d0
	lea (1,%a0),%a2
	or.b (%a0),%d0
	move.l %d0,-(%sp)
	jbsr bswap
	move.l %d0,(%a3)+
.L17:
	addq.l #4,%sp
.L9:
	addq.l #1,%a4
.L7:
	move.b (%a4),%d0
	jbne .L8
	move.l %d2,%d0
	movm.l -16(%fp),#0x1c04
	unlk %fp
	rts
	.size	unpack, .-unpack
	.ident	"GCC: (GNU) 4.1.1"
