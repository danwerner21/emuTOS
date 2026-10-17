#NO_APP
	.file	"disasm.c"
	.text
	.align	2
	.globl	pdr
	.type	pdr, @function
pdr:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.w 10(%fp),%d2
	pea 68.w
	lea _con_out,%a2
	jbsr (%a2)
	lea nstring,%a0
	move.b (%a0,%d2.w),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	pdr, .-pdr
	.align	2
	.globl	pdri
	.type	pdri, @function
pdri:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.w 10(%fp),%d2
	pea 40.w
	lea _con_out,%a2
	jbsr (%a2)
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr pdr
	pea 41.w
	jbsr (%a2)
	lea (12,%sp),%sp
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	pdri, .-pdri
	.align	2
	.globl	inf14
	.type	inf14, @function
inf14:
	link.w %fp,#0
	move.w instr,%d0
	moveq #7,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr pdr
	addq.l #4,%sp
	unlk %fp
	rts
	.size	inf14, .-inf14
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"\n** illegal size field **\n"
.LC1:
	.string	"%s"
	.text
	.align	2
	.globl	badsize
	.type	badsize, @function
badsize:
	link.w %fp,#0
	pea .LC0
	pea .LC1
	jbsr cprintf
	addq.l #8,%sp
	unlk %fp
	rts
	.size	badsize, .-badsize
	.section	.rodata.str1.1
.LC2:
	.string	"%02lx"
	.text
	.align	2
	.globl	hexbzs
	.type	hexbzs, @function
hexbzs:
	link.w %fp,#0
	move.b 11(%fp),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	pea .LC2
	jbsr cprintf
	addq.l #8,%sp
	unlk %fp
	rts
	.size	hexbzs, .-hexbzs
	.section	.rodata.str1.1
.LC3:
	.string	"%04lx"
	.text
	.align	2
	.globl	hexwzs
	.type	hexwzs, @function
hexwzs:
	link.w %fp,#0
	move.w 10(%fp),%a0
	move.l %a0,-(%sp)
	pea .LC3
	jbsr cprintf
	addq.l #8,%sp
	unlk %fp
	rts
	.size	hexwzs, .-hexwzs
	.align	2
	.globl	prdisp
	.type	prdisp, @function
prdisp:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.l sdot,%a0
	move.w (%a0)+,%d2
	move.l %a0,sdot
	addq.l #2,dotinc
	pea 36.w
	jbsr _con_out
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr hexwzs
	addq.l #8,%sp
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	prdisp, .-prdisp
	.section	.rodata.str1.1
.LC4:
	.string	"%08lx"
	.text
	.align	2
	.globl	hexlzs
	.type	hexlzs, @function
hexlzs:
	link.w %fp,#0
	move.l 8(%fp),-(%sp)
	pea .LC4
	jbsr cprintf
	addq.l #8,%sp
	unlk %fp
	rts
	.size	hexlzs, .-hexlzs
	.section	.rodata.str1.1
.LC5:
	.string	"#$"
	.text
	.align	2
	.globl	primm
	.type	primm, @function
primm:
	link.w %fp,#0
	move.l %d2,-(%sp)
	cmp.w #2,10(%fp)
	jbeq .L18
	moveq #0,%d0
	jbra .L20
.L18:
	move.l sdot,%a0
	move.w (%a0)+,%d0
	ext.l %d0
	swap %d0
	clr.w %d0
	move.l %a0,sdot
	addq.l #2,dotinc
.L20:
	move.l sdot,%a0
	move.l %d0,%d2
	or.w (%a0)+,%d2
	move.l %a0,sdot
	addq.l #2,dotinc
	pea .LC5
	pea .LC1
	jbsr cprintf
	move.l %d2,-(%sp)
	jbsr hexlzs
	lea (12,%sp),%sp
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	primm, .-primm
	.align	2
	.globl	inf21
	.type	inf21, @function
inf21:
	link.w %fp,#0
	pea 1.w
	jbsr primm
	addq.l #4,%sp
	unlk %fp
	rts
	.size	inf21, .-inf21
	.align	2
	.globl	inf12
	.type	inf12, @function
inf12:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.w instr,%d0
	moveq #7,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr pdr
	pea 44.w
	jbsr _con_out
	move.l sdot,%a0
	move.w (%a0),%a1
	lea (2,%a0),%a2
	move.l %a2,sdot
	addq.l #2,dotinc
	pea (%a1,%a0.l)
	jbsr hexlzs
	lea (12,%sp),%sp
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	inf12, .-inf12
	.section	.rodata.str1.1
.LC6:
	.string	"SP"
	.text
	.align	2
	.globl	par
	.type	par, @function
par:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.w 10(%fp),%d2
	cmp.w #7,%d2
	jbne .L27
	pea .LC6
	pea .LC1
	jbsr cprintf
	jbra .L31
.L27:
	pea 65.w
	lea _con_out,%a2
	jbsr (%a2)
	lea nstring,%a0
	move.b (%a0,%d2.w),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr (%a2)
.L31:
	addq.l #8,%sp
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	par, .-par
	.align	2
	.globl	prtreg
	.type	prtreg, @function
prtreg:
	link.w %fp,#0
	move.w 10(%fp),%d0
	cmp.w #7,%d0
	jble .L33
	subq.w #8,%d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr par
	jbra .L37
.L33:
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr pdr
.L37:
	addq.l #4,%sp
	unlk %fp
	rts
	.size	prtreg, .-prtreg
	.section	.rodata.str1.1
.LC7:
	.string	"PC,"
.LC8:
	.string	".l"
	.text
	.align	2
	.globl	prindex
	.type	prindex, @function
prindex:
	link.w %fp,#0
	movm.l #0x3020,-(%sp)
	move.w 10(%fp),%d3
	move.l sdot,%a0
	move.w (%a0)+,%d2
	move.l %a0,sdot
	addq.l #2,dotinc
	pea 36.w
	lea _con_out,%a2
	jbsr (%a2)
	move.b %d2,%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr hexbzs
	pea 40.w
	jbsr (%a2)
	lea (12,%sp),%sp
	cmp.w #16,%d3
	jbne .L39
	pea .LC7
	pea .LC1
	jbsr cprintf
	jbra .L45
.L39:
	move.w %d3,%a0
	move.l %a0,-(%sp)
	jbsr par
	pea 44.w
	jbsr (%a2)
.L45:
	addq.l #8,%sp
	move.w %d2,%d0
	moveq #12,%d1
	asr.w %d1,%d0
	moveq #15,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr prtreg
	addq.l #4,%sp
	btst #11,%d2
	jbeq .L42
	pea .LC8
	pea .LC1
	jbsr cprintf
	addq.l #8,%sp
.L42:
	pea 41.w
	jbsr _con_out
	addq.l #4,%sp
	movm.l -12(%fp),#0x40c
	unlk %fp
	rts
	.size	prindex, .-prindex
	.align	2
	.globl	inf22
	.type	inf22, @function
inf22:
	link.w %fp,#0
	move.w instr,%d0
	moveq #15,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtreg
	addq.l #4,%sp
	unlk %fp
	rts
	.size	inf22, .-inf22
	.align	2
	.globl	inf13
	.type	inf13, @function
inf13:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.w instr,%d0
	move.l %d0,%d1
	and.l #3584,%d1
	moveq #9,%d2
	lsr.l %d2,%d1
	move.w %d0,%d2
	and.w #7,%d2
	and.w #248,%d0
	cmp.w #72,%d0
	jbne .L49
	addq.w #8,%d1
	jbra .L54
.L49:
	cmp.w #136,%d0
	jbne .L51
.L54:
	addq.w #8,%d2
.L51:
	move.w %d1,%a0
	move.l %a0,-(%sp)
	lea prtreg,%a2
	jbsr (%a2)
	pea 44.w
	jbsr _con_out
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	inf13, .-inf13
	.align	2
	.globl	inf6
	.type	inf6, @function
inf6:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.w instr,%d0
	ext.l %d0
	move.l %d0,%d1
	and.l #3584,%d1
	moveq #9,%d2
	asr.l %d2,%d1
	move.w %d1,%d2
	btst #5,%d0
	jbeq .L56
	move.w %d1,%a0
	move.l %a0,-(%sp)
	jbsr pdr
	addq.l #4,%sp
	jbra .L58
.L56:
	tst.w %d1
	jbne .L59
	moveq #8,%d2
.L59:
	pea 35.w
	jbsr _con_out
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr hexbzs
	addq.l #8,%sp
.L58:
	pea 44.w
	jbsr _con_out
	move.w instr,%d0
	moveq #7,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtreg
	addq.l #8,%sp
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	inf6, .-inf6
	.align	2
	.globl	pari
	.type	pari, @function
