#NO_APP
	.file	"cprintf.c"
	.text
	.align	2
	.globl	putch
	.type	putch, @function
putch:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.b 11(%fp),%d2
	cmp.b #10,%d2
	jbne .L2
	pea 13.w
	jbsr _con_out
	addq.l #4,%sp
.L2:
	move.b %d2,%d0
	ext.w %d0
	move.w %d0,%a2
	move.l %a2,-(%sp)
	jbsr _con_out
	move.l %a2,%d0
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	putch, .-putch
	.globl	__umodsi3
	.globl	__udivsi3
	.align	2
	.globl	cprintf
	.type	cprintf, @function
cprintf:
	link.w %fp,#-16
	movm.l #0x3f3c,-(%sp)
	move.l 8(%fp),%a3
	lea (12,%fp),%a0
	move.l %a0,-4(%fp)
	moveq #0,%d6
	jbra .L82
.L7:
	addq.l #1,%a3
	addq.l #1,%d6
	cmp.b #37,%d0
	jbne .L81
	move.b (%a3),%d7
	cmp.b #45,%d7
	jbne .L10
	addq.l #1,%a3
.L10:
	moveq #0,%d5
.L12:
	move.b (%a3)+,%d2
	move.b %d2,%d0
	ext.w %d0
	move.w %d0,%d1
	ext.l %d1
	move.w #-48,%a0
	add.l %d1,%a0
	moveq #9,%d0
	cmp.l %a0,%d0
	jbcs .L13
	move.l %d5,%d0
	add.l %d5,%d0
	add.l %d0,%d0
	add.l %d5,%d0
	move.l %d0,%a0
	add.l %d0,%a0
	lea -48(%a0,%d1.l),%a0
	move.l %a0,%d5
	jbra .L12
.L13:
	cmp.b #46,%d2
	jbne .L15
	sub.l %a4,%a4
.L17:
	move.b (%a3)+,%d0
	ext.w %d0
	move.w %d0,%d1
	ext.l %d1
	move.w #-48,%a0
	add.l %d1,%a0
	moveq #9,%d2
	cmp.l %a0,%d2
	jbcs .L18
	lea (%a4,%a4.l),%a0
	add.l %a0,%a0
	add.l %a4,%a0
	add.l %a0,%a0
	lea -48(%a0,%d1.l),%a4
	jbra .L17
.L15:
	sub.l %a4,%a4
.L18:
	cmp.b #45,%d7
	jbne .L20
	neg.l %d5
	jbra .L22
.L20:
	cmp.b #48,%d7
	jbeq .L22
	moveq #32,%d7
.L22:
	tst.l %d1
	jbeq .L24
	moveq #104,%d0
	cmp.l %d1,%d0
	jbne .L26
	move.b (%a3)+,%d0
	ext.w %d0
	move.w %d0,%d1
	ext.l %d1
	moveq #0,%d0
	jbra .L28
.L26:
	moveq #108,%d2
	cmp.l %d1,%d2
	jbeq .L29
	moveq #1,%d0
	jbra .L28
.L29:
	move.b (%a3)+,%d0
	ext.w %d0
	move.w %d0,%d1
	ext.l %d1
	moveq #2,%d0
.L28:
	moveq #111,%d2
	cmp.l %d1,%d2
	jbeq .L35
	jblt .L38
	move.b #99,%d2
	cmp.l %d1,%d2
	jbeq .L33
	move.b #100,%d2
	cmp.l %d1,%d2
	jbeq .L34
	move.b #88,%d2
	cmp.l %d1,%d2
	jbne .L31
	jbra .L32
.L38:
	moveq #117,%d2
	cmp.l %d1,%d2
	jbeq .L37
	move.b #120,%d2
	cmp.l %d1,%d2
	jbeq .L32
	moveq #115,%d0
	cmp.l %d1,%d0
	jbne .L31
	jbra .L36
.L34:
	moveq #-10,%d4
	jbra .L39
.L32:
	moveq #4,%d1
	or.l %d1,%d0
	moveq #16,%d4
	jbra .L39
.L35:
	moveq #4,%d2
	or.l %d2,%d0
	moveq #8,%d4
	jbra .L39
.L37:
	moveq #4,%d1
	or.l %d1,%d0
	moveq #10,%d4
.L39:
	moveq #6,%d2
	cmp.l %d0,%d2
	jbcs .L40
	add.l %d0,%d0
	.set .LI47,.+2
	move.w .L47-.LI47.b(%pc,%d0.l),%d0
	jmp %pc@(2,%d0:w)
	.align	2
	.swbeg	&7
