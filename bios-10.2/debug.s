#NO_APP
	.file	"debug.c"
	.text
	.align	2
	.globl	token
	.type	token, @function
token:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l 8(%fp),%a0
	move.l __ctype_ptr,%a2
	jbra .L2
.L3:
	addq.l #1,%a0
.L2:
	move.b (%a0),%d0
	ext.w %d0
	btst #3,(%a2,%d0.w)
	jbne .L3
	move.l %a0,%a1
	jbra .L5
.L6:
	addq.l #1,%a1
	move.b (%a1),%d0
	ext.w %d0
.L5:
	move.b (%a2,%d0.w),%d0
	moveq #7,%d1
	and.l %d1,%d0
	jbne .L6
	cmp.l %a1,%a0
	jbeq .L8
	move.l %a0,%d0
	jbra .L10
.L8:
	moveq #0,%d0
.L10:
	move.b (%a1),%d1
	jbeq .L11
	move.b %d1,charsave
	clr.b (%a1)
.L11:
	move.l 12(%fp),%a0
	move.l %a1,(%a0)
	move.l (%sp)+,%a2
	unlk %fp
	rts
	.size	token, .-token
	.align	2
	.globl	size_imm
	.type	size_imm, @function
size_imm:
	link.w %fp,#0
	move.w state+68,%d1
	move.w %d1,%d0
	swap %d0
	mov.w state+70,%d0
	move.l %d0,%a0
	move.w 2(%a0),%d1
	btst #8,%d1
	jbne .L15
	moveq #2,%d0
	jbra .L17
.L15:
	move.w %d1,%d0
	lsr.w #4,%d0
	and.w #3,%d0
	and.w #3,%d1
	cmp.w #2,%d0
	jbne .L18
	moveq #4,%d0
	jbra .L20
.L18:
	cmp.w #3,%d0
	jbne .L21
	moveq #6,%d0
	jbra .L20
.L21:
	moveq #2,%d0
.L20:
	cmp.w #2,%d1
	jbne .L23
	addq.l #2,%d0
	jbra .L17
.L23:
	cmp.w #3,%d1
	jbne .L17
	addq.l #4,%d0
.L17:
	unlk %fp
	rts
	.size	size_imm, .-size_imm
	.align	2
	.globl	size_ea
	.type	size_ea, @function
size_ea:
	link.w %fp,#0
	move.w 10(%fp),%d1
	move.w %d1,%d0
	lsr.w #3,%d0
	and.w #7,%d0
	cmp.w #4,%d0
	jbls .L28
	cmp.w #5,%d0
	jbeq .L30
	cmp.w #7,%d0
	jbne .L32
	move.w %d1,%d0
	and.w #7,%d0
	jbeq .L30
	cmp.w #2,%d0
	jbeq .L30
	cmp.w #1,%d0
	jbne .L36
	moveq #4,%d0
	jbra .L38
.L36:
	cmp.w #3,%d0
	jbne .L28
	jbsr size_imm
	jbra .L38
.L32:
	jbsr size_imm
	jbra .L38
.L28:
	moveq #0,%d0
	jbra .L38
.L30:
	moveq #2,%d0
.L38:
	unlk %fp
	rts
	.size	size_ea, .-size_ea
	.align	2
	.globl	install_breaks
	.type	install_breaks, @function
install_breaks:
	link.w %fp,#0
	lea breakpoint,%a0
.L42:
	btst #1,7(%a0)
	jbeq .L43
	move.w (%a0),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a0),%d0
	move.l %d0,%a1
	move.w #19196,(%a1)
.L43:
	cmp.l #breakpoint+128,%a0
	jbeq .L47
	addq.l #8,%a0
	jbra .L42
.L47:
	unlk %fp
	rts
	.size	install_breaks, .-install_breaks
	.align	2
	.globl	remove_breaks
	.type	remove_breaks, @function
remove_breaks:
	link.w %fp,#0
	lea breakpoint+6,%a1
.L49:
	lea (-6,%a1),%a0
	btst #1,1(%a1)
	jbeq .L50
	move.w (%a0),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a0),%d0
	move.l %d0,%a0
	move.w -2(%a1),(%a0)
.L50:
	addq.l #8,%a1
	cmp.l #breakpoint+142,%a1
	jbne .L49
	clr.w breakpoint+134
	clr.w breakpoint+128
	clr.w breakpoint+130
	unlk %fp
	rts
	.size	remove_breaks, .-remove_breaks
	.align	2
	.globl	check_pc
	.type	check_pc, @function
check_pc:
	link.w %fp,#0
	movm.l #0x3020,-(%sp)
	move.w state+68,%d0
	move.w %d0,%d2
	swap %d2
	mov.w state+70,%d2
	sub.l %a1,%a1
	lea breakpoint+6,%a2
	moveq #0,%d1