pari:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.w 10(%fp),%d2
	pea 40.w
	lea _con_out,%a2
	jbsr (%a2)
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr par
	pea 41.w
	jbsr (%a2)
	lea (12,%sp),%sp
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	pari, .-pari
	.align	2
	.globl	paripi
	.type	paripi, @function
paripi:
	link.w %fp,#0
	move.w 10(%fp),%a0
	move.l %a0,-(%sp)
	jbsr pari
	pea 43.w
	jbsr _con_out
	addq.l #8,%sp
	unlk %fp
	rts
	.size	paripi, .-paripi
	.align	2
	.globl	inf11
	.type	inf11, @function
inf11:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.w instr,%d0
	moveq #7,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	lea paripi,%a2
	jbsr (%a2)
	pea 44.w
	jbsr _con_out
	move.b instr,%d0
	lsr.l #1,%d0
	moveq #7,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	inf11, .-inf11
	.align	2
	.globl	paripd
	.type	paripd, @function
paripd:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.w 10(%fp),%d2
	pea 45.w
	jbsr _con_out
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr pari
	addq.l #8,%sp
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	paripd, .-paripd
	.section	.rodata.str1.1
.LC9:
	.string	"(PC)"
	.text
	.align	2
	.globl	prtop
	.type	prtop, @function
prtop:
	link.w %fp,#0
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.w 10(%fp),%d0
	move.w 14(%fp),%d1
	move.w %d0,%d2
	and.w #7,%d2
	moveq #56,%d3
	and.l %d3,%d0
	asr.l #3,%d0
	cmp.w #7,%d0
	jbhi .L89
	add.l %d0,%d0
	.set .LI80,.+2
	move.w .L80-.LI80.b(%pc,%d0.l),%d0
	jmp %pc@(2,%d0:w)
	.align	2
	.swbeg	&8
.L80:
	.word .L72-.L80
	.word .L73-.L80
	.word .L93-.L80
	.word .L75-.L80
	.word .L76-.L80
	.word .L77-.L80
	.word .L78-.L80
	.word .L79-.L80
.L72:
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr pdr
	jbra .L90
.L73:
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr par
	jbra .L90
.L75:
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr paripi
	jbra .L90
.L76:
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr paripd
	jbra .L90
.L77:
	jbsr prdisp
.L93:
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr pari
	jbra .L90
.L78:
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbra .L92
.L79:
	cmp.w #4,%d2
	jbhi .L89
	moveq #0,%d0
	move.w %d2,%d0
	add.l %d0,%d0
	.set .LI86,.+2
	move.w .L86-.LI86.b(%pc,%d0.l),%d0
	jmp %pc@(2,%d0:w)
	.align	2
	.swbeg	&5
.L86:
	.word .L81-.L86
	.word .L82-.L86
	.word .L83-.L86
	.word .L84-.L86
	.word .L85-.L86
.L81:
	move.l sdot,%d1
	move.l %d1,%a0
	move.w (%a0),%d0
	ext.l %d0
	tst.w %d0
	jbge .L87
	or.l #-65536,%d0
.L87:
	addq.l #2,%d1
	move.l %d1,sdot
	addq.l #2,dotinc
	move.l %d0,-(%sp)
	jbsr hexlzs
	jbra .L90
.L82:
	move.l sdot,%a0
	move.w (%a0)+,%d2
	ext.l %d2
	swap %d2
	clr.w %d2
	moveq #0,%d0
	move.w (%a0)+,%d0
	add.l %d0,%d2
	move.l %a0,sdot
	addq.l #4,dotinc
	pea 36.w
	jbsr _con_out
	move.l %d2,-(%sp)
	jbsr hexlzs
	jbra .L91
.L83:
	jbsr prdisp
	pea .LC9
	pea .LC1
	jbsr cprintf
.L91:
	addq.l #8,%sp
	jbra .L89
.L84:
	pea 16.w
.L92:
	jbsr prindex
	jbra .L90
.L85:
	move.w %d1,%a0
	move.l %a0,-(%sp)
	jbsr primm
.L90:
	addq.l #4,%sp
.L89:
	move.l -8(%fp),%d2
	move.l -4(%fp),%d3
	unlk %fp
	rts
	.size	prtop, .-prtop
	.align	2
	.globl	inf25
	.type	inf25, @function
inf25:
	link.w %fp,#0
	movm.l #0x3800,-(%sp)
	move.w instr,%d3
	move.l sdot,%a0
	move.w (%a0)+,%a1
	move.l %a0,sdot
	addq.l #2,dotinc
	move.l %a1,%d1
	move.l %a1,%d0
	and.l #61440,%d0
	move.l %d0,%d2
	moveq #12,%d4
	lsr.l %d4,%d2
	btst #11,%d1
	jbeq .L95
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr prtreg
	pea 44.w
	jbsr _con_out
	addq.l #8,%sp
.L95:
	moveq #63,%d0
	not.b %d0
	and.l %d3,%d0
	move.l %d0,-(%sp)
	move.w instr,%d1
	moveq #63,%d4
	and.l %d4,%d1
	move.l %d1,-(%sp)
	jbsr prtop
	addq.l #8,%sp
	btst #3,instr
	jbne .L99
	pea 44.w
	jbsr _con_out
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr prtreg
	addq.l #8,%sp
.L99:
	movm.l -12(%fp),#0x1c
	unlk %fp
	rts
	.size	inf25, .-inf25
	.align	2
	.globl	inf16
	.type	inf16, @function
inf16:
	link.w %fp,#0
	movm.l #0x2030,-(%sp)
	move.w instr,%d0
	and.w #12288,%d0
	cmp.w #4096,%d0
	jbne .L101
	clr.w %d0
	jbra .L103
.L101:
	cmp.w #12288,%d0
	jbeq .L109
	cmp.w #8192,%d0
	jbne .L106
	moveq #2,%d0
	jbra .L103
.L106:
	jbsr badsize
.L109:
	moveq #1,%d0
.L103:
	move.w %d0,%a2
	move.l %a2,-(%sp)
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	lea prtop,%a3
	jbsr (%a3)
	pea 44.w
	jbsr _con_out
	move.w instr,%d0
	ext.l %d0
	move.l %a2,-(%sp)
	move.l %d0,%d1
	and.l #3584,%d1
	moveq #9,%d2
	asr.l %d2,%d1
	and.l #448,%d0
	asr.l #3,%d0
	or.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr (%a3)
	lea (20,%sp),%sp
	movm.l -12(%fp),#0xc04
	unlk %fp
	rts
	.size	inf16, .-inf16
	.align	2
	.globl	inf10
	.type	inf10, @function
inf10:
	link.w %fp,#0
	move.w instr,%d0
	ext.l %d0
	btst #8,%d0
	jbeq .L111
	moveq #9,%d1
	lsr.l %d1,%d0
	move.b #7,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr pdr
	jbra .L115
.L111:
	pea 1.w
	jbsr primm
.L115:
	move.l #44,(%sp)
	jbsr _con_out
	pea 1.w
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
	lea (12,%sp),%sp
	unlk %fp
	rts
	.size	inf10, .-inf10
	.align	2
	.globl	inf9
	.type	inf9, @function
inf9:
	link.w %fp,#0
	pea 1.w
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
	pea 44.w
	jbsr _con_out
	move.b instr,%d0
	lsr.l #1,%d0
	moveq #7,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr pdr
	lea (16,%sp),%sp
	unlk %fp
	rts
	.size	inf9, .-inf9
	.align	2
	.globl	inf7
	.type	inf7, @function
inf7:
	link.w %fp,#0
	pea 1.w
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
	addq.l #8,%sp
	unlk %fp
	rts
	.size	inf7, .-inf7
	.align	2
	.globl	inf2
	.type	inf2, @function
inf2:
	link.w %fp,#0
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.w instr,%d1
	ext.l %d1
	move.l %d1,%d0
	and.l #3584,%d0
	move.l %d0,%d3
	moveq #9,%d2
	lsr.l %d2,%d3
	moveq #63,%d0
	not.b %d0
	and.l %d1,%d0
	cmp.l #192,%d0
	jbne .L121
	move.l %d1,%d0
	and.l #448,%d0
	cmp.l #448,%d0
	sne %d0
	move.b %d0,%d2
	ext.w %d2
	addq.w #2,%d2
	addq.w #8,%d3
	jbra .L126
.L121:
	move.l %d0,%d2
	lsr.l #6,%d2
.L126:
	cmp.w #7,%d3
	jbgt .L127
	btst #8,%d1
	jbne .L129
.L127:
	move.w %d2,%a0
	move.l %a0,-(%sp)
	moveq #63,%d0
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
	pea 44.w
	jbsr _con_out
	move.w %d3,%a0
	move.l %a0,-(%sp)
	jbsr prtreg
	jbra .L132