.L47:
	.word .L41-.L47
	.word .L46-.L47
	.word .L46-.L47
	.word .L40-.L47
	.word .L44-.L47
	.word .L46-.L47
	.word .L46-.L47
.L40:
	moveq #0,%d0
	jbra .L48
.L41:
	move.l -4(%fp),%d0
	move.l %d0,%d1
	addq.l #4,%d1
	move.l %d1,-4(%fp)
	move.l %d0,%a0
	move.l (%a0),%d0
	ext.l %d0
	jbra .L48
.L44:
	move.l -4(%fp),%d0
	move.l %d0,%d1
	addq.l #4,%d1
	move.l %d1,-4(%fp)
	move.l %d0,%a0
	move.l (%a0),%d0
	and.l #65535,%d0
	jbra .L48
.L46:
	move.l -4(%fp),%d0
	move.l %d0,%d1
	addq.l #4,%d1
	move.l %d1,-4(%fp)
	move.l %d0,%a0
	move.l (%a0),%d0
.L48:
	tst.l %d4
	jbge .L49
	neg.l %d4
	tst.l %d0
	jbge .L49
	neg.l %d0
	move.w #1,%a5
	jbra .L52
.L49:
	sub.l %a5,%a5
.L52:
	move.l %d0,%d2
	clr.b -5(%fp)
	moveq #10,%d3
.L53:
	lea (-16,%fp),%a2
	move.l %d4,-(%sp)
	move.l %d2,-(%sp)
	jbsr __umodsi3
	addq.l #8,%sp
	lea nstring,%a0
	move.b (%a0,%d0.l),(%a2,%d3.l)
	subq.l #1,%d3
	move.l %d4,-(%sp)
	move.l %d2,-(%sp)
	jbsr __udivsi3
	addq.l #8,%sp
	move.l %d0,%d2
	jbne .L53
	cmp.w #0,%a5
	jbeq .L55
	move.b #45,(%a2,%d3.l)
	subq.l #1,%d3
.L55:
	lea 1(%a2,%d3.l),%a2
	jbra .L57
.L36:
	move.l -4(%fp),%d0
	move.l %d0,%d1
	addq.l #4,%d1
	move.l %d1,-4(%fp)
	move.l %d0,%a0
	move.l (%a0),%a2
.L57:
	subq.l #1,%d6
	move.l %a2,-(%sp)
	jbsr strlen
	addq.l #4,%sp
	cmp.w #0,%a4
	jbne .L58
	move.l %d0,%a4
.L58:
	tst.l %d5
	jble .L60
	move.l %d5,%d2
	sub.l %d0,%d2
	jbra .L62
.L63:
	move.b %d7,%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr putch
	addq.l #1,%d6
	subq.l #1,%d2
	addq.l #4,%sp
.L62:
	tst.l %d2
	jbgt .L63
	moveq #0,%d5
	jbra .L78
.L60:
	tst.l %d5
	jbge .L78
	neg.l %d5
	sub.l %d0,%d5
	jbra .L78
.L67:
	subq.l #1,%a4
	addq.l #1,%a2
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr putch
	addq.l #1,%d6
	addq.l #4,%sp
.L78:
	move.b (%a2),%d0
	jbeq .L79
	cmp.w #0,%a4
	jbgt .L67
	jbra .L79
.L70:
	pea 32.w
	jbsr putch
	addq.l #1,%d6
	subq.l #1,%d5
	addq.l #4,%sp
.L79:
	tst.l %d5
	jbgt .L70
	jbra .L82
.L33:
	move.l -4(%fp),%d0
	move.l %d0,%d1
	addq.l #4,%d1
	move.l %d1,-4(%fp)
	move.l %d0,%a0
	move.l (%a0),%d0
	jbra .L81
.L31:
	move.b %d1,%d0
.L81:
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr putch
	addq.l #4,%sp
.L82:
	move.b (%a3),%d0
	jbne .L7
.L24:
	move.l %d6,%d0
	movm.l -56(%fp),#0x3cfc
	unlk %fp
	rts
	.size	cprintf, .-cprintf
	.globl	nstring
	.section	.rodata
	.type	nstring, @object
	.size	nstring, 17
nstring:
	.string	"0123456789ABCDEF"
	.ident	"GCC: (GNU) 4.1.1"