.L57:
	btst #1,1(%a2)
	jbeq .L58
	lea breakpoint,%a0
	move.w (%a0,%d1.l),%d3
	move.w %d3,%d0
	swap %d0
	mov.w 2(%a0,%d1.l),%d0
	cmp.l %d0,%d2
	jbeq .L60
.L58:
	addq.l #1,%a1
	addq.l #8,%d1
	addq.l #8,%a2
	moveq #16,%d0
	cmp.l %a1,%d0
	jbne .L57
	move.w #-1,%a1
.L60:
	move.l %a1,%d0
	movm.l (%sp)+,#0x40c
	unlk %fp
	rts
	.size	check_pc, .-check_pc
	.globl	__divsi3
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"%06lx:"
.LC1:
	.string	" "
.LC2:
	.string	"\n"
	.text
	.align	2
	.globl	dump_memory
	.type	dump_memory, @function
dump_memory:
	link.w %fp,#0
	movm.l #0x3f20,-(%sp)
	move.l 8(%fp),%d2
	move.l 12(%fp),%d3
	move.l 16(%fp),%d4
	move.l %d2,%d0
	subq.l #1,%d0
	moveq #3,%d1
	cmp.l %d0,%d1
	jbcs .L66
	btst #0,%d2
	jbne .L68
	moveq #-2,%d0
	and.l %d0,%d3
.L68:
	moveq #3,%d1
	cmp.l %d2,%d1
	jbne .L70
	moveq #64,%d7
.L72:
	clr.w %d6
	jbra .L73
.L66:
	moveq #1,%d2
.L70:
	move.l %d2,-(%sp)
	pea 16.w
	jbsr __divsi3
	addq.l #8,%sp
	move.w %d0,%d7
	jbra .L72
.L74:
	move.l %d3,-(%sp)
	pea .LC0
	jbsr cprintf
	move.l %d3,%a2
	clr.w %d3
	moveq #0,%d5
	jbra .L91
.L76:
	tst.w %d5
	jbeq .L77
	cmp.w %d3,%d6
	jbne .L79
.L77:
	pea .LC1
	jbsr cprintf
	addq.l #4,%sp
.L79:
	moveq #2,%d0
	cmp.l %d2,%d0
	jbeq .L82
	jblt .L85
	moveq #1,%d1
	cmp.l %d2,%d1
	jbne .L80
	jbra .L81
.L85:
	moveq #3,%d0
	cmp.l %d2,%d0
	jbeq .L83
	moveq #4,%d1
	cmp.l %d2,%d1
	jbeq .L84
.L80:
	moveq #0,%d0
	jbra .L86
.L81:
	moveq #0,%d0
	move.b (%a2)+,%d0
	moveq #8,%d6
	jbra .L86
.L82:
	moveq #0,%d0
	move.w (%a2)+,%d0
	moveq #4,%d6
	jbra .L86
.L83:
	moveq #0,%d0
	move.b (%a2)+,%d0
	jbra .L86
.L84:
	move.l (%a2)+,%d0
.L86:
	move.l %d0,-(%sp)
	move.l %d2,%d0
	add.l %d2,%d0
	move.l %d0,%a0
	add.l %d0,%a0
	add.l #fmt.1804,%a0
	move.l -4(%a0),-(%sp)
	jbsr cprintf
	addq.w #1,%d3
	subq.l #1,%d4
	addq.l #1,%d5
.L91:
	addq.l #8,%sp
	cmp.w %d3,%d7
	jbeq .L87
	tst.l %d4
	jbne .L76
.L87:
	pea .LC2
	jbsr cprintf
	move.l %a2,%d3
	addq.l #4,%sp
.L73:
	tst.l %d4
	jbgt .L74
	movm.l -28(%fp),#0x4fc
	unlk %fp
	rts
	.size	dump_memory, .-dump_memory
	.section	.rodata.str1.1
.LC3:
	.string	"  %c%hd %08lx"
	.text
	.align	2
	.globl	print_regs
	.type	print_regs, @function
print_regs:
	link.w %fp,#0
	movm.l #0x3830,-(%sp)
	move.l 12(%fp),%a3
	move.b 11(%fp),%d4
	move.w 18(%fp),%d3
	clr.w %d2
	jbra .L103
.L94:
	moveq #0,%d1
	move.w %d2,%d1
	move.l %d1,%d0
	add.l %d1,%d0
	add.l %d0,%d0
	move.l (%a3,%d0.l),-(%sp)
	move.l %d1,-(%sp)
	move.b %d4,%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	pea .LC3
	lea cprintf,%a2
	jbsr (%a2)
	addq.w #1,%d2
	moveq #3,%d0
	and.l %d2,%d0
	lea (16,%sp),%sp
	jbne .L103
	pea .LC2
	jbsr (%a2)
	addq.l #4,%sp