.L129:
	move.w %d3,%a0
	move.l %a0,-(%sp)
	jbsr prtreg
	pea 44.w
	jbsr _con_out
	move.w %d2,%a0
	move.l %a0,-(%sp)
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
.L132:
	lea (16,%sp),%sp
	move.l -8(%fp),%d2
	move.l -4(%fp),%d3
	unlk %fp
	rts
	.size	inf2, .-inf2
	.align	2
	.globl	inf1
	.type	inf1, @function
inf1:
	link.w %fp,#0
	movm.l #0x3030,-(%sp)
	move.w instr,%d0
	ext.l %d0
	move.l %d0,%d2
	and.l #3584,%d2
	moveq #7,%d1
	and.l %d0,%d1
	lea _con_out,%a3
	moveq #9,%d3
	lsr.l %d3,%d2
	btst #3,%d0
	jbeq .L134
	move.l %d1,-(%sp)
	lea paripd,%a2
	jbra .L138
.L134:
	move.l %d1,-(%sp)
	lea pdr,%a2
.L138:
	jbsr (%a2)
	pea 44.w
	jbsr (%a3)
	move.l %d2,-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	movm.l -16(%fp),#0xc0c
	unlk %fp
	rts
	.size	inf1, .-inf1
	.align	2
	.globl	inf19
	.type	inf19, @function
inf19:
	link.w %fp,#0
	movm.l #0x2030,-(%sp)
	move.w instr,%d0
	move.w %d0,%d2
	and.w #384,%d2
	lea hexwzs,%a2
	lea pari,%a3
	cmp.w #384,%d2
	jbne .L140
	moveq #9,%d1
	lsr.l %d1,%d0
	move.b #7,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr prtreg
	pea 44.w
	jbsr _con_out
	move.l sdot,%a0
	move.w (%a0),%a0
	move.l %a0,-(%sp)
	jbsr (%a2)
	move.w instr,%d0
	moveq #7,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr (%a3)
	lea (16,%sp),%sp
	jbra .L142
.L140:
	move.l sdot,%a0
	move.w (%a0),%a0
	move.l %a0,-(%sp)
	jbsr (%a2)
	move.w instr,%d0
	moveq #7,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr (%a3)
	addq.l #8,%sp
	cmp.w #256,%d2
	jbne .L142
	pea 44.w
	jbsr _con_out
	move.b instr,%d0
	lsr.l #1,%d0
	moveq #7,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr prtreg
	addq.l #8,%sp
.L142:
	addq.l #2,sdot
	addq.l #2,dotinc
	movm.l -12(%fp),#0xc04
	unlk %fp
	rts
	.size	inf19, .-inf19
	.section	.rodata.str1.1
.LC10:
	.string	"A7"
	.text
	.align	2
	.globl	putrlist
	.type	putrlist, @function
putrlist:
	link.w %fp,#0
	movm.l #0x2030,-(%sp)
	move.w 14(%fp),%d2
	move.l 8(%fp),%a3
	moveq #-1,%d1
	move.w #-1,%a2
.L146:
	move.w %d2,%d0
	and.w (%a3)+,%d0
	jbeq .L147
	tst.w %d1
	jbne .L149
	pea 47.w
	jbsr _con_out
	addq.l #4,%sp
	jbra .L151
.L149:
	cmp.w #1,%d1
	jbeq .L152
.L151:
	pea 1(%a2)
	jbsr prtreg
	pea 45.w
	jbsr _con_out
	moveq #1,%d1
	addq.l #8,%sp
	jbra .L152
.L147:
	cmp.w #1,%d1
	jbne .L152
	move.l %a2,-(%sp)
	jbsr prtreg
	clr.w %d1
	addq.l #4,%sp
.L152:
	addq.l #1,%a2
	moveq #15,%d0
	cmp.l %a2,%d0
	jbne .L146
	cmp.w #1,%d1
	jbne .L157
	pea .LC10
	pea .LC1
	jbsr cprintf
	addq.l #8,%sp
.L157:
	movm.l -12(%fp),#0xc04
	unlk %fp
	rts
	.size	putrlist, .-putrlist
	.align	2
	.globl	inf18
	.type	inf18, @function
inf18:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.l sdot,%a0
	move.w (%a0)+,%d2
	move.l %a0,sdot
	addq.l #2,dotinc
	move.w instr,%d0
	ext.l %d0
	btst #10,%d0
	jbeq .L161
	pea 1.w
	moveq #63,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr prtop
	pea 44.w
	jbsr _con_out
	move.w %d2,%a0
	move.l %a0,-(%sp)
	pea regmsk1
	jbsr putrlist
	lea (20,%sp),%sp
	jbra .L167
.L161:
	moveq #56,%d1
	and.l %d1,%d0
	move.w %d2,%a0
	lea putrlist,%a1
	move.b #32,%d1
	cmp.l %d0,%d1
	jbne .L164
	move.l %a0,-(%sp)
	pea regmsk0
	jbra .L168
.L164:
	move.l %a0,-(%sp)
	pea regmsk1
.L168:
	jbsr (%a1)
	addq.w #4,%sp
	move.l #44,(%sp)
	jbsr _con_out
	pea 1.w
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
	lea (12,%sp),%sp
.L167:
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	inf18, .-inf18
	.section	.rodata.str1.1
.LC11:
	.string	"SFC"
.LC12:
	.string	"DFC"
.LC13:
	.string	"CACR"
.LC14:
	.string	"USP"
.LC15:
	.string	"VBR"
.LC16:
	.string	"CAAR"
.LC17:
	.string	"MSP"
.LC18:
	.string	"ISP"
.LC19:
	.string	"*illegal Control Register"
	.text
	.align	2
	.globl	inf24
	.type	inf24, @function
inf24:
	link.w %fp,#0
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.l sdot,%a0
	move.w (%a0)+,%d2
	move.l %a0,sdot
	addq.l #2,dotinc
	move.l %d2,%d0
	and.l #61440,%d0
	move.l %d0,%d3
	moveq #12,%d1
	lsr.l %d1,%d3
	btst #0,instr+1
	jbeq .L170
	move.w %d3,%a0
	move.l %a0,-(%sp)
	jbsr prtreg
	pea 44.w
	jbsr _con_out
	addq.l #8,%sp
.L170:
	move.w %d2,%d0
	and.w #4095,%d0
	cmp.w #2048,%d0
	jbeq .L176
	jbgt .L181
	cmp.w #1,%d0
	jbeq .L174
	cmp.w #2,%d0
	jbeq .L175
	tst.w %d0
	jbeq .L173
	jbra .L172
.L181:
	cmp.w #2050,%d0
	jbeq .L178
	jblt .L177
	cmp.w #2051,%d0
	jbeq .L179
	cmp.w #2052,%d0
	jbne .L172
	jbra .L180
.L173:
	pea .LC11
	jbra .L186
.L174:
	pea .LC12
	jbra .L186
.L175:
	pea .LC13
	jbra .L186
.L176:
	pea .LC14
	jbra .L186
.L177:
	pea .LC15
	jbra .L186
.L178:
	pea .LC16
	jbra .L186
.L179:
	pea .LC17
	jbra .L186
.L180:
	pea .LC18
	jbra .L186
.L172:
	pea .LC19
.L186:
	pea .LC1
	jbsr cprintf
	addq.l #8,%sp
	btst #0,instr+1
	jbne .L185
	pea 44.w
	jbsr _con_out
	move.w %d3,%a0
	move.l %a0,-(%sp)
	jbsr prtreg
	addq.l #8,%sp
.L185:
	move.l -8(%fp),%d2
	move.l -4(%fp),%d3
	unlk %fp
	rts
	.size	inf24, .-inf24
	.align	2
	.globl	inf23
	.type	inf23, @function
inf23:
	link.w %fp,#0
	pea .LC5
	pea .LC1
	jbsr cprintf
	move.b instr+1,%d0
	moveq #15,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr hexbzs
	lea (12,%sp),%sp
	unlk %fp
	rts
	.size	inf23, .-inf23
	.align	2
	.globl	inf20
	.type	inf20, @function
inf20:
	link.w %fp,#0
	pea .LC5
	pea .LC1
	jbsr cprintf
	move.b instr+1,%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbsr hexbzs
	pea 44.w
	jbsr _con_out
	move.b instr,%d0
	lsr.l #1,%d0
	moveq #7,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr prtreg
	lea (20,%sp),%sp
	unlk %fp
	rts
	.size	inf20, .-inf20
	.section	.rodata.str1.1
.LC20:
	.string	"USP,"
.LC21:
	.string	",USP"
	.text
	.align	2
	.globl	inf17
	.type	inf17, @function