.L103:
	cmp.w %d2,%d3
	jbne .L94
	movm.l -20(%fp),#0xc1c
	unlk %fp
	rts
	.size	print_regs, .-print_regs
	.section	.rodata.str1.1
.LC4:
	.string	"  A7 %08lx\n"
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
	move.l 8(%fp),%a3
	pea 8.w
	move.l %a3,-(%sp)
	pea 68.w
	lea print_regs,%a2
	jbsr (%a2)
	pea 7.w
	pea 32(%a3)
	pea 65.w
	jbsr (%a2)
	lea (24,%sp),%sp
	btst #5,74(%a3)
	jbeq .L105
	move.w 60(%a3),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 62(%a3),%d0
	jbra .L107
.L105:
	move.w 64(%a3),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 66(%a3),%d0
.L107:
	move.l %d0,-(%sp)
	pea .LC4
	lea cprintf,%a2
	jbsr (%a2)
	move.w 64(%a3),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 66(%a3),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.w 74(%a3),%d0
	move.l %d0,-(%sp)
	move.w 68(%a3),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 70(%a3),%d0
	move.l %d0,-(%sp)
	pea .LC5
	jbsr (%a2)
	lea (24,%sp),%sp
	cmp.w #4095,72(%a3)
	jbne .L108
	pea .LC2
	jbsr (%a2)
	addq.l #4,%sp
	jbra .L111
.L108:
	move.w 60(%a3),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 62(%a3),%d0
	move.l %d0,-(%sp)
	pea .LC6
	jbsr (%a2)
	pea .LC2
	jbsr (%a2)
	lea (12,%sp),%sp
.L111:
	move.l -8(%fp),%a2
	move.l -4(%fp),%a3
	unlk %fp
	rts
	.size	print_state, .-print_state
	.section	.rodata.str1.1
.LC7:
	.string	"%2hd %c %06lx\n"
	.text
	.align	2
	.globl	list_breaks
	.type	list_breaks, @function
list_breaks:
	link.w %fp,#0
	movm.l #0x3020,-(%sp)
	moveq #0,%d3
	lea breakpoint+6,%a2
	moveq #0,%d2
.L113:
	moveq #0,%d0
	move.w (%a2),%d0
	btst #0,%d0
	jbeq .L114
	lea breakpoint,%a0
	btst #1,%d0
	seq %d0
	ext.w %d0
	move.w %d0,%a1
	move.w (%a0,%d2.l),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a0,%d2.l),%d0
	move.l %d0,-(%sp)
	pea 101(%a1)
	move.l %d3,-(%sp)
	pea .LC7
	jbsr cprintf
	lea (16,%sp),%sp
.L114:
	addq.l #1,%d3
	addq.l #8,%d2
	addq.l #8,%a2
	moveq #16,%d0
	cmp.l %d3,%d0
	jbne .L113
	movm.l -12(%fp),#0x40c
	unlk %fp
	rts
	.size	list_breaks, .-list_breaks
	.section	.rodata.str1.1
.LC8:
	.string	" ?\n"
	.text
	.align	2
	.globl	cmd_error
	.type	cmd_error, @function
cmd_error:
	link.w %fp,#0
	pea .LC8
	jbsr cprintf
	addq.l #4,%sp
	unlk %fp
	rts
	.size	cmd_error, .-cmd_error
	.align	2
	.globl	clear_breaks
	.type	clear_breaks, @function
clear_breaks:
	link.w %fp,#0
	move.l 8(%fp),%a0
	move.l __ctype_ptr,%a1
	jbra .L126
.L127:
	addq.l #1,%a0
.L126:
	move.b (%a0),%d1
	move.b %d1,%d0
	ext.w %d0
	btst #3,(%a1,%d0.w)
	jbne .L127
	cmp.b #42,%d1
	jbne .L129
	clr.l errno
	clr.w %d1
	move.w #15,%a1
	jbra .L136
.L129:
	pea 10.w
	clr.l -(%sp)
	move.l %a0,-(%sp)
	jbsr strtoul
	lea (12,%sp),%sp
	tst.l errno
	jbeq .L132
	jbsr cmd_error
	jbra .L135
.L136:
	moveq #0,%d0
	move.w %d1,%d0
	lea breakpoint,%a0
	lsl.l #3,%d0
	clr.w (%a0,%d0.l)
	clr.w 2(%a0,%d0.l)
	move.l %d0,%a0
	add.l #breakpoint+4,%a0
	clr.w (%a0)
	move.l %d0,%a0
	add.l #breakpoint+6,%a0
	clr.w (%a0)
	addq.w #1,%d1
	cmp.w %a1,%d1
	jbhi .L135
	jbra .L136
.L132:
	move.w %d0,%a1
	move.w %d0,%d1
	jbra .L136
.L135:
	unlk %fp
	rts
	.size	clear_breaks, .-clear_breaks
	.align	2
	.globl	disable_break
	.type	disable_break, @function
disable_break:
	link.w %fp,#0
	pea 10.w
	clr.l -(%sp)
	move.l 8(%fp),-(%sp)
	jbsr strtoul
	lea (12,%sp),%sp
	tst.l errno
	jbne .L139
	cmp.w #15,%d0
	jbhi .L139
	and.l #65535,%d0
	lsl.l #3,%d0
	move.l %d0,%a0
	add.l #breakpoint+6,%a0
	move.w (%a0),%d0
	btst #0,%d0
	jbeq .L139
	and.w #-3,%d0
	move.w %d0,(%a0)
	jbra .L144
.L139:
	jbsr cmd_error
.L144:
	unlk %fp
	rts
	.size	disable_break, .-disable_break
	.align	2
	.globl	enable_break
	.type	enable_break, @function
enable_break:
	link.w %fp,#0
	pea 10.w
	clr.l -(%sp)
	move.l 8(%fp),-(%sp)
	jbsr strtoul
	lea (12,%sp),%sp
	tst.l errno
	jbne .L146
	cmp.w #15,%d0
	jbhi .L146
	and.l #65535,%d0
	lsl.l #3,%d0
	move.l %d0,%a0
	add.l #breakpoint+6,%a0
	move.w (%a0),%d0
	btst #0,%d0
	jbeq .L146
	or.w #2,%d0
	move.w %d0,(%a0)
	jbra .L151
.L146:
	jbsr cmd_error
.L151:
	unlk %fp
	rts
	.size	enable_break, .-enable_break
	.align	2
	.globl	create_break
	.type	create_break, @function
create_break:
	link.w %fp,#0
	movm.l #0x3800,-(%sp)
	move.l radix,-(%sp)
	clr.l -(%sp)
	move.l 8(%fp),-(%sp)
	jbsr strtoul
	lea (12,%sp),%sp
	tst.l errno
	jbne .L175
	move.l %d0,%d2
	and.l #4194303,%d2
	btst #0,%d0
	jbne .L175
	cmp.l #4095,%d2
	jble .L175
	cmp.l #3670015,%d2
	jbgt .L175
	moveq #0,%d3
	lea breakpoint+6,%a1
	moveq #0,%d1
.L159:
	btst #0,1(%a1)
	jbeq .L160
	lea breakpoint,%a0
	move.w (%a0,%d1.l),%d4
	move.w %d4,%d0
	swap %d0
	mov.w 2(%a0,%d1.l),%d0
	cmp.l %d0,%d2
	jbeq .L175
.L160:
	addq.l #1,%d3
	addq.l #8,%d1
	addq.l #8,%a1
	moveq #16,%d0
	cmp.l %d3,%d0
	jbne .L159
	moveq #0,%d1
	lea breakpoint+6,%a0
.L164:
	btst #0,1(%a0)
	jbeq .L165
	addq.l #1,%d1
	addq.l #8,%a0
	moveq #16,%d4
	cmp.l %d1,%d4
	jbeq .L175
	jbra .L164
.L165:
	cmp.l #4161535,%d2
	jbgt .L175
	lea breakpoint,%a0
	lsl.l #3,%d1
	move.l %d2,%d0
	clr.w %d0
	swap %d0
	move.w %d0,(%a0,%d1.l)
	move.w %d2,2(%a0,%d1.l)
	move.l %d1,%a0
	add.l #breakpoint+4,%a0
	move.l %d2,%a1
	move.w (%a1),(%a0)
	move.l %d1,%a0
	add.l #breakpoint+6,%a0
	move.w #3,(%a0)
	jbra .L170
.L175:
	jbsr cmd_error
.L170:
	movm.l -12(%fp),#0x1c
	unlk %fp
	rts
	.size	create_break, .-create_break
	.align	2
	.globl	execute_trace
	.type	execute_trace, @function
execute_trace:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%d2
	jbsr check_pc
	tst.l %d0
	jblt .L177
	lsl.l #3,%d0
	move.l %d0,%a2
	add.l #breakpoint+6,%a2
	and.w #-3,(%a2)
	pea 1.w
	jbsr Trace
	or.w #2,(%a2)
	subq.l #1,%d2
	addq.l #4,%sp
.L177:
	tst.l %d2
	jble .L181
	move.l %d2,-(%sp)
	jbsr Trace
	addq.l #4,%sp
.L181:
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	execute_trace, .-execute_trace
	.align	2
	.globl	execute_go
	.type	execute_go, @function
execute_go:
	link.w %fp,#0
	move.l %a2,-(%sp)
	jbsr check_pc
	tst.l %d0
	jblt .L183
	lsl.l #3,%d0
	move.l %d0,%a2
	add.l #breakpoint+6,%a2
	and.w #-3,(%a2)
	pea 1.w
	jbsr Trace
	or.w #2,(%a2)
	addq.l #4,%sp