inf17:
	link.w %fp,#0
	movm.l #0x2030,-(%sp)
	move.w instr,%d0
	lea cprintf,%a3
	moveq #7,%d2
	and.l %d0,%d2
	lea par,%a2
	btst #3,%d0
	jbeq .L192
	pea .LC20
	pea .LC1
	jbsr (%a3)
	move.l %d2,-(%sp)
	jbsr (%a2)
	jbra .L196
.L192:
	move.l %d2,-(%sp)
	jbsr (%a2)
	pea .LC21
	pea .LC1
	jbsr (%a3)
.L196:
	lea (12,%sp),%sp
	movm.l -12(%fp),#0xc04
	unlk %fp
	rts
	.size	inf17, .-inf17
	.section	.rodata.str1.1
.LC22:
	.string	",#$"
	.text
	.align	2
	.globl	inf15
	.type	inf15, @function
inf15:
	link.w %fp,#0
	move.w instr,%d0
	moveq #7,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr par
	pea .LC22
	pea .LC1
	jbsr cprintf
	move.l sdot,%a0
	move.w (%a0),%a0
	move.l %a0,-(%sp)
	jbsr hexwzs
	addq.l #2,sdot
	addq.l #2,dotinc
	lea (16,%sp),%sp
	unlk %fp
	rts
	.size	inf15, .-inf15
	.section	.rodata.str1.1
.LC23:
	.string	"$"
	.text
	.align	2
	.globl	inf8
	.type	inf8, @function
inf8:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.w instr,%d0
	tst.b %d0
	jbne .L200
	move.l sdot,%d0
	move.l %d0,%a1
	move.w (%a1),%a0
	lea (%a0,%d0.l),%a2
	addq.l #2,%d0
	move.l %d0,sdot
	addq.l #2,dotinc
	jbra .L202
.L200:
	cmp.b #-1,%d0
	jbne .L203
	move.l sdot,%d0
	move.l %d0,%a2
	move.l %d0,%a0
	add.l (%a0),%a2
	addq.l #4,%d0
	move.l %d0,sdot
	addq.l #4,dotinc
	jbra .L202
.L203:
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,%a2
	add.l sdot,%a2
.L202:
	pea .LC23
	pea .LC1
	jbsr cprintf
	move.l %a2,-(%sp)
	jbsr hexlzs
	lea (12,%sp),%sp
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	inf8, .-inf8
	.section	.rodata.str1.1
.LC24:
	.string	"SR,"
.LC25:
	.string	"CCR,"
.LC26:
	.string	",CCR"
.LC27:
	.string	",SR"
	.text
	.align	2
	.globl	inf5
	.type	inf5, @function
inf5:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.w instr,%d0
	move.w %d0,%d2
	and.w #1536,%d2
	jbne .L207
	pea .LC24
	jbra .L217
.L207:
	cmp.w #512,%d2
	jbne .L210
	pea .LC25
.L217:
	pea .LC1
	jbsr cprintf
	addq.w #4,%sp
	move.l #1,(%sp)
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
	addq.l #8,%sp
	jbra .L212
.L210:
	pea 1.w
	moveq #63,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr prtop
	addq.l #8,%sp
	cmp.w #1024,%d2
	jbne .L212
	pea .LC26
	jbra .L218
.L212:
	cmp.w #1536,%d2
	jbne .L216
	pea .LC27
.L218:
	pea .LC1
	jbsr cprintf
	addq.l #8,%sp
.L216:
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	inf5, .-inf5
	.align	2
	.globl	inf4
	.type	inf4, @function
inf4:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.w instr,%d0
	and.l #3584,%d0
	moveq #9,%d1
	asr.l %d1,%d0
	move.w %d0,%d2
	jbne .L220
	moveq #8,%d2
.L220:
	pea .LC5
	pea .LC1
	jbsr cprintf
	move.w %d2,%a0
	move.l %a0,-(%sp)
	jbsr hexbzs
	pea 44.w
	jbsr _con_out
	pea 1.w
	move.w instr,%d0
	moveq #63,%d1
	and.l %d1,%d0
	move.l %d0,-(%sp)
	jbsr prtop
	lea (24,%sp),%sp
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	inf4, .-inf4
	.section	.rodata.str1.1
.LC28:
	.string	"SR"
.LC29:
	.string	"CCR"
	.text
	.align	2
	.globl	inf3
	.type	inf3, @function
inf3:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.w instr,%d2
	moveq #63,%d0
	not.b %d0
	and.l %d0,%d2
	lsr.l #6,%d2
	move.l %d2,-(%sp)
	jbsr primm
	pea 44.w
	jbsr _con_out
	move.w instr,%d0
	addq.l #8,%sp
	cmp.w #572,%d0
	jbeq .L225
	jbgt .L227
	cmp.w #60,%d0
	jbeq .L225
	cmp.w #124,%d0
	jbne .L224
	jbra .L226
.L227:
	cmp.w #2620,%d0
	jbeq .L225
	cmp.w #2684,%d0
	jbeq .L226
	cmp.w #636,%d0
	jbne .L224
.L226:
	pea .LC28
	jbra .L231
.L225:
	pea .LC29
.L231:
	pea .LC1
	jbsr cprintf
	jbra .L230
.L224:
	move.l %d2,-(%sp)
	moveq #63,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr prtop
.L230:
	addq.l #8,%sp
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	inf3, .-inf3
	.section	.rodata.str1.1
.LC30:
	.string	"illegal instruction format #\n"
	.text
	.align	2
	.globl	noin
	.type	noin, @function
noin:
	link.w %fp,#0
	pea .LC30
	pea .LC1
	jbsr cprintf
	addq.l #8,%sp
	unlk %fp
	rts
	.size	noin, .-noin
	.section	.rodata.str1.1
.LC31:
	.string	"  "
	.text
	.align	2
	.globl	pinstr
	.type	pinstr, @function
pinstr:
	link.w %fp,#0
	movm.l #0x2030,-(%sp)
	move.l 8(%fp),%d0
	move.l %d0,dot
	move.l %d0,%d1
	addq.l #2,%d1
	move.l %d1,sdot
	moveq #2,%d1
	move.l %d1,dotinc
	move.l %d0,%a0
	move.w (%a0),%d2
	move.w %d2,instr
	lea optab,%a3
	lea (%a3,%a3.l),%a0
.L235:
	move.l #optab,%d1
	neg.l %d1
	move.w %d2,%d0
	and.w (%a0,%d1.l),%d0
	cmp.w 2(%a0,%d1.l),%d0
	jbeq .L236
	lea (12,%a3),%a3
	lea (12,%a0),%a0
	jbra .L235
.L236:
	move.l 8(%a3),-(%sp)
	pea .LC1
	lea cprintf,%a2
	jbsr (%a2)
	pea .LC31
	pea .LC1
	jbsr (%a2)
	move.w 4(%a3),%d0
	lea (16,%sp),%sp
	cmp.w #28,%d0
	jbhi .L238
	tst.w %d0
	jbeq .L240
	cmp.w #25,%d0
	jbhi .L240
	and.l #65535,%d0
	add.l %d0,%d0
	.set .LI268,.+2
	move.w .L268-.LI268.b(%pc,%d0.l),%d0
	jmp %pc@(2,%d0:w)
	.align	2
	.swbeg	&26
.L268:
	.word .L242-.L268
	.word .L243-.L268
	.word .L244-.L268
	.word .L245-.L268
	.word .L246-.L268
	.word .L247-.L268
	.word .L248-.L268
	.word .L249-.L268
	.word .L250-.L268
	.word .L251-.L268
	.word .L252-.L268
	.word .L253-.L268
	.word .L254-.L268
	.word .L255-.L268
	.word .L256-.L268
	.word .L257-.L268
	.word .L258-.L268
	.word .L259-.L268
	.word .L260-.L268
	.word .L261-.L268
	.word .L262-.L268
	.word .L263-.L268
	.word .L264-.L268
	.word .L265-.L268
	.word .L266-.L268
	.word .L267-.L268
.L242:
	jbsr noin
	jbra .L240
.L243:
	jbsr inf1
	jbra .L240
.L244:
	jbsr inf2
	jbra .L240
.L245:
	jbsr inf3
	jbra .L240
.L246:
	jbsr inf4
	jbra .L240
.L247:
	jbsr inf5
	jbra .L240
.L248:
	jbsr inf6
	jbra .L240
.L249:
	jbsr inf7
	jbra .L240
.L250:
	jbsr inf8
	jbra .L240
.L251:
	jbsr inf9
	jbra .L240
.L252:
	jbsr inf10
	jbra .L240
.L253:
	jbsr inf11
	jbra .L240
.L254:
	jbsr inf12
	jbra .L240