.L183:
	pea 1.w
	jbsr Go
	addq.l #4,%sp
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	execute_go, .-execute_go
	.align	2
	.globl	execute_skipover
	.type	execute_skipover, @function
execute_skipover:
	link.w %fp,#0
	movm.l #0x3800,-(%sp)
	move.w state+68,%d0
	move.w %d0,%d4
	swap %d4
	mov.w state+70,%d4
	move.l %d4,%a0
	move.w (%a0),%d2
	move.w %d2,%d1
	ext.l %d1
	move.l %d1,%d0
	and.l #65408,%d0
	cmp.l #20096,%d0
	jbne .L187
	move.w %d2,-(%sp)
	clr.w -(%sp)
	jbsr size_ea
	addq.l #4,%sp
	jbra .L194
.L187:
	move.l %d1,%d0
	and.l #61440,%d0
	cmp.l #24576,%d0
	jbne .L190
	tst.b %d1
	jbne .L192
	move.w #2,%d0
	jbra .L194
.L192:
	moveq #0,%d0
.L194:
	addq.l #2,%d0
	jbra .L189
.L190:
	move.l %d1,%d3
	and.l #61688,%d3
	cmp.l #20680,%d3
	jbeq .L195
	move.l %d1,%d0
	and.l #65520,%d0
	cmp.l #20032,%d0
	jbeq .L197
	cmp.w #20086,%d2
	jbeq .L197
	cmp.l #20728,%d3
	jbne .L200
	moveq #7,%d0
	and.l %d1,%d0
	moveq #2,%d1
	cmp.l %d0,%d1
	jbeq .L195
	move.b #3,%d1
	cmp.l %d0,%d1
	jbne .L197
	moveq #6,%d0
	jbra .L189
.L200:
	pea 1.w
	jbsr execute_trace
	addq.l #4,%sp
	jbra .L205
.L195:
	moveq #4,%d0
	jbra .L189
.L197:
	moveq #2,%d0
.L189:
	add.l %d4,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,breakpoint+128
	move.w %d0,breakpoint+130
	move.l %d0,%a0
	move.w (%a0),breakpoint+132
	move.w #3,breakpoint+134
	jbsr execute_go
.L205:
	movm.l -12(%fp),#0x1c
	unlk %fp
	rts
	.size	execute_skipover, .-execute_skipover
	.align	2
	.globl	lookup
	.type	lookup, @function
lookup:
	link.w %fp,#0
	movm.l #0x3820,-(%sp)
	move.l 12(%fp),%d2
	move.b 19(%fp),%d4
	clr.l errno
	move.l %d2,-(%sp)
	jbsr strlen
	addq.l #4,%sp
	move.w %d0,%d3
	move.l 8(%fp),%a2
	jbra .L207
.L208:
	cmp.w %d0,%d3
	jbne .L209
	moveq #0,%d0
	move.w 4(%a2),%d0
	moveq #0,%d1
	move.w 6(%a2),%d1
	tst.b %d4
	jbeq .L211
	move.l %d2,-(%sp)
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr strcasecmp
	jbra .L218
.L211:
	move.l %d2,-(%sp)
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	move.l %d1,-(%sp)
	jbsr strcmp
.L218:
	addq.l #8,%sp
	tst.l %d0
	seq %d0
	neg.b %d0
	jbeq .L209
	move.w (%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a2),%d0
	jbra .L215
.L209:
	lea (10,%a2),%a2
.L207:
	move.w 8(%a2),%d0
	jbne .L208
	moveq #1,%d0
	move.l %d0,errno
	clr.b %d0
.L215:
	movm.l -16(%fp),#0x41c
	unlk %fp
	rts
	.size	lookup, .-lookup
	.section	.rodata.str1.1
.LC9:
	.string	"         "
.LC10:
	.string	">>"
	.globl	__mulsi3
.LC11:
	.string	"%02lx\n"
.LC12:
	.string	" %d\n"
.LC13:
	.string	"%04lx : "
.LC14:
	.string	"%08lx : "
.LC15:
	.string	"%06lx : "
.LC16:
	.string	"%06lx:  "
.LC17:
	.ascii	"B <addr>  set break                    G  go from current PC"
	.ascii	"\nBC <n>  clear break                    N [<radix>]  set/as"
	.ascii	"k radix\nBD <n>  disable break                  Q  quit\nBE "
	.ascii	"<n>  enable break                   R [<reg>]  register(s) d"
	.ascii	"isplay\nBL   list breaks                       S  step over "
	.ascii	"b"
	.string	"ranch or call\nD [<addr> [<lth>]]  dump               T [<n>]  trace N instructions\n DB, DW, DL, DC  format                U [<addr> [<lth>]]  unassemble\nI <port>  input byte port\nO <port> <byte>  out to byte port\n                        ? or H  print help\n"
	.text
	.align	2
	.globl	debug68
	.type	debug68, @function
debug68:
	link.w %fp,#-84
	movm.l #0x3e3c,-(%sp)
	moveq #16,%d0
	move.l %d0,radix
	sub.l %a5,%a5
	moveq #64,%d5
	move.w #2,%a4
	moveq #4,%d6
.L312:
	pea state
	jbsr print_state
	pea 6.w
	move.w state+68,%d2
	move.w %d2,%d1
	swap %d1
	mov.w state+70,%d1
	move.l %d1,-(%sp)
	pea 2.w
	jbsr dump_memory
	pea .LC9
	lea cprintf,%a2
	jbsr (%a2)
	move.w state+68,%d3
	move.w %d3,%d4
	swap %d4
	mov.w state+70,%d4
	move.l %d4,-(%sp)
	jbsr pinstr
	pea .LC2
	jbsr (%a2)
	lea (28,%sp),%sp
.L313:
	pea .LC10
	jbsr cprintf
	pea 80.w
	lea (-84,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (12,%sp),%sp
	tst.l %d0
	jbeq .L313
	move.l %a2,-4(%fp)
	move.l __ctype_ptr,%a3
	jbra .L225
.L226:
	addq.l #1,%a0
	move.l %a0,-4(%fp)
.L225:
	move.l -4(%fp),%a0
	move.b (%a0),%d0
	ext.w %d0
	move.w %d0,%a2
	btst #3,(%a2,%a3.l)
	jbne .L226
	lea (1,%a0),%a1
	move.l %a1,-4(%fp)
	move.l %a2,%a0
	btst #1,(%a2,%a3.l)
	jbeq .L228
	lea (-32,%a2),%a0
.L228:
	lea (-66,%a0),%a0
	moveq #19,%d0
	cmp.l %a0,%d0
	jbcs .L230
	add.l %a0,%a0
	.set .LI242,.+2
	move.w .L242-.LI242.b(%pc,%a0.l),%d0
	jmp %pc@(2,%d0:w)
	.align	2
	.swbeg	&20
.L242:
	.word .L231-.L242
	.word .L230-.L242
	.word .L232-.L242
	.word .L230-.L242
	.word .L230-.L242
	.word .L233-.L242
	.word .L230-.L242
	.word .L234-.L242
	.word .L230-.L242
	.word .L230-.L242
	.word .L230-.L242
	.word .L230-.L242
	.word .L235-.L242
	.word .L236-.L242
	.word .L230-.L242
	.word .L298-.L242
	.word .L238-.L242
	.word .L239-.L242
	.word .L240-.L242
	.word .L241-.L242
.L231:
	move.b (%a1)+,%d0
	ext.w %d0
	move.l %a1,%d1
	move.l %a1,-4(%fp)
	move.w %d0,%a0
	btst #1,(%a0,%a3.l)
	jbeq .L243
	lea (-32,%a0),%a0
.L243:
	moveq #68,%d2
	cmp.l %a0,%d2
	jbeq .L248
	jblt .L251
	moveq #32,%d3
	cmp.l %a0,%d3
	jbeq .L246
	moveq #67,%d0
	cmp.l %a0,%d0
	jbne .L309
	jbra .L247
.L251:
	moveq #69,%d2
	cmp.l %a0,%d2
	jbeq .L249
	moveq #76,%d3
	cmp.l %a0,%d3
	jbne .L309
	jbra .L250
.L247:
	move.l %d1,-(%sp)
	jbsr clear_breaks
	jbra .L308
.L248:
	move.l %d1,-(%sp)
	jbsr disable_break
	jbra .L308
.L249:
	move.l %d1,-(%sp)
	jbsr enable_break
	jbra .L308
.L250:
	move.l %d1,-(%sp)
	jbsr list_breaks
	jbra .L308
.L246:
	move.l %d1,-(%sp)
	jbsr create_break
	jbra .L308
.L232:
	move.b (%a1)+,%d0
	ext.w %d0
	move.l %a1,%d1
	move.l %a1,-4(%fp)
	move.w %d0,%a0
	btst #1,(%a0,%a3.l)
	jbeq .L252
	lea (-32,%a0),%a0
.L252:
	moveq #67,%d0
	cmp.l %a0,%d0
	jbeq .L256
	jblt .L259
	moveq #66,%d2
	cmp.l %a0,%d2
	jbne .L254
	jbra .L255
.L259:
	moveq #76,%d3
	cmp.l %a0,%d3
	jbeq .L257
	moveq #87,%d0
	cmp.l %a0,%d0
	jbne .L254
	jbra .L258
.L257:
	move.w #4,%a4
	jbra .L260
.L256:
	move.w #3,%a4
	jbra .L260
.L255:
	move.w #1,%a4
	jbra .L260
.L258:
	move.w #2,%a4
	jbra .L260
.L254:
	subq.l #1,%d1
	move.l %d1,-4(%fp)
.L260:
	move.l radix,-(%sp)
	move.l %fp,%d2
	subq.l #4,%d2
	move.l %d2,-(%sp)
	move.l -4(%fp),-(%sp)
	lea strtoul,%a2
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l errno
	jbne .L261
	move.l %d0,%a5
.L261:
	move.l radix,-(%sp)
	move.l %d2,-(%sp)
	move.l -4(%fp),-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l errno
	jbne .L263
	tst.l %d0
	jble .L263
	move.l %d0,%d5
.L263:
	lea dump_memory,%a2
	moveq #3,%d1
	cmp.l %a4,%d1
	jbeq .L266
	move.l %a4,-(%sp)
	pea -1(%a4,%d5.l)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	move.l %a4,-(%sp)
	move.l %d0,-(%sp)
	jbsr __mulsi3
	addq.l #8,%sp
	move.l %d0,%d5
	move.l %d2,-(%sp)
	move.l %a5,-(%sp)
	move.l %a4,-(%sp)
	jbsr (%a2)
	add.l %d5,%a5
	jbra .L310
.L266:
	move.l %d0,-(%sp)
	move.l %a5,-(%sp)
	pea 3.w
	jbsr (%a2)
	move.l %a5,-(%sp)
	jbsr strlen
	addq.l #4,%sp
	lea 1(%a5,%d0.l),%a5
.L310:
	lea (12,%sp),%sp
	jbra .L313
.L233:
	jbsr execute_go
	jbra .L312
.L234:
	move.l radix,-(%sp)
	clr.l -(%sp)
	move.l %a1,-(%sp)
	jbsr strtoul
	lea (12,%sp),%sp
	tst.l errno
	jbne .L313
	and.l #16383,%d0
	move.l %d0,%a0
	moveq #0,%d0
	move.b -32768(%a0),%d0
	move.l %d0,-(%sp)
	pea .LC11
	jbra .L311
.L235:
	pea 10.w
	clr.l -(%sp)
	move.l %a1,-(%sp)
	jbsr strtoul
	move.l %d0,%d1
	subq.l #2,%d0
	lea (12,%sp),%sp
	moveq #14,%d2
	cmp.l %d0,%d2
	jbcc .L269
	move.l radix,-(%sp)
	pea .LC12
.L311:
	jbsr cprintf
	addq.l #8,%sp
	jbra .L313
.L269:
	move.l %d1,radix
	jbra .L313
.L236:
	move.l radix,-(%sp)
	move.l %fp,%d3
	subq.l #4,%d3
	move.l %d3,-(%sp)
	move.l %a1,-(%sp)
	lea strtoul,%a2
	jbsr (%a2)
	move.l %d0,%d2
	lea (12,%sp),%sp
	tst.l errno
	jbne .L313
	move.l radix,-(%sp)
	move.l %d3,-(%sp)
	move.l -4(%fp),-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l errno
	jbne .L313
	and.l #16383,%d2
	move.l %d2,%a0
	move.b %d0,-32768(%a0)
	jbra .L313
.L238:
	pea -4(%fp)
	move.l %a1,-(%sp)
	jbsr token
	addq.l #8,%sp
	tst.l %d0
	jbeq .L312
	pea 1.w
	move.l %d0,-(%sp)
	pea builtin
	jbsr lookup
	move.l %d0,%d2
	lea (12,%sp),%sp
	tst.l errno
	jbeq .L275
.L309:
	jbsr cmd_error
	jbra .L313
.L275:
	cmp.l #255,%d0
	jbne .L277
	btst #5,state+74
	jbne .L279
	move.b #16,%d2
	jbra .L281
.L277:
	add.l %d2,%d0
	add.l %d0,%d0
	lea state,%a0
	move.l (%a0,%d0.l),%d1
	move.l #.LC13,%d0
	moveq #18,%d3
	cmp.l %d2,%d3
	jbeq .L284
.L282:
	move.l #.LC14,%d0
	moveq #14,%d3
	cmp.l %d2,%d3
	jbge .L284
	move.l #.LC15,%d0
.L284:
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	jbsr cprintf
	pea 80.w
	lea (-84,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (16,%sp),%sp
	tst.l %d0
	jbeq .L313
	move.l radix,-(%sp)
	clr.l -(%sp)
	move.l %a2,-(%sp)
	jbsr strtoul
	move.l %d0,%d3
	lea (12,%sp),%sp
	tst.l errno
	jbne .L313
	lea state,%a0
	move.l %d2,%d0
	add.l %d2,%d0
	add.l %d0,%d0
	move.l %d3,%d1
	clr.w %d1
	swap %d1
	move.w %d1,(%a0,%d0.l)
	move.w %d3,2(%a0,%d0.l)
	jbra .L313
.L239:
	jbsr execute_skipover
	jbra .L312
.L240:
	move.l radix,-(%sp)
	pea -4(%fp)
	move.l %a1,-(%sp)
	jbsr strtoul
	lea (12,%sp),%sp
	tst.l %d0
	jbgt .L289
	moveq #1,%d0
.L289:
	move.l %d0,-(%sp)
	jbsr execute_trace
	addq.l #4,%sp
	jbra .L312
.L241:
	move.l radix,-(%sp)
	move.l %fp,%d2
	subq.l #4,%d2
	move.l %d2,-(%sp)
	move.l %a1,-(%sp)
	lea strtoul,%a2
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l errno
	jbne .L291
	moveq #-2,%d4
	and.l %d0,%d4
.L291:
	move.l radix,-(%sp)
	move.l %d2,-(%sp)
	move.l -4(%fp),-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l errno
	jbne .L293
	tst.l %d0
	jble .L293
	move.l %d0,%d6
.L293:
	move.l %d6,%d2
	jbra .L296
.L297:
	move.l %d4,-(%sp)
	pea .LC16
	lea cprintf,%a2
	jbsr (%a2)
	move.l %d4,-(%sp)
	jbsr pinstr
	add.l %d0,%d4
	pea .LC2
	jbsr (%a2)
	lea (16,%sp),%sp
.L296:
	dbra %d2,.L297
	clr.w %d2
	subq.l #1,%d2
	jbcc .L297
	jbra .L313
.L230:
	pea .LC17
	jbsr cprintf
.L308:
	addq.l #4,%sp
	jbra .L313
.L279:
	moveq #15,%d2
.L281:
	move.l %d2,%d0
	add.l %d2,%d0
	add.l %d0,%d0
	lea state,%a0
	move.l (%a0,%d0.l),%d1
	jbra .L282
.L298:
	movm.l -120(%fp),#0x3c7c
	unlk %fp
	rts
	.size	debug68, .-debug68
	.section	.rodata.str1.1
.LC18:
	.string	"D0"
.LC19:
	.string	"D1"
.LC20:
	.string	"D2"
.LC21:
	.string	"D3"
.LC22:
	.string	"D4"
.LC23:
	.string	"D5"
.LC24:
	.string	"D6"
.LC25:
	.string	"D7"
.LC26:
	.string	"A0"
.LC27:
	.string	"A1"
.LC28:
	.string	"A2"
.LC29:
	.string	"A3"
.LC30:
	.string	"A4"
.LC31:
	.string	"A5"
.LC32:
	.string	"A6"
.LC33:
	.string	"A7"
.LC34:
	.string	"SSP"
.LC35:
	.string	"USP"
.LC36:
	.string	"PC"
.LC37:
	.string	"SR"
.LC38:
	.string	"SP"
	.section	.rodata
	.align	2
	.type	builtin, @object
	.size	builtin, 220
builtin:
	.long	0
	.long	.LC18
	.word	2
	.long	1
	.long	.LC19
	.word	2
	.long	2
	.long	.LC20
	.word	2
	.long	3
	.long	.LC21
	.word	2
	.long	4
	.long	.LC22
	.word	2
	.long	5
	.long	.LC23
	.word	2
	.long	6
	.long	.LC24
	.word	2
	.long	7
	.long	.LC25
	.word	2
	.long	8
	.long	.LC26
	.word	2
	.long	9
	.long	.LC27
	.word	2
	.long	10
	.long	.LC28
	.word	2
	.long	11
	.long	.LC29
	.word	2
	.long	12
	.long	.LC30
	.word	2
	.long	13
	.long	.LC31
	.word	2
	.long	14
	.long	.LC32
	.word	2
	.long	255
	.long	.LC33
	.word	2
	.long	15
	.long	.LC34
	.word	3
	.long	16
	.long	.LC35
	.word	3
	.long	17
	.long	.LC36
	.word	2
	.long	18
	.long	.LC37
	.word	2
	.long	255
	.long	.LC38
	.word	2
	.long	0
	.long	0
	.word	0
	.section	.rodata.str1.1
.LC39:
	.string	" %02hx"
.LC40:
	.string	" %04hx"
.LC41:
	.string	"%c"
.LC42:
	.string	" %08lx"
	.section	.rodata
	.align	4
	.type	fmt.1804, @object
	.size	fmt.1804, 16
fmt.1804:
	.long	.LC39
	.long	.LC40
	.long	.LC41
	.long	.LC42
	.comm	instr,2,2
	.comm	break_taken,1,1
	.comm	errno,4,4
	.comm	radix,4,4
	.comm	charsave,1,1
	.comm	breakpoint,136,2
	.ident	"GCC: (GNU) 4.1.1"