.L255:
	jbsr inf13
	jbra .L240
.L256:
	jbsr inf14
	jbra .L240
.L257:
	jbsr inf15
	jbra .L240
.L258:
	jbsr inf16
	jbra .L240
.L259:
	jbsr inf17
	jbra .L240
.L260:
	jbsr inf18
	jbra .L240
.L261:
	jbsr inf19
	jbra .L240
.L262:
	jbsr inf20
	jbra .L240
.L263:
	jbsr inf21
	jbra .L240
.L264:
	jbsr inf22
	jbra .L240
.L265:
	jbsr inf23
	jbra .L240
.L266:
	jbsr inf24
	jbra .L240
.L267:
	jbsr inf25
	jbra .L240
.L238:
	pea 63.w
	jbsr _con_out
	addq.l #4,%sp
.L240:
	move.l dotinc,%d0
	movm.l -12(%fp),#0xc04
	unlk %fp
	rts
	.size	pinstr, .-pinstr
	.globl	optab
	.section	.rodata.str1.1
.LC32:
	.string	"andi.b"
.LC33:
	.string	"andi.w"
.LC34:
	.string	"eori.b"
.LC35:
	.string	"eori.w"
.LC36:
	.string	"illegal"
.LC37:
	.string	"nop"
.LC38:
	.string	"ori.b"
.LC39:
	.string	"ori.w"
.LC40:
	.string	"reset"
.LC41:
	.string	"rtd"
.LC42:
	.string	"rte"
.LC43:
	.string	"rtr"
.LC44:
	.string	"rts"
.LC45:
	.string	"stop"
.LC46:
	.string	"trapv"
.LC47:
	.string	"movec"
.LC48:
	.string	"dbt"
.LC49:
	.string	"dbra"
.LC50:
	.string	"dbhi"
.LC51:
	.string	"dbls"
.LC52:
	.string	"dbcc"
.LC53:
	.string	"dbcs"
.LC54:
	.string	"dbne"
.LC55:
	.string	"dbeq"
.LC56:
	.string	"dbvc"
.LC57:
	.string	"dbvs"
.LC58:
	.string	"dbpl"
.LC59:
	.string	"dbmi"
.LC60:
	.string	"dbge"
.LC61:
	.string	"dblt"
.LC62:
	.string	"dbgt"
.LC63:
	.string	"dble"
.LC64:
	.string	"ext.w"
.LC65:
	.string	"ext.l"
.LC66:
	.string	"link"
.LC67:
	.string	"move.l"
.LC68:
	.string	"swap"
.LC69:
	.string	"unlk"
.LC70:
	.string	"trap"
.LC71:
	.string	"addi.b"
.LC72:
	.string	"addi.w"
.LC73:
	.string	"addi.l"
.LC74:
	.string	"andi.l"
.LC75:
	.string	"asl"
.LC76:
	.string	"asr"
.LC77:
	.string	"bchg"
.LC78:
	.string	"bclr"
.LC79:
	.string	"bset"
.LC80:
	.string	"btst"
.LC81:
	.string	"clr.b"
.LC82:
	.string	"clr.w"
.LC83:
	.string	"clr.l"
.LC84:
	.string	"cmpi.b"
.LC85:
	.string	"cmpi.w"
.LC86:
	.string	"cmpi.l"
.LC87:
	.string	"eori.l"
.LC88:
	.string	"jmp"
.LC89:
	.string	"jsr"
.LC90:
	.string	"lsl"
.LC91:
	.string	"lsr"
.LC92:
	.string	"move.w"
.LC93:
	.string	"movem.w"
.LC94:
	.string	"movem.l"
.LC95:
	.string	"moves.b"
.LC96:
	.string	"moves.w"
.LC97:
	.string	"moves.l"
.LC98:
	.string	"nbcd"
.LC99:
	.string	"neg.b"
.LC100:
	.string	"neg.w"
.LC101:
	.string	"neg.l"
.LC102:
	.string	"negx.b"
.LC103:
	.string	"negx.w"
.LC104:
	.string	"negx.l"
.LC105:
	.string	"not.b"
.LC106:
	.string	"not.w"
.LC107:
	.string	"not.l"
.LC108:
	.string	"ori.l"
.LC109:
	.string	"pea"
.LC110:
	.string	"rol"
.LC111:
	.string	"ror"
.LC112:
	.string	"roxl"
.LC113:
	.string	"roxr"
.LC114:
	.string	"st"
.LC115:
	.string	"sf"
.LC116:
	.string	"shi"
.LC117:
	.string	"sls"
.LC118:
	.string	"scc"
.LC119:
	.string	"scs"
.LC120:
	.string	"sne"
.LC121:
	.string	"seq"
.LC122:
	.string	"svc"
.LC123:
	.string	"svs"
.LC124:
	.string	"spl"
.LC125:
	.string	"smi"
.LC126:
	.string	"sge"
.LC127:
	.string	"slt"
.LC128:
	.string	"sgt"
.LC129:
	.string	"sle"
.LC130:
	.string	"subi.b"
.LC131:
	.string	"subi.w"
.LC132:
	.string	"subi.l"
.LC133:
	.string	"tas.b"
.LC134:
	.string	"tst.b"
.LC135:
	.string	"tst.w"
.LC136:
	.string	"tst.l"
.LC137:
	.string	"bhi"
.LC138:
	.string	"bls"
.LC139:
	.string	"bcc"
.LC140:
	.string	"bcs"
.LC141:
	.string	"bne"
.LC142:
	.string	"beq"
.LC143:
	.string	"bvc"
.LC144:
	.string	"bvs"
.LC145:
	.string	"bpl"
.LC146:
	.string	"bmi"
.LC147:
	.string	"bge"
.LC148:
	.string	"blt"
.LC149:
	.string	"bgt"
.LC150:
	.string	"ble"
.LC151:
	.string	"bra"
.LC152:
	.string	"bsr"
.LC153:
	.string	"abcd"
.LC154:
	.string	"addx.b"
.LC155:
	.string	"addx.w"
.LC156:
	.string	"addx.l"
.LC157:
	.string	"exg"
.LC158:
	.string	"asl.b"
.LC159:
	.string	"asl.w"
.LC160:
	.string	"asl.l"
.LC161:
	.string	"asr.b"
.LC162:
	.string	"asr.w"
.LC163:
	.string	"asr.l"
.LC164:
	.string	"cmpm.b"
.LC165:
	.string	"cmpm.w"
.LC166:
	.string	"cmpm.l"
.LC167:
	.string	"lsl.b"
.LC168:
	.string	"lsl.w"
.LC169:
	.string	"lsl.l"
.LC170:
	.string	"lsr.b"
.LC171:
	.string	"lsr.w"
.LC172:
	.string	"lsr.l"
.LC173:
	.string	"movep.w"
.LC174:
	.string	"movep.l"
.LC175:
	.string	"rol.b"
.LC176:
	.string	"rol.w"
.LC177:
	.string	"rol.l"
.LC178:
	.string	"ror.b"
.LC179:
	.string	"ror.w"
.LC180:
	.string	"ror.l"
.LC181:
	.string	"roxl.b"
.LC182:
	.string	"roxl.w"
.LC183:
	.string	"roxl.l"
.LC184:
	.string	"roxr.b"
.LC185:
	.string	"roxr.w"
.LC186:
	.string	"roxr.l"
.LC187:
	.string	"sbcd"
.LC188:
	.string	"subx.b"
.LC189:
	.string	"subx.w"
.LC190:
	.string	"subx.l"
.LC191:
	.string	"add.b"
.LC192:
	.string	"add.w"
.LC193:
	.string	"add.l"
.LC194:
	.string	"adda.w"
.LC195:
	.string	"adda.l"
.LC196:
	.string	"addq.b"
.LC197:
	.string	"addq.w"
.LC198:
	.string	"addq.l"
.LC199:
	.string	"and.b"
.LC200:
	.string	"and.w"
.LC201:
	.string	"and.l"
.LC202:
	.string	"chk"
.LC203:
	.string	"cmp.b"
.LC204:
	.string	"cmp.w"
.LC205:
	.string	"cmp.l"
.LC206:
	.string	"cmpa.w"
.LC207:
	.string	"cmpa.l"
.LC208:
	.string	"divs"
.LC209:
	.string	"divu"
.LC210:
	.string	"eor.b"
.LC211:
	.string	"eor.w"
.LC212:
	.string	"eor.l"
.LC213:
	.string	"lea"
.LC214:
	.string	"movea.w"
.LC215:
	.string	"movea.l"
.LC216:
	.string	"muls"
.LC217:
	.string	"mulu"
.LC218:
	.string	"or.b"
.LC219:
	.string	"or.w"
.LC220:
	.string	"or.l"
.LC221:
	.string	"sub.b"
.LC222:
	.string	"sub.w"
.LC223:
	.string	"sub.l"
.LC224:
	.string	"suba.w"
.LC225:
	.string	"suba.l"
.LC226:
	.string	"subq.b"
.LC227:
	.string	"subq.w"
.LC228:
	.string	"subq.l"
.LC229:
	.string	"moveq.l"
.LC230:
	.string	"move.b"
.LC231:
	.string	"*unknown instruction*"
	.section	.rodata
	.align	4
	.type	optab, @object
	.size	optab, 3216
optab:
	.word	-1
	.word	572
	.word	3
	.zero	2
	.long	.LC32
	.word	-1
	.word	636
	.word	3
	.zero	2
	.long	.LC33
	.word	-1
	.word	2620
	.word	3
	.zero	2
	.long	.LC34
	.word	-1
	.word	2684
	.word	3
	.zero	2
	.long	.LC35
	.word	-1
	.word	19194
	.word	0
	.zero	2
	.long	.LC36
	.word	-1
	.word	19195
	.word	0
	.zero	2
	.long	.LC36
	.word	-1
	.word	19196
	.word	0
	.zero	2
	.long	.LC36
	.word	-1
	.word	20081
	.word	0
	.zero	2
	.long	.LC37
	.word	-1
	.word	60
	.word	3
	.zero	2
	.long	.LC38
	.word	-1
	.word	124
	.word	3
	.zero	2
	.long	.LC39
	.word	-1
	.word	20080
	.word	0
	.zero	2
	.long	.LC40
	.word	-1
	.word	20084
	.word	21
	.zero	2
	.long	.LC41
	.word	-1
	.word	20083
	.word	0
	.zero	2
	.long	.LC42
	.word	-1
	.word	20087
	.word	0
	.zero	2
	.long	.LC43
	.word	-1
	.word	20085
	.word	0
	.zero	2
	.long	.LC44
	.word	-1
	.word	20082
	.word	21
	.zero	2
	.long	.LC45
	.word	-1
	.word	20086
	.word	0
	.zero	2
	.long	.LC46
	.word	-2
	.word	20090
	.word	24
	.zero	2
	.long	.LC47
	.word	-8
	.word	20680
	.word	12
	.zero	2
	.long	.LC48
	.word	-8
	.word	20936
	.word	12
	.zero	2
	.long	.LC49
	.word	-8
	.word	21192
	.word	12
	.zero	2
	.long	.LC50
	.word	-8
	.word	21448
	.word	12
	.zero	2
	.long	.LC51
	.word	-8
	.word	21704
	.word	12
	.zero	2
	.long	.LC52
	.word	-8
	.word	21960
	.word	12
	.zero	2
	.long	.LC53
	.word	-8
	.word	22216
	.word	12
	.zero	2
	.long	.LC54
	.word	-8
	.word	22472
	.word	12
	.zero	2
	.long	.LC55
	.word	-8
	.word	22728
	.word	12
	.zero	2
	.long	.LC56
	.word	-8
	.word	22984
	.word	12
	.zero	2
	.long	.LC57
	.word	-8
	.word	23240
	.word	12
	.zero	2
	.long	.LC58
	.word	-8
	.word	23496
	.word	12
	.zero	2
	.long	.LC59
	.word	-8
	.word	23752
	.word	12
	.zero	2
	.long	.LC60
	.word	-8
	.word	24008
	.word	12
	.zero	2
	.long	.LC61
	.word	-8
	.word	24264
	.word	12
	.zero	2
	.long	.LC62
	.word	-8
	.word	24520
	.word	12
	.zero	2
	.long	.LC63
	.word	-8
	.word	18560
	.word	14
	.zero	2
	.long	.LC64
	.word	-8
	.word	18624
	.word	14
	.zero	2
	.long	.LC65
	.word	-8
	.word	20048
	.word	15
	.zero	2
	.long	.LC66
	.word	-8
	.word	20064
	.word	17
	.zero	2
	.long	.LC67
	.word	-8
	.word	20072
	.word	17
	.zero	2
	.long	.LC67
	.word	-8
	.word	18496
	.word	22
	.zero	2
	.long	.LC68
	.word	-8
	.word	20056
	.word	22
	.zero	2
	.long	.LC69
	.word	-16
	.word	20032
	.word	23
	.zero	2
	.long	.LC70
	.word	-64
	.word	1536
	.word	3
	.zero	2
	.long	.LC71
	.word	-64
	.word	1600
	.word	3
	.zero	2
	.long	.LC72
	.word	-64
	.word	1664
	.word	3
	.zero	2
	.long	.LC73
	.word	-64
	.word	512
	.word	3
	.zero	2
	.long	.LC32
	.word	-64
	.word	576
	.word	3
	.zero	2
	.long	.LC33
	.word	-64
	.word	640
	.word	3
	.zero	2
	.long	.LC74
	.word	-64
	.word	-7744
	.word	7
	.zero	2
	.long	.LC75
	.word	-64
	.word	-8000
	.word	7
	.zero	2
	.long	.LC76
	.word	-64
	.word	2112
	.word	10
	.zero	2
	.long	.LC77
	.word	-64
	.word	2176
	.word	10
	.zero	2
	.long	.LC78
	.word	-64
	.word	2240
	.word	10
	.zero	2
	.long	.LC79
	.word	-64
	.word	2048
	.word	10
	.zero	2
	.long	.LC80
	.word	-64
	.word	16896
	.word	7
	.zero	2
	.long	.LC81
	.word	-64
	.word	16960
	.word	7
	.zero	2
	.long	.LC82
	.word	-64
	.word	17024
	.word	7
	.zero	2
	.long	.LC83
	.word	-64
	.word	3072
	.word	3
	.zero	2
	.long	.LC84
	.word	-64
	.word	3136
	.word	3
	.zero	2
	.long	.LC85
	.word	-64
	.word	3200
	.word	3
	.zero	2
	.long	.LC86
	.word	-64
	.word	2560
	.word	3
	.zero	2
	.long	.LC34
	.word	-64
	.word	2624
	.word	3
	.zero	2
	.long	.LC35
	.word	-64
	.word	2688
	.word	3
	.zero	2
	.long	.LC87
	.word	-64
	.word	20160
	.word	7
	.zero	2
	.long	.LC88
	.word	-64
	.word	20096
	.word	7
	.zero	2
	.long	.LC89
	.word	-64
	.word	-7232
	.word	7
	.zero	2
	.long	.LC90
	.word	-64
	.word	-7488
	.word	7
	.zero	2
	.long	.LC91
	.word	-64
	.word	17088
	.word	5
	.zero	2
	.long	.LC92
	.word	-64
	.word	17600
	.word	5
	.zero	2
	.long	.LC92
	.word	-64
	.word	18112
	.word	5
	.zero	2
	.long	.LC92
	.word	-64
	.word	16576
	.word	5
	.zero	2
	.long	.LC92
	.word	-64
	.word	19584
	.word	18
	.zero	2
	.long	.LC93
	.word	-64
	.word	19648
	.word	18
	.zero	2
	.long	.LC94
	.word	-64
	.word	18560
	.word	18
	.zero	2
	.long	.LC93
	.word	-64
	.word	18624
	.word	18
	.zero	2
	.long	.LC94
	.word	-64
	.word	3584
	.word	25
	.zero	2
	.long	.LC95
	.word	-64
	.word	3648
	.word	25
	.zero	2
	.long	.LC96
	.word	-64
	.word	3712
	.word	25
	.zero	2
	.long	.LC97
	.word	-64
	.word	18432
	.word	7
	.zero	2
	.long	.LC98
	.word	-64
	.word	17408
	.word	7
	.zero	2
	.long	.LC99
	.word	-64
	.word	17472
	.word	7
	.zero	2
	.long	.LC100
	.word	-64
	.word	17536
	.word	7
	.zero	2
	.long	.LC101
	.word	-64
	.word	16384
	.word	7
	.zero	2
	.long	.LC102
	.word	-64
	.word	16448
	.word	7
	.zero	2
	.long	.LC103
	.word	-64
	.word	16512
	.word	7
	.zero	2
	.long	.LC104
	.word	-64
	.word	17920
	.word	7
	.zero	2
	.long	.LC105
	.word	-64
	.word	17984
	.word	7
	.zero	2
	.long	.LC106
	.word	-64
	.word	18048
	.word	7
	.zero	2
	.long	.LC107
	.word	-64
	.word	0
	.word	3
	.zero	2
	.long	.LC38
	.word	-64
	.word	64
	.word	3
	.zero	2
	.long	.LC39
	.word	-64
	.word	128
	.word	3
	.zero	2
	.long	.LC108
	.word	-64
	.word	18496
	.word	7
	.zero	2
	.long	.LC109
	.word	-64
	.word	-6208
	.word	7
	.zero	2
	.long	.LC110
	.word	-64
	.word	-6464
	.word	7
	.zero	2
	.long	.LC111
	.word	-64
	.word	-6720
	.word	7
	.zero	2
	.long	.LC112
	.word	-64
	.word	-6976
	.word	7
	.zero	2
	.long	.LC113
	.word	-64
	.word	20672
	.word	7
	.zero	2
	.long	.LC114
	.word	-64
	.word	20928
	.word	7
	.zero	2
	.long	.LC115
	.word	-64
	.word	21184
	.word	7
	.zero	2
	.long	.LC116
	.word	-64
	.word	21440
	.word	7
	.zero	2
	.long	.LC117
	.word	-64
	.word	21696
	.word	7
	.zero	2
	.long	.LC118
	.word	-64
	.word	21952
	.word	7
	.zero	2
	.long	.LC119
	.word	-64
	.word	22208
	.word	7
	.zero	2
	.long	.LC120
	.word	-64
	.word	22464
	.word	7
	.zero	2
	.long	.LC121
	.word	-64
	.word	22720
	.word	7
	.zero	2
	.long	.LC122
	.word	-64
	.word	22976
	.word	7
	.zero	2
	.long	.LC123
	.word	-64
	.word	23232
	.word	7
	.zero	2
	.long	.LC124
	.word	-64
	.word	23488
	.word	7
	.zero	2
	.long	.LC125
	.word	-64
	.word	23744
	.word	7
	.zero	2
	.long	.LC126
	.word	-64
	.word	24000
	.word	7
	.zero	2
	.long	.LC127
	.word	-64
	.word	24256
	.word	7
	.zero	2
	.long	.LC128
	.word	-64
	.word	24512
	.word	7
	.zero	2
	.long	.LC129
	.word	-64
	.word	1024
	.word	3
	.zero	2
	.long	.LC130
	.word	-64
	.word	1088
	.word	3
	.zero	2
	.long	.LC131
	.word	-64
	.word	1152
	.word	3
	.zero	2
	.long	.LC132
	.word	-64
	.word	19136
	.word	7
	.zero	2
	.long	.LC133
	.word	-64
	.word	18944
	.word	7
	.zero	2
	.long	.LC134
	.word	-64
	.word	19008
	.word	7
	.zero	2
	.long	.LC135
	.word	-64
	.word	19072
	.word	7
	.zero	2
	.long	.LC136
	.word	-256
	.word	25088
	.word	8
	.zero	2
	.long	.LC137
	.word	-256
	.word	25344
	.word	8
	.zero	2
	.long	.LC138
	.word	-256
	.word	25600
	.word	8
	.zero	2
	.long	.LC139
	.word	-256
	.word	25856
	.word	8
	.zero	2
	.long	.LC140
	.word	-256
	.word	26112
	.word	8
	.zero	2
	.long	.LC141
	.word	-256
	.word	26368
	.word	8
	.zero	2
	.long	.LC142
	.word	-256
	.word	26624
	.word	8
	.zero	2
	.long	.LC143
	.word	-256
	.word	26880
	.word	8
	.zero	2
	.long	.LC144
	.word	-256
	.word	27136
	.word	8
	.zero	2
	.long	.LC145
	.word	-256
	.word	27392
	.word	8
	.zero	2
	.long	.LC146
	.word	-256
	.word	27648
	.word	8
	.zero	2
	.long	.LC147
	.word	-256
	.word	27904
	.word	8
	.zero	2
	.long	.LC148
	.word	-256
	.word	28160
	.word	8
	.zero	2
	.long	.LC149
	.word	-256
	.word	28416
	.word	8
	.zero	2
	.long	.LC150
	.word	-256
	.word	24576
	.word	8
	.zero	2
	.long	.LC151
	.word	-256
	.word	24832
	.word	8
	.zero	2
	.long	.LC152
	.word	-3592
	.word	-16128
	.word	1
	.zero	2
	.long	.LC153
	.word	-3592
	.word	-16120
	.word	1
	.zero	2
	.long	.LC153
	.word	-3592
	.word	-12032
	.word	1
	.zero	2
	.long	.LC154
	.word	-3592
	.word	-11968
	.word	1
	.zero	2
	.long	.LC155
	.word	-3592
	.word	-11904
	.word	1
	.zero	2
	.long	.LC156
	.word	-3592
	.word	-12024
	.word	1
	.zero	2
	.long	.LC154
	.word	-3592
	.word	-11960
	.word	1
	.zero	2
	.long	.LC155
	.word	-3592
	.word	-11896
	.word	1
	.zero	2
	.long	.LC156
	.word	-3592
	.word	-16064
	.word	13
	.zero	2
	.long	.LC157
	.word	-3592
	.word	-16056
	.word	13
	.zero	2
	.long	.LC157
	.word	-3592
	.word	-15992
	.word	13
	.zero	2
	.long	.LC157
	.word	-3592
	.word	-7936
	.word	6
	.zero	2
	.long	.LC158
	.word	-3592
	.word	-7872
	.word	6
	.zero	2
	.long	.LC159
	.word	-3592
	.word	-7808
	.word	6
	.zero	2
	.long	.LC160
	.word	-3592
	.word	-7904
	.word	6
	.zero	2
	.long	.LC158
	.word	-3592
	.word	-7840
	.word	6
	.zero	2
	.long	.LC159
	.word	-3592
	.word	-7776
	.word	6
	.zero	2
	.long	.LC160
	.word	-3592
	.word	-8192
	.word	6
	.zero	2
	.long	.LC161
	.word	-3592
	.word	-8128
	.word	6
	.zero	2
	.long	.LC162
	.word	-3592
	.word	-8064
	.word	6
	.zero	2
	.long	.LC163
	.word	-3592
	.word	-8160
	.word	6
	.zero	2
	.long	.LC161
	.word	-3592
	.word	-8096
	.word	6
	.zero	2
	.long	.LC162
	.word	-3592
	.word	-8032
	.word	6
	.zero	2
	.long	.LC163
	.word	-3592
	.word	-20216
	.word	11
	.zero	2
	.long	.LC164
	.word	-3592
	.word	-20152
	.word	11
	.zero	2
	.long	.LC165
	.word	-3592
	.word	-20088
	.word	11
	.zero	2
	.long	.LC166
	.word	-3592
	.word	-7928
	.word	6
	.zero	2
	.long	.LC167
	.word	-3592
	.word	-7864
	.word	6
	.zero	2
	.long	.LC168
	.word	-3592
	.word	-7800
	.word	6
	.zero	2
	.long	.LC169
	.word	-3592
	.word	-7896
	.word	6
	.zero	2
	.long	.LC167
	.word	-3592
	.word	-7832
	.word	6
	.zero	2
	.long	.LC168
	.word	-3592
	.word	-7768
	.word	6
	.zero	2
	.long	.LC169
	.word	-3592
	.word	-8184
	.word	6
	.zero	2
	.long	.LC170
	.word	-3592
	.word	-8120
	.word	6
	.zero	2
	.long	.LC171
	.word	-3592
	.word	-8056
	.word	6
	.zero	2
	.long	.LC172
	.word	-3592
	.word	-8152
	.word	6
	.zero	2
	.long	.LC170
	.word	-3592
	.word	-8088
	.word	6
	.zero	2
	.long	.LC171
	.word	-3592
	.word	-8024
	.word	6
	.zero	2
	.long	.LC172
	.word	-3592
	.word	264
	.word	19
	.zero	2
	.long	.LC173
	.word	-3592
	.word	328
	.word	19
	.zero	2
	.long	.LC174
	.word	-3592
	.word	392
	.word	19
	.zero	2
	.long	.LC173
	.word	-3592
	.word	456
	.word	19
	.zero	2
	.long	.LC174
	.word	-3592
	.word	-7912
	.word	6
	.zero	2
	.long	.LC175
	.word	-3592
	.word	-7848
	.word	6
	.zero	2
	.long	.LC176
	.word	-3592
	.word	-7784
	.word	6
	.zero	2
	.long	.LC177
	.word	-3592
	.word	-7880
	.word	6
	.zero	2
	.long	.LC175
	.word	-3592
	.word	-7816
	.word	6
	.zero	2
	.long	.LC176
	.word	-3592
	.word	-7752
	.word	6
	.zero	2
	.long	.LC177
	.word	-3592
	.word	-8168
	.word	6
	.zero	2
	.long	.LC178
	.word	-3592
	.word	-8104
	.word	6
	.zero	2
	.long	.LC179
	.word	-3592
	.word	-8040
	.word	6
	.zero	2
	.long	.LC180
	.word	-3592
	.word	-8136
	.word	6
	.zero	2
	.long	.LC178
	.word	-3592
	.word	-8072
	.word	6
	.zero	2
	.long	.LC179
	.word	-3592
	.word	-8008
	.word	6
	.zero	2
	.long	.LC180
	.word	-3592
	.word	-7920
	.word	6
	.zero	2
	.long	.LC181
	.word	-3592
	.word	-7856
	.word	6
	.zero	2
	.long	.LC182
	.word	-3592
	.word	-7792
	.word	6
	.zero	2
	.long	.LC183
	.word	-3592
	.word	-7888
	.word	6
	.zero	2
	.long	.LC181
	.word	-3592
	.word	-7824
	.word	6
	.zero	2
	.long	.LC182
	.word	-3592
	.word	-7760
	.word	6
	.zero	2
	.long	.LC183
	.word	-3592
	.word	-8176
	.word	6
	.zero	2
	.long	.LC184
	.word	-3592
	.word	-8112
	.word	6
	.zero	2
	.long	.LC185
	.word	-3592
	.word	-8048
	.word	6
	.zero	2
	.long	.LC186
	.word	-3592
	.word	-8144
	.word	6
	.zero	2
	.long	.LC184
	.word	-3592
	.word	-8080
	.word	6
	.zero	2
	.long	.LC185
	.word	-3592
	.word	-8016
	.word	6
	.zero	2
	.long	.LC186
	.word	-3592
	.word	-32512
	.word	1
	.zero	2
	.long	.LC187
	.word	-3592
	.word	-32504
	.word	1
	.zero	2
	.long	.LC187
	.word	-3592
	.word	-28416
	.word	1
	.zero	2
	.long	.LC188
	.word	-3592
	.word	-28352
	.word	1
	.zero	2
	.long	.LC189
	.word	-3592
	.word	-28288
	.word	1
	.zero	2
	.long	.LC190
	.word	-3592
	.word	-28408
	.word	1
	.zero	2
	.long	.LC188
	.word	-3592
	.word	-28344
	.word	1
	.zero	2
	.long	.LC189
	.word	-3592
	.word	-28280
	.word	1
	.zero	2
	.long	.LC190
	.word	-3648
	.word	-12288
	.word	2
	.zero	2
	.long	.LC191
	.word	-3648
	.word	-12224
	.word	2
	.zero	2
	.long	.LC192
	.word	-3648
	.word	-12160
	.word	2
	.zero	2
	.long	.LC193
	.word	-3648
	.word	-12032
	.word	2
	.zero	2
	.long	.LC191
	.word	-3648
	.word	-11968
	.word	2
	.zero	2
	.long	.LC192
	.word	-3648
	.word	-11904
	.word	2
	.zero	2
	.long	.LC193
	.word	-3648
	.word	-12096
	.word	2
	.zero	2
	.long	.LC194
	.word	-3648
	.word	-11840
	.word	2
	.zero	2
	.long	.LC195
	.word	-3648
	.word	20480
	.word	4
	.zero	2
	.long	.LC196
	.word	-3648
	.word	20544
	.word	4
	.zero	2
	.long	.LC197
	.word	-3648
	.word	20608
	.word	4
	.zero	2
	.long	.LC198
	.word	-3648
	.word	-16384
	.word	2
	.zero	2
	.long	.LC199
	.word	-3648
	.word	-16320
	.word	2
	.zero	2
	.long	.LC200
	.word	-3648
	.word	-16256
	.word	2
	.zero	2
	.long	.LC201
	.word	-3648
	.word	-16128
	.word	2
	.zero	2
	.long	.LC199
	.word	-3648
	.word	-16064
	.word	2
	.zero	2
	.long	.LC200
	.word	-3648
	.word	-16000
	.word	2
	.zero	2
	.long	.LC201
	.word	-3648
	.word	320
	.word	10
	.zero	2
	.long	.LC77
	.word	-3648
	.word	384
	.word	10
	.zero	2
	.long	.LC78
	.word	-3648
	.word	448
	.word	10
	.zero	2
	.long	.LC79
	.word	-3648
	.word	256
	.word	10
	.zero	2
	.long	.LC80
	.word	-3648
	.word	16768
	.word	9
	.zero	2
	.long	.LC202
	.word	-3648
	.word	-20480
	.word	2
	.zero	2
	.long	.LC203
	.word	-3648
	.word	-20416
	.word	2
	.zero	2
	.long	.LC204
	.word	-3648
	.word	-20352
	.word	2
	.zero	2
	.long	.LC205
	.word	-3648
	.word	-20288
	.word	2
	.zero	2
	.long	.LC206
	.word	-3648
	.word	-20032
	.word	2
	.zero	2
	.long	.LC207
	.word	-3648
	.word	-32320
	.word	9
	.zero	2
	.long	.LC208
	.word	-3648
	.word	-32576
	.word	9
	.zero	2
	.long	.LC209
	.word	-3648
	.word	-20224
	.word	2
	.zero	2
	.long	.LC210
	.word	-3648
	.word	-20160
	.word	2
	.zero	2
	.long	.LC211
	.word	-3648
	.word	-20096
	.word	2
	.zero	2
	.long	.LC212
	.word	-3648
	.word	16832
	.word	2
	.zero	2
	.long	.LC213
	.word	-3648
	.word	12352
	.word	16
	.zero	2
	.long	.LC214
	.word	-3648
	.word	8256
	.word	16
	.zero	2
	.long	.LC215
	.word	-3648
	.word	-15936
	.word	9
	.zero	2
	.long	.LC216
	.word	-3648
	.word	-16192
	.word	9
	.zero	2
	.long	.LC217
	.word	-3648
	.word	-32768
	.word	2
	.zero	2
	.long	.LC218
	.word	-3648
	.word	-32704
	.word	2
	.zero	2
	.long	.LC219
	.word	-3648
	.word	-32640
	.word	2
	.zero	2
	.long	.LC220
	.word	-3648
	.word	-32512
	.word	2
	.zero	2
	.long	.LC218
	.word	-3648
	.word	-32448
	.word	2
	.zero	2
	.long	.LC219
	.word	-3648
	.word	-32384
	.word	2
	.zero	2
	.long	.LC220
	.word	-3648
	.word	-28672
	.word	2
	.zero	2
	.long	.LC221
	.word	-3648
	.word	-28608
	.word	2
	.zero	2
	.long	.LC222
	.word	-3648
	.word	-28544
	.word	2
	.zero	2
	.long	.LC223
	.word	-3648
	.word	-28416
	.word	2
	.zero	2
	.long	.LC221
	.word	-3648
	.word	-28352
	.word	2
	.zero	2
	.long	.LC222
	.word	-3648
	.word	-28288
	.word	2
	.zero	2
	.long	.LC223
	.word	-3648
	.word	-28480
	.word	2
	.zero	2
	.long	.LC224
	.word	-3648
	.word	-28224
	.word	2
	.zero	2
	.long	.LC225
	.word	-3648
	.word	20736
	.word	4
	.zero	2
	.long	.LC226
	.word	-3648
	.word	20800
	.word	4
	.zero	2
	.long	.LC227
	.word	-3648
	.word	20864
	.word	4
	.zero	2
	.long	.LC228
	.word	-3840
	.word	28672
	.word	20
	.zero	2
	.long	.LC229
	.word	-4096
	.word	4096
	.word	16
	.zero	2
	.long	.LC230
	.word	-4096
	.word	12288
	.word	16
	.zero	2
	.long	.LC92
	.word	-4096
	.word	8192
	.word	16
	.zero	2
	.long	.LC67
	.word	0
	.word	0
	.word	0
	.zero	2
	.long	.LC231
	.globl	regmsk0
	.align	2
	.type	regmsk0, @object
	.size	regmsk0, 32
regmsk0:
	.word	-32768
	.word	16384
	.word	8192
	.word	4096
	.word	2048
	.word	1024
	.word	512
	.word	256
	.word	128
	.word	64
	.word	32
	.word	16
	.word	8
	.word	4
	.word	2
	.word	1
	.globl	regmsk1
	.align	2
	.type	regmsk1, @object
	.size	regmsk1, 32
regmsk1:
	.word	1
	.word	2
	.word	4
	.word	8
	.word	16
	.word	32
	.word	64
	.word	128
	.word	256
	.word	512
	.word	1024
	.word	2048
	.word	4096
	.word	8192
	.word	16384
	.word	-32768
	.local	dot
	.comm	dot,4,4
	.local	sdot
	.comm	sdot,4,4
	.local	dotinc
	.comm	dotinc,4,4
	.comm	instr,2,2
	.ident	"GCC: (GNU) 4.1.1"
