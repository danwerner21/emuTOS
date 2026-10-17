#NO_APP
	.file	"main68.c"
	.text
	.align	2
	.type	fromhex, @function
fromhex:
	link.w %fp,#0
	move.b 11(%fp),%d1
	move.b %d1,%d0
	add.b #-48,%d0
	cmp.b #9,%d0
	jbhi .L2
	move.b %d1,%d0
	ext.w %d0
	move.w %d0,%a0
	lea (-48,%a0),%a0
	jbra .L4
.L2:
	move.b %d1,%d0
	add.b #-97,%d0
	cmp.b #5,%d0
	jbhi .L5
	move.b %d1,%d0
	ext.w %d0
	move.w %d0,%a0
	lea (-87,%a0),%a0
	jbra .L4
.L5:
	move.b %d1,%d0
	add.b #-65,%d0
	cmp.b #5,%d0
	jbls .L7
	move.w #-1,%a0
	jbra .L4
.L7:
	move.b %d1,%d0
	ext.w %d0
	move.w %d0,%a0
	lea (-55,%a0),%a0
.L4:
	move.l %a0,%d0
	unlk %fp
	rts
	.size	fromhex, .-fromhex
	.align	2
	.globl	do_remark
	.type	do_remark, @function
do_remark:
	link.w %fp,#0
	unlk %fp
	rts
	.size	do_remark, .-do_remark
	.align	2
	.globl	is_cmd_head
	.type	is_cmd_head, @function
is_cmd_head:
	link.w %fp,#0
	movm.l #0x3020,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d3
	move.l __ctype_ptr,%a1
	sub.l %a0,%a0
	moveq #1,%d2
	jbra .L13
.L14:
	move.b (%a2,%a0.l),%d1
	move.b %d1,%d0
	ext.w %d0
	move.b (%a1,%d0.w),%d0
	and.b #-105,%d0
	jbne .L15
	cmp.b #13,%d1
	jbeq .L15
	cmp.b #10,%d1
	jbeq .L15
	cmp.b #9,%d1
	seq %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
	jbra .L19
.L15:
	moveq #1,%d0
.L19:
	and.l %d0,%d2
	addq.l #1,%a0
.L13:
	cmp.l %a0,%d3
	jble .L20
	tst.l %d2
	jbne .L14
.L20:
	move.l %d2,%d0
	movm.l (%sp)+,#0x40c
	unlk %fp
	rts
	.size	is_cmd_head, .-is_cmd_head
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"\nBuilt-in commands:\n"
.LC1:
	.string	"%12s : %s\n"
.LC2:
	.string	"\nCommand syntax:  [u|s] [<builtin>|<file[.ext]>] [<args> ...]\n    <file[.ext]> may be *.CMD *.OUT *.68K *.SYS *.ELF  (all with Magic ID)\n\n"
	.text
	.align	2
	.globl	help
	.type	help, @function
help:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	pea .LC0
	jbsr cprintf
	addq.l #4,%sp
	sub.l %a2,%a2
	jbra .L24
.L25:
	lea cmd_table+16,%a0
	move.w (%a0,%a2.l),%d2
	move.w %d2,%d1
	swap %d1
	mov.w 2(%a0,%a2.l),%d1
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	pea .LC1
	jbsr (%a1)
	lea (20,%a2),%a2
	lea (12,%sp),%sp
.L24:
	lea cmd_table,%a0
	move.w (%a0,%a2.l),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a0,%a2.l),%d0
	lea cprintf,%a1
	tst.l %d0
	jbne .L25
	pea .LC2
	jbsr (%a1)
	addq.l #4,%sp
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	help, .-help
	.section	.rodata.str1.1
.LC3:
	.string	"Error: %s\n"
.LC4:
	.string	"Error: Unknown error %d. Hold tight.\n"
	.text
	.align	2
	.globl	f_perror
	.type	f_perror, @function
f_perror:
	link.w %fp,#0
	move.l 8(%fp),%d0
	lea cprintf,%a1
	moveq #19,%d1
	cmp.l %d0,%d1
	jblt .L29
	add.l %d0,%d0
	add.l %d0,%d0
	lea fatfs_errmsg.2196,%a0
	move.l (%a0,%d0.l),-(%sp)
	pea .LC3
	jbra .L33
.L29:
	move.l %d0,-(%sp)
	pea .LC4
.L33:
	jbsr (%a1)
	addq.l #8,%sp
	unlk %fp
	rts
	.size	f_perror, .-f_perror
	.section	.rodata.str1.1
.LC5:
	.string	"(%s)  %4d-%02d-%02d  at  %2d:%02d:%02d\n"
	.text
	.align	2
	.globl	do_today
	.type	do_today, @function
do_today:
	link.w %fp,#-8
	move.l %d2,-(%sp)
	pea 2.w
	jbsr daytime_c
	move.l %d1,%d2
	clr.w %d2
	swap %d2
	move.w %d2,-4(%fp)
	move.w %d1,-2(%fp)
	move.l %d0,%d2
	clr.w %d2
	swap %d2
	move.w %d2,-8(%fp)
	and.l #65535,%d0
	move.w %d0,-6(%fp)
	moveq #0,%d2
	move.b -1(%fp),%d2
	move.l %d2,-(%sp)
	moveq #0,%d2
	move.b -2(%fp),%d2
	move.l %d2,-(%sp)
	moveq #0,%d2
	move.w -4(%fp),%d2
	move.l %d2,-(%sp)
	lsr.l #4,%d0
	moveq #0,%d1
	not.b %d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	move.b -6(%fp),%d0
	lsr.l #4,%d0
	moveq #15,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	moveq #0,%d0
	move.w -8(%fp),%d0
	move.l %d0,-(%sp)
	move.b -5(%fp),%d0
	lsl.l #2,%d0
	moveq #60,%d1
	and.l %d1,%d0
	lea dow,%a0
	move.l (%a0,%d0.l),-(%sp)
	pea .LC5
	jbsr cprintf
	lea (36,%sp),%sp
	move.l -12(%fp),%d2
	unlk %fp
	rts
	.size	do_today, .-do_today
	.align	2
	.globl	readline
	.type	readline, @function
readline:
	link.w %fp,#-8
	movm.l #0x3820,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d4
	move.l 16(%fp),%d3
	moveq #0,%d2
	jbra .L56
.L38:
	pea -6(%fp)
	pea 1.w
	pea -1(%fp)
	move.l %d3,-(%sp)
	jbsr f_read
	lea (16,%sp),%sp
	tst.l %d0
	jbne .L39
	move.b #1,%d0
	cmp.l -6(%fp),%d0
	jbeq .L41
.L39:
	clr.b (%a2,%d2.l)
	tst.l %d2
	jbne .L42
	moveq #-1,%d2
	jbra .L42
.L41:
	move.b -1(%fp),%d0
	cmp.b #10,%d0
	jbeq .L55
	tst.b %d0
	jbeq .L55
	cmp.b #13,%d0
	jbeq .L56
	move.b %d0,(%a2,%d2.l)
	addq.l #1,%d2
.L56:
	move.l %d4,%d0
	subq.l #1,%d0
	cmp.l %d2,%d0
	jbhi .L38
.L55:
	clr.b (%a2,%d2.l)
.L42:
	move.l %d2,%d0
	movm.l -24(%fp),#0x41c
	unlk %fp
	rts
	.size	readline, .-readline
	.align	2
	.globl	extend_filename
	.type	extend_filename, @function
extend_filename:
	link.w %fp,#0
	movm.l #0x3030,-(%sp)
	move.l 8(%fp),%a3
	move.l (%a3),%d2
	clr.l -(%sp)
	move.l %d2,-(%sp)
	jbsr f_stat
	addq.l #8,%sp
	tst.l %d0
	jbeq .L58
	move.l %d2,-(%sp)
	jbsr strlen
	addq.l #4,%sp
	move.l %d0,%a2
	lea (%a2,%d2.l),%a0
	jbra .L60
.L61:
	cmp.l %a0,%d2
	jbeq .L62
	move.b (%a0),%d0
	cmp.b #47,%d0
	jbeq .L62
	cmp.b #58,%d0
	jbeq .L62
	cmp.b #92,%d0
	jbne .L66
.L62:
	move.l %d2,%d3
	subq.l #4,%d3
	move.l %d2,-(%sp)
	move.l %d3,-(%sp)
	jbsr strcpy
	move.l %d3,(%a3)
	lea (%a2,%d3.l),%a0
	move.b #46,(%a0)+
	move.l %a0,%a3
	lea exts,%a2
	addq.l #8,%sp
	jbra .L67
.L68:
	move.l %d0,-(%sp)
	move.l %a3,-(%sp)
	jbsr strcpy
	clr.l -(%sp)
	move.l %d3,-(%sp)
	jbsr f_stat
	addq.l #4,%a2
	lea (16,%sp),%sp
	tst.l %d0
	jbne .L67
	move.l %d3,%d2
	jbra .L58
.L67:
	move.l (%a2),%d0
	jbne .L68
	clr.b -1(%a3)
	jbra .L71
.L66:
	cmp.b #46,%d0
	jbeq .L71
.L60:
	subq.l #1,%a0
	cmp.w #0,%a0
	jbne .L61
.L71:
	moveq #0,%d2
.L58:
	move.l %d2,%d0
	movm.l -16(%fp),#0xc0c
	unlk %fp
	rts
	.size	extend_filename, .-extend_filename
	.align	2
	.globl	run_program
	.type	run_program, @function
run_program:
	link.w %fp,#0
	move.l h_m_a,%a0
	move.l %a0,-(%sp)
	pea -4096(%a0)
	move.l 12(%fp),-(%sp)
	tst.w 10(%fp)
	seq %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
	move.l %d0,-(%sp)
	jbsr _run_us_mode
	lea (16,%sp),%sp
	unlk %fp
	rts
	.size	run_program, .-run_program
	.section	.rodata.str1.1
.LC6:
	.string	"Cannot read ELF file header\n"
.LC7:
	.string	"Bad ELF header\n"
.LC8:
	.string	"Not a 32-bit ELF file.\n"
.LC9:
	.string	"ELF file is not an executable.\n"
.LC10:
	.string	"ELF file is not for 68000 processor.\n"
	.globl	__mulsi3
.LC11:
	.string	"Cannot read ELF program header.\n"
.LC12:
	.string	"ELF executable is dynamically linked.\n"
.LC13:
	.string	"Loading %d bytes from file offset 0x%x to memory at 0x%x\n"
.LC14:
	.string	"Unable to read segment from ELF file.\n"
.LC15:
	.string	"ELF executable requires an interpreter.\n"
.LC16:
	.string	"Linux kernel detected:"
.LC17:
	.string	" does not support KISS68030.\n"
.LC18:
	.string	" wrong bootinfo version.\n"
.LC19:
	.string	" creating bootinfo at 0x%x\n"
.LC20:
	.string	"initrd="
.LC21:
	.string	" "
.LC22:
	.string	"Loading initrd \"%s\": %d bytes at 0x%x\n"
.LC23:
	.string	"Unable to load initrd.\n"
.LC24:
	.string	"user"
.LC25:
	.string	"supervisor"
.LC26:
	.string	"Entry at 0x%x in %s mode\n"
.LC27:
	.string	"Unable to open \"%s\": No initrd.\n"
	.text
	.align	2
	.globl	load_elf_executable
	.type	load_elf_executable, @function
load_elf_executable:
	link.w %fp,#-828
	movm.l #0x3f3c,-(%sp)
	move.l 12(%fp),%d7
	move.l 16(%fp),%a4
	clr.l -(%sp)
	move.l %a4,-(%sp)
	jbsr f_lseek
	pea -4(%fp)
	pea 52.w
	pea -88(%fp)
	move.l %a4,-(%sp)
	jbsr f_read
	lea (24,%sp),%sp
	tst.l %d0
	jbne .L78
	move.b #52,%d0
	cmp.l -4(%fp),%d0
	jbeq .L80
.L78:
	pea .LC6
	jbra .L151
.L80:
	cmp.b #127,-88(%fp)
	jbne .L82
	cmp.b #69,-87(%fp)
	jbne .L82
	cmp.b #76,-86(%fp)
	jbne .L82
	cmp.b #70,-85(%fp)
	jbne .L82
	cmp.b #1,-82(%fp)
	jbeq .L87
.L82:
	pea .LC7
	jbra .L151
.L87:
	cmp.b #1,-84(%fp)
	jbne .L88
	cmp.b #2,-83(%fp)
	jbne .L88
	tst.b -81(%fp)
	jbne .L88
	tst.b -80(%fp)
	jbeq .L92
.L88:
	pea .LC8
	jbra .L151
.L92:
	cmp.w #2,-72(%fp)
	jbeq .L93
	pea .LC9
	jbra .L151
.L93:
	cmp.w #4,-70(%fp)
	jbne .L95
	moveq #0,%d3
	moveq #0,%d4
	moveq #0,%d6
	move.w #-1,%a3
	jbra .L97
.L95:
	pea .LC10
	jbra .L151
.L98:
	move.w -60(%fp),%d1
	move.w %d1,%d2
	swap %d2
	mov.w -58(%fp),%d2
	moveq #0,%d0
	move.w -46(%fp),%d0
	move.l %d0,-(%sp)
	move.l %d4,-(%sp)
	jbsr __mulsi3
	addq.l #8,%sp
	move.l %d2,%a0
	pea (%a0,%d0.l)
	move.l %a4,-(%sp)
	move.l #f_lseek,%d5
	move.l %d5,%a1
	jbsr (%a1)
	move.l %fp,%d2
	subq.l #4,%d2
	move.l %d2,-(%sp)
	pea 32.w
	pea -36(%fp)
	move.l %a4,-(%sp)
	lea f_read,%a5
	jbsr (%a5)
	lea (24,%sp),%sp
	tst.l %d0
	jbne .L99
	move.b #32,%d0
	cmp.l -4(%fp),%d0
	jbeq .L101
.L99:
	pea .LC11
	jbra .L151
.L101:
	move.w -36(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -34(%fp),%d0
	moveq #2,%d1
	cmp.l %d0,%d1
	jbeq .L104
	jbcs .L106
	move.b #1,%d1
	cmp.l %d0,%d1
	jbne .L102
	jbra .L103
.L106:
	moveq #3,%d1
	cmp.l %d0,%d1
	jbeq .L105
	move.b #5,%d1
	cmp.l %d0,%d1
	jbne .L102
.L104:
	pea .LC12
	jbra .L151
.L103:
	move.w -24(%fp),%a0
	move.w %a0,%d0
	swap %d0
	mov.w -22(%fp),%d0
	tst.l %d0
	jbne .L107
	move.w -32(%fp),%a1
	move.w %a1,%d0
	swap %d0
	mov.w -30(%fp),%d0
	add.l #4096,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,-32(%fp)
	move.w %d0,-30(%fp)
	clr.w -24(%fp)
	move.w #4096,-22(%fp)
	move.w -20(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -18(%fp),%d0
	add.l #-4096,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,-20(%fp)
	move.w %d0,-18(%fp)
	move.w -16(%fp),%a0
	move.w %a0,%d0
	swap %d0
	mov.w -14(%fp),%d0
	add.l #-4096,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,-16(%fp)
	move.w %d0,-14(%fp)
.L107:
	move.w -24(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -22(%fp),%d0
	move.l %d0,-(%sp)
	move.w -32(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -30(%fp),%d0
	move.l %d0,-(%sp)
	move.w -20(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -18(%fp),%d0
	move.l %d0,-(%sp)
	pea .LC13
	lea cprintf,%a2
	jbsr (%a2)
	move.w -32(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -30(%fp),%d0
	move.l %d0,-(%sp)
	move.l %a4,-(%sp)
	move.l %d5,%a0
	jbsr (%a0)
	move.l %d2,-(%sp)
	move.w -20(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -18(%fp),%d0
	move.l %d0,-(%sp)
	move.w -24(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -22(%fp),%d0
	move.l %d0,-(%sp)
	move.l %a4,-(%sp)
	jbsr (%a5)
	lea (40,%sp),%sp
	tst.l %d0
	jbne .L109
	move.l -4(%fp),%a0
	move.w -20(%fp),%a1
	move.w %a1,%d0
	swap %d0
	mov.w -18(%fp),%d0
	cmp.l %a0,%d0
	jbeq .L111
.L109:
	pea .LC14
	jbsr (%a2)
	jbra .L152
.L111:
	move.w -16(%fp),%d0
	move.w %d0,%d1
	swap %d1
	mov.w -14(%fp),%d1
	cmp.l %d1,%a0
	jbcc .L112
	move.w -24(%fp),%a1
	move.w %a1,%d0
	swap %d0
	mov.w -22(%fp),%d0
	sub.l %a0,%d1
	move.l %d1,-(%sp)
	clr.l -(%sp)
	pea (%a0,%d0.l)
	jbsr memset
	lea (12,%sp),%sp
.L112:
	move.w -24(%fp),%d0
	move.w %d0,%d1
	swap %d1
	mov.w -22(%fp),%d1
	cmp.l %a3,%d1
	jbcc .L114
	move.l %d1,%a3
.L114:
	move.w -20(%fp),%a0
	move.w %a0,%d0
	swap %d0
	mov.w -18(%fp),%d0
	add.l %d1,%d0
	cmp.l %d0,%d6
	jbcs .L115
	jbra .L150
.L105:
	pea .LC15
	jbra .L151
.L115:
	move.l %d0,%d6
.L150:
	moveq #1,%d3
.L102:
	addq.l #1,%d4
.L97:
	moveq #0,%d0
	move.w -44(%fp),%d0
	cmp.l %d4,%d0
	jbgt .L98
	tst.l %d3
	jbne .L118
	moveq #1,%d0
	jbra .L81
.L118:
	move.b 2(%a3),%d0
	lsl.w #8,%d0
	swap %d0
	clr.w %d0
	moveq #0,%d1
	move.b 3(%a3),%d1
	swap %d1
	clr.w %d1
	or.l %d0,%d1
	moveq #0,%d0
	move.b 4(%a3),%d0
	lsl.l #8,%d0
	or.l %d1,%d0
	or.b 5(%a3),%d0
	cmp.l #1112102426,%d0
	jbne .L120
	pea .LC16
	jbsr cprintf
	addq.l #4,%sp
	move.l %a3,%a0
.L122:
	move.b 6(%a0),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 7(%a0),%d0
	swap %d0
	clr.w %d0
	or.l %d1,%d0
	moveq #0,%d1
	move.b 8(%a0),%d1
	lsl.l #8,%d1
	or.l %d0,%d1
	or.b 9(%a0),%d1
	tst.l %d1
	jbeq .L149
	cmp.l #1653,%d1
	jbne .L125
	move.b 10(%a0),%d0
	lsl.w #8,%d0
	swap %d0
	clr.w %d0
	moveq #0,%d1
	move.b 11(%a0),%d1
	swap %d1
	clr.w %d1
	or.l %d0,%d1
	moveq #0,%d0
	move.b 12(%a0),%d0
	lsl.l #8,%d0
	or.l %d1,%d0
	or.b 13(%a0),%d0
	lea cprintf,%a4
	cmp.l #131072,%d0
	jbeq .L127
	pea .LC18
	jbsr (%a4)
	jbra .L152
.L125:
	addq.l #8,%a0
	jbra .L122
.L127:
	move.l %d6,%a2
	lea (4095,%a2),%a2
	move.l %a2,%d0
	and.w #61440,%d0
	move.l %d0,%a2
	move.l %d0,-(%sp)
	pea .LC19
	jbsr (%a4)
	move.w #1,(%a2)
	clr.w 4(%a2)
	move.w #1653,6(%a2)
	move.w #8,2(%a2)
	addq.l #8,%a2
	move.w #2,(%a2)
	clr.w 4(%a2)
	move.w #2,6(%a2)
	move.w #8,2(%a2)
	lea (8,%a2),%a0
	move.w #4,(%a0)
	clr.w 4(%a0)
	move.w #2,6(%a0)
	move.w #8,2(%a0)
	addq.l #8,%a0
	move.w #3,(%a0)
	clr.w 4(%a0)
	clr.w 6(%a0)
	move.w #8,2(%a0)
	addq.l #8,%a0
	move.w #5,(%a0)
	move.w #12,2(%a0)
	lea (28,%a2),%a2
	clr.w (%a2)
	clr.w 2(%a2)
	move.w h_m_a,4(%a2)
	move.w h_m_a+2,6(%a2)
	moveq #0,%d0
	move.w 2(%a0),%d0
	lea (%a0,%d0.l),%a3
	clr.b -288(%fp)
	move.l 8(%fp),%a2
	addq.l #4,%a2
	moveq #0,%d3
	moveq #1,%d2
	addq.l #8,%sp
	jbra .L129
.L130:
	pea 7.w
	pea .LC20
	move.l (%a2),-(%sp)
	jbsr strncasecmp
	lea (12,%sp),%sp
	tst.l %d0
	jbne .L131
	move.l (%a2),%d3
	addq.l #7,%d3
	jbra .L133
.L131:
	tst.b -288(%fp)
	jbeq .L134
	pea .LC21
	pea -288(%fp)
	jbsr strcat
	addq.l #8,%sp
.L134:
	pea 200.w
	move.l (%a2),-(%sp)
	pea -288(%fp)
	jbsr strncat
	lea (12,%sp),%sp
.L133:
	addq.l #1,%d2
	addq.l #4,%a2
.L129:
	cmp.l %d2,%d7
	jbgt .L130
	move.l %fp,%d2
	add.l #-288,%d2
	move.l %d2,-(%sp)
	jbsr strlen
	addq.l #4,%d0
	moveq #-4,%d1
	and.l %d1,%d0
	move.w #7,(%a3)
	move.w %d0,%a0
	addq.w #4,%a0
	move.w %a0,2(%a3)
	move.l %d0,(%sp)
	move.l %d2,-(%sp)
	pea 4(%a3)
	jbsr memcpy
	moveq #0,%d0
	move.w 2(%a3),%d0
	add.l %d0,%a3
	lea (12,%sp),%sp
	tst.l %d3
	jbeq .L137
	pea 1.w
	move.l %d3,-(%sp)
	add.l #-540,%d2
	move.l %d2,-(%sp)
	jbsr f_open
	lea (12,%sp),%sp
	lea cprintf,%a4
	tst.l %d0
	jbne .L139
	move.w #6,(%a3)
	move.w #12,2(%a3)
	lea (4,%a3),%a2
	move.l %a3,%d0
	add.l #4095,%d0
	and.w #61440,%d0
	add.l #4194304,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,(%a2)
	move.w %d0,2(%a2)
	move.w -816(%fp),%a1
	move.w %a1,%d1
	swap %d1
	mov.w -814(%fp),%d1
	move.l %d1,%d0
	clr.w %d0
	swap %d0
	move.w %d0,4(%a2)
	move.w %d1,6(%a2)
	move.w (%a2),%a0
	move.w %a0,%d0
	swap %d0
	mov.w 2(%a2),%d0
	move.l %d0,-(%sp)
	move.l %d1,-(%sp)
	move.l %d3,-(%sp)
	pea .LC22
	jbsr (%a4)
	pea -4(%fp)
	move.w 4(%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 6(%a2),%d0
	move.l %d0,-(%sp)
	move.w (%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a2),%d0
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	jbsr f_read
	lea (32,%sp),%sp
	tst.l %d0
	jbne .L141
	move.w 4(%a2),%a0
	move.w %a0,%d0
	swap %d0
	mov.w 6(%a2),%d0
	cmp.l -4(%fp),%d0
	jbeq .L143
.L141:
	pea .LC23
	jbsr (%a4)
	addq.l #4,%sp
	jbra .L144
.L143:
	moveq #0,%d0
	move.w 2(%a3),%d0
	add.l %d0,%a3
.L144:
	pea -828(%fp)
	jbsr f_close
	addq.l #4,%sp
.L137:
	clr.w (%a3)
	move.w #4,2(%a3)
	jbsr cpu_cache_disable
	moveq #0,%d2
	jbra .L145
.L120:
	move.l usermode,%d2
	move.w -64(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -62(%fp),%d0
	move.l %d0,-(%sp)
	move.w %d2,-(%sp)
	clr.w -(%sp)
	jbsr run_program
	addq.l #8,%sp
	move.l #.LC24,%d0
	tst.l %d2
	jbne .L147
.L145:
	move.l #.LC25,%d0
.L147:
	move.l %d0,-(%sp)
	move.w -64(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -62(%fp),%d0
	move.l %d0,-(%sp)
	pea .LC26
	jbsr cprintf
	move.l h_m_a,%a0
	move.l %a0,-(%sp)
	pea -4096(%a0)
	move.w -64(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -62(%fp),%d0
	move.l %d0,-(%sp)
	tst.l %d2
	seq %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
	move.l %d0,-(%sp)
	jbsr _run_us_mode
	moveq #1,%d0
	lea (28,%sp),%sp
	jbra .L81
.L139:
	move.l %d3,-(%sp)
	pea .LC27
	jbsr (%a4)
	addq.l #8,%sp
	jbra .L137
.L149:
	pea .LC17
.L151:
	jbsr cprintf
.L152:
	moveq #0,%d0
	addq.l #4,%sp
.L81:
	movm.l -868(%fp),#0x3cfc
	unlk %fp
	rts
	.size	load_elf_executable, .-load_elf_executable
	.section	.rodata.str1.1
.LC28:
	.string	"Cannot read COFF file header.\n"
.LC29:
	.string	"Bad COFF header.\n"
.LC30:
	.string	"COFF file would overwrite processor vectors.\n"
.LC31:
	.string	"Loading section \"%s\": %d bytes from offset 0x%x to memory at 0x%x\n"
.LC32:
	.string	"Unable to read section from COFF file.\n"
.LC33:
	.string	"Zeroing section \"%s\": %d bytes at 0x%x\n"
	.text
	.align	2
	.globl	load_coff_executable
	.type	load_coff_executable, @function
load_coff_executable:
	link.w %fp,#-372
	movm.l #0x3c3c,-(%sp)
	move.l 16(%fp),%d4
	pea -4(%fp)
	pea 368.w
	pea -372(%fp)
	move.l %d4,-(%sp)
	jbsr f_read
	lea (16,%sp),%sp
	tst.l %d0
	jbne .L154
	move.b #23,%d0
	cmp.l -4(%fp),%d0
	jbcs .L156
.L154:
	pea .LC28
	jbra .L182
.L156:
	cmp.w #336,-372(%fp)
	jbne .L158
	move.w -370(%fp),%d2
	jbeq .L158
	cmp.w #8,%d2
	jbhi .L158
	moveq #0,%d1
	jbra .L162
.L158:
	pea .LC29
.L182:
	jbsr cprintf
.L183:
	moveq #0,%d0
	addq.l #4,%sp
	jbra .L157
.L163:
	move.l %d1,%d0
	add.l %d1,%d0
	add.l %d0,%d0
	add.l %d1,%d0
	lsl.l #3,%d0
	lea (%fp,%d0.l),%a0
	move.w -304(%a0),%d5
	move.w %d5,%d0
	swap %d0
	mov.w -302(%a0),%d0
	tst.l %d0
	jbeq .L164
	move.w -312(%a0),%a1
	move.w %a1,%d0
	swap %d0
	mov.w -310(%a0),%d0
	cmp.l #4095,%d0
	jbls .L181
.L164:
	addq.l #1,%d1
.L162:
	moveq #0,%d0
	move.w %d2,%d0
	cmp.l %d1,%d0
	jbne .L163
	moveq #0,%d3
	lea (-304,%fp),%a4
	lea (-308,%fp),%a3
	moveq #0,%d2
	jbra .L168
.L169:
	lea (%fp,%d2.l),%a2
	move.w (%a3),%d0
	move.w %d0,%d1
	swap %d1
	mov.w 2(%a3),%d1
	tst.l %d1
	jbeq .L170
	move.w (%a4),%d5
	move.w %d5,%d0
	swap %d0
	mov.w 2(%a4),%d0
	lea cprintf,%a5
	tst.l %d0
	jbeq .L172
	lea (-312,%a2),%a2
	move.w (%a2),%a0
	move.w %a0,%d5
	swap %d5
	mov.w 2(%a2),%d5
	move.l %d5,-(%sp)
	move.l %d0,-(%sp)
	move.l %d1,-(%sp)
	lea (-372,%fp),%a0
	pea 48(%a0,%d2.l)
	pea .LC31
	jbsr (%a5)
	move.w (%a4),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a4),%d0
	move.l %d0,-(%sp)
	move.l %d4,-(%sp)
	jbsr f_lseek
	pea -4(%fp)
	move.w (%a3),%a0
	move.w %a0,%d5
	swap %d5
	mov.w 2(%a3),%d5
	move.l %d5,-(%sp)
	move.w (%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 2(%a2),%d0
	move.l %d0,-(%sp)
	move.l %d4,-(%sp)
	jbsr f_read
	lea (44,%sp),%sp
	tst.l %d0
	jbne .L174
	move.w (%a3),%d5
	move.w %d5,%d0
	swap %d0
	mov.w 2(%a3),%d0
	cmp.l -4(%fp),%d0
	jbeq .L170
.L174:
	pea .LC32
	jbsr (%a5)
	jbra .L183
.L172:
	move.w -232(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -230(%fp),%d0
	move.l %d0,-(%sp)
	move.w -228(%fp),%a0
	move.w %a0,%d5
	swap %d5
	mov.w -226(%fp),%d5
	move.l %d5,-(%sp)
	pea -244(%fp)
	pea .LC33
	jbsr (%a5)
	move.w -228(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -226(%fp),%d0
	move.l %d0,-(%sp)
	clr.l -(%sp)
	move.w -232(%fp),%a0
	move.w %a0,%d5
	swap %d5
	mov.w -230(%fp),%d5
	move.l %d5,-(%sp)
	jbsr memset
	lea (28,%sp),%sp
.L170:
	addq.l #1,%d3
	moveq #40,%d0
	add.l %d0,%d2
	lea (40,%a3),%a3
	lea (40,%a4),%a4
.L168:
	moveq #0,%d0
	move.w -370(%fp),%d0
	cmp.l %d3,%d0
	jbgt .L169
	move.l #.LC24,%d0
	tst.l usermode
	jbne .L179
	jbra .L177
.L181:
	pea .LC30
	jbra .L182
.L177:
	move.l #.LC25,%d0
.L179:
	move.l %d0,-(%sp)
	move.w -336(%fp),%d5
	move.w %d5,%d1
	swap %d1
	mov.w -334(%fp),%d1
	move.l %d1,-(%sp)
	pea .LC26
	jbsr cprintf
	move.w -336(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -334(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.w usermode+2,%d0
	move.l %d0,-(%sp)
	jbsr run_program
	moveq #1,%d0
	lea (20,%sp),%sp
.L157:
	movm.l -404(%fp),#0x3c3c
	unlk %fp
	rts
	.size	load_coff_executable, .-load_coff_executable
	.section	.rodata.str1.1
.LC34:
	.string	"Cannot read .68K file header.\n"
.LC35:
	.string	"Unable to load file below 0x%04x or above 0x%x\n"
.LC36:
	.string	"Error loading .68K file.\n"
	.text
	.align	2
	.globl	load_m68k_executable
	.type	load_m68k_executable, @function
load_m68k_executable:
	link.w %fp,#-32
	movm.l #0x3c20,-(%sp)
	move.l 16(%fp),%d5
	move.l %fp,%d4
	subq.l #4,%d4
	move.l %d4,-(%sp)
	pea 28.w
	pea -32(%fp)
	move.l %d5,-(%sp)
	lea f_read,%a2
	jbsr (%a2)
	lea (16,%sp),%sp
	tst.l %d0
	jbne .L185
	move.b #27,%d0
	cmp.l -4(%fp),%d0
	jbcs .L187
.L185:
	pea .LC34
	jbra .L197
.L187:
	move.w -30(%fp),%d2
	move.w %d2,%d1
	swap %d1
	mov.w -28(%fp),%d1
	move.w -26(%fp),%a0
	move.w %a0,%d0
	swap %d0
	mov.w -24(%fp),%d0
	move.w -10(%fp),%d2
	move.w %d2,%d3
	swap %d3
	mov.w -8(%fp),%d3
	cmp.w #24602,-32(%fp)
	jbne .L189
	cmp.l #4095,%d3
	jbls .L189
	addq.l #1,%d1
	moveq #-2,%d2
	and.l %d2,%d1
	addq.l #1,%d0
	and.l %d2,%d0
	move.l %d1,%d2
	add.l %d0,%d2
	move.w -22(%fp),%a0
	move.w %a0,%d0
	swap %d0
	mov.w -20(%fp),%d0
	addq.l #1,%d0
	moveq #-2,%d1
	and.l %d1,%d0
	add.l %d3,%d0
	add.l %d2,%d0
	cmp.l #1048576,%d0
	jbls .L192
.L189:
	move.l #1048576,-(%sp)
	pea 4096.w
	pea .LC35
	jbsr cprintf
	moveq #0,%d0
	lea (12,%sp),%sp
	jbra .L188
.L192:
	move.l %d4,-(%sp)
	move.l %d2,-(%sp)
	move.l %d3,-(%sp)
	move.l %d5,-(%sp)
	jbsr (%a2)
	lea (16,%sp),%sp
	tst.l %d0
	jbne .L193
	cmp.l -4(%fp),%d2
	jbls .L195
.L193:
	pea .LC36
.L197:
	jbsr cprintf
	moveq #0,%d0
	addq.l #4,%sp
	jbra .L188
.L195:
	move.l %d3,-(%sp)
	moveq #0,%d0
	move.w usermode+2,%d0
	move.l %d0,-(%sp)
	jbsr run_program
	moveq #1,%d0
	addq.l #8,%sp
.L188:
	movm.l -52(%fp),#0x43c
	unlk %fp
	rts
	.size	load_m68k_executable, .-load_m68k_executable
	.section	.rodata.str1.1
.LC37:
	.string	"Cannot use drive %s\n"
.LC38:
	.string	"s"
.LC39:
	.string	""
.LC40:
	.string	"%s: takes exactly %d argument%s\n"
.LC41:
	.string	"%s: takes %d to %d arguments\n"
	.text
	.align	2
	.globl	handle_cmd_builtin
	.type	handle_cmd_builtin, @function
handle_cmd_builtin:
	link.w %fp,#0
	movm.l #0x2030,-(%sp)
	move.l 8(%fp),%a3
	move.l 12(%fp),%d2
	moveq #1,%d0
	cmp.l %d2,%d0
	jbne .L199
	move.l (%a3),%a2
	move.l %a2,-(%sp)
	jbsr strlen
	addq.l #4,%sp
	cmp.b #58,-1(%a2,%d0.l)
	jbne .L199
	move.l %a2,-(%sp)
	jbsr f_chdrive
	addq.l #4,%sp
	tst.l %d0
	jbne .L202
	move.b #1,%d0
	jbra .L204
.L202:
	move.l %d0,-(%sp)
	jbsr f_perror
	move.l (%a3),-(%sp)
	pea .LC37
	jbsr cprintf
	moveq #1,%d0
	lea (12,%sp),%sp
	jbra .L204
.L205:
	move.l %d0,-(%sp)
	move.l (%a3),-(%sp)
	jbsr strcasecmp
	addq.l #8,%sp
	tst.l %d0
	jbne .L206
	move.l %d2,%d1
	subq.l #1,%d1
	move.w 4(%a2),%a0
	move.w %a0,%d2
	swap %d2
	mov.w 6(%a2),%d2
	cmp.l %d1,%d2
	jbgt .L208
	move.w 8(%a2),%a0
	move.w %a0,%d0
	swap %d0
	mov.w 10(%a2),%d0
	tst.l %d0
	jbeq .L210
	cmp.l %d1,%d0
	jblt .L208
.L210:
	move.w 12(%a2),%a0
	move.w %a0,%d0
	swap %d0
	mov.w 14(%a2),%d0
	move.l %d1,-(%sp)
	pea 4(%a3)
	move.l %d0,%a0
	jbsr (%a0)
	moveq #1,%d0
	addq.l #8,%sp
	jbra .L204
.L208:
	move.w 8(%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 10(%a2),%d0
	cmp.l %d2,%d0
	jbne .L212
	move.l #.LC38,%d0
	moveq #1,%d1
	cmp.l %d2,%d1
	jbne .L216
	move.l #.LC39,%d0
.L216:
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	move.l (%a3),-(%sp)
	pea .LC40
	jbra .L220
.L212:
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	move.l (%a3),-(%sp)
	pea .LC41
.L220:
	jbsr cprintf
	moveq #1,%d0
	lea (16,%sp),%sp
	jbra .L204
.L206:
	lea (20,%a2),%a2
	jbra .L217
.L199:
	lea cmd_table,%a2
.L217:
	move.w (%a2),%a0
	move.w %a0,%d0
	swap %d0
	mov.w 2(%a2),%d0
	tst.l %d0
	jbne .L205
.L204:
	movm.l -12(%fp),#0xc04
	unlk %fp
	rts
	.size	handle_cmd_builtin, .-handle_cmd_builtin
	.section	.rodata.str1.1
.LC42:
	.string	"f_opendir(\"%s\"): "
.LC43:
	.string	"f_readdir(): "
.LC44:
	.string	"         %04d-%02d-%02d %02d:%02d %s/"
.LC45:
	.string	"%8d %04d-%02d-%02d %02d:%02d %-12s"
.LC46:
	.string	"\n"
.LC47:
	.string	"  "
.LC48:
	.string	"f_closedir(): "
	.text
	.align	2
	.globl	do_ls
	.type	do_ls, @function
do_ls:
	link.w %fp,#-52
	movm.l #0x3820,-(%sp)
	move.l #.LC39,%d3
	tst.l 12(%fp)
	jbeq .L224
	move.l 8(%fp),%a0
	move.l (%a0),%d3
.L224:
	move.l %d3,-(%sp)
	pea -50(%fp)
	jbsr f_opendir
	move.l %d0,%d2
	addq.l #8,%sp
	jbeq .L225
	move.l %d3,-(%sp)
	pea .LC42
	jbsr cprintf
	move.l %d2,-(%sp)
	jbsr f_perror
	lea (12,%sp),%sp
	jbra .L246
.L247:
	pea .LC43
	jbsr cprintf
	move.l %d2,-(%sp)
	jbsr f_perror
	addq.l #8,%sp
	jbra .L231
.L225:
	moveq #1,%d3
.L228:
	pea -22(%fp)
	pea -50(%fp)
	jbsr f_readdir
	move.l %d0,%d2
	addq.l #8,%sp
	jbne .L247
	tst.b -13(%fp)
	jbeq .L231
	move.b -14(%fp),%d4
	moveq #16,%d0
	and.l %d0,%d4
	lea cprintf,%a0
	move.w -16(%fp),%d1
	move.w -18(%fp),%d0
	lea (-13,%fp),%a2
	tst.l %d4
	jbeq .L233
	move.l %a2,-(%sp)
	lsr.w #5,%d1
	move.b #63,%d2
	and.l %d1,%d2
	move.l %d2,-(%sp)
	lsr.w #6,%d1
	moveq #31,%d2
	and.l %d1,%d2
	move.l %d2,-(%sp)
	moveq #31,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	lsr.w #5,%d0
	moveq #15,%d2
	and.l %d0,%d2
	move.l %d2,-(%sp)
	lsr.w #4,%d0
	moveq #127,%d1
	and.l %d1,%d0
	move.l %d0,%a1
	pea 1980(%a1)
	pea .LC44
	jbsr (%a0)
	move.l %a2,-(%sp)
	jbsr strlen
	move.l %d0,%d2
	lea (32,%sp),%sp
	jbra .L235
.L236:
	pea .LC21
	jbsr cprintf
	addq.l #1,%d2
	addq.l #4,%sp
.L235:
	moveq #11,%d0
	cmp.l %d2,%d0
	jbge .L236
	jbra .L237
.L233:
	move.l %a2,-(%sp)
	lsr.w #5,%d1
	moveq #63,%d2
	and.l %d1,%d2
	move.l %d2,-(%sp)
	lsr.w #6,%d1
	moveq #31,%d2
	and.l %d1,%d2
	move.l %d2,-(%sp)
	moveq #31,%d1
	and.l %d0,%d1
	move.l %d1,-(%sp)
	lsr.w #5,%d0
	moveq #15,%d2
	and.l %d0,%d2
	move.l %d2,-(%sp)
	lsr.w #4,%d0
	moveq #127,%d1
	and.l %d1,%d0
	move.l %d0,%a1
	pea 1980(%a1)
	move.w -22(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -20(%fp),%d0
	move.l %d0,-(%sp)
	pea .LC45
	jbsr (%a0)
	lea (32,%sp),%sp
.L237:
	tst.l %d3
	jbne .L238
	pea .LC46
	jbsr cprintf
	jbra .L248
.L238:
	lea cprintf,%a0
	tst.l %d4
	jbne .L241
	pea .LC47
	jbra .L249
.L241:
	pea .LC21
.L249:
	jbsr (%a0)
.L248:
	addq.l #4,%sp
	tst.l %d3
	seq %d0
	ext.w %d0
	move.w %d0,%d3
	ext.l %d3
	neg.l %d3
	jbra .L228
.L231:
	tst.l %d3
	jbne .L243
	pea .LC46
	jbsr cprintf
	addq.l #4,%sp
.L243:
	pea -50(%fp)
	jbsr f_closedir
	move.l %d0,%d2
	addq.l #4,%sp
	jbeq .L246
	pea .LC48
	jbsr cprintf
	move.l %d2,-(%sp)
	jbsr f_perror
	addq.l #8,%sp
.L246:
	movm.l -68(%fp),#0x41c
	unlk %fp
	rts
	.size	do_ls, .-do_ls
	.align	2
	.globl	do_cd
	.type	do_cd, @function
do_cd:
	link.w %fp,#0
	move.l 8(%fp),%a0
	move.l (%a0),-(%sp)
	jbsr f_chdir
	addq.l #4,%sp
	tst.l %d0
	jbeq .L253
	move.l %d0,-(%sp)
	jbsr f_perror
	addq.l #4,%sp
.L253:
	unlk %fp
	rts
	.size	do_cd, .-do_cd
	.align	2
	.globl	do_execute
	.type	do_execute, @function
do_execute:
	link.w %fp,#0
	move.l %d2,-(%sp)
	pea 16.w
	clr.l -(%sp)
	move.l 8(%fp),%a0
	move.l (%a0),-(%sp)
	jbsr strtoul
	move.l %d0,%d2
	lea (12,%sp),%sp
	move.l #.LC24,%d0
	tst.l usermode
	jbne .L257
	move.l #.LC25,%d0
.L257:
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	pea .LC26
	jbsr cprintf
	move.l %d2,-(%sp)
	moveq #0,%d0
	move.w usermode+2,%d0
	move.l %d0,-(%sp)
	jbsr run_program
	lea (20,%sp),%sp
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	do_execute, .-do_execute
	.section	.rodata.str1.1
.LC49:
	.string	"Ambiguous value: \"%s\" (odd length).\n"
.LC50:
	.string	"Bad hex character \"%c\" in value \"%s\".\n"
	.text
	.align	2
	.globl	do_writemem
	.type	do_writemem, @function
do_writemem:
	link.w %fp,#0
	movm.l #0x3e3c,-(%sp)
	move.l 8(%fp),%d5
	move.l 12(%fp),%d6
	pea 16.w
	clr.l -(%sp)
	move.l %d5,%a5
	move.l (%a5)+,-(%sp)
	jbsr strtoul
	move.l %d0,%d4
	moveq #1,%d3
	lea (12,%sp),%sp
	jbra .L260
.L261:
	move.l (%a5),%a3
	move.l %a3,-(%sp)
	jbsr strlen
	addq.l #4,%sp
	move.l %d0,%d2
	moveq #1,%d0
	cmp.l %d2,%d0
	jbeq .L262
	btst #0,%d2
	jbeq .L262
	move.l %a3,-(%sp)
	pea .LC49
	jbsr cprintf
	addq.l #8,%sp
	jbra .L279
.L266:
	move.b (%a3,%a2.l),%d0
	ext.w %d0
	move.w %d0,%a4
	move.l %a4,-(%sp)
	jbsr fromhex
	addq.l #4,%sp
	tst.l %d0
	jbge .L267
	move.l %a3,-(%sp)
	move.l %a4,-(%sp)
	pea .LC50
	jbsr cprintf
	lea (12,%sp),%sp
	jbra .L279
.L267:
	addq.l #1,%a2
	jbra .L269
.L262:
	sub.l %a2,%a2
.L269:
	cmp.l %a2,%d2
	jbgt .L266
	addq.l #1,%d3
	addq.l #4,%a5
.L260:
	cmp.l %d3,%d6
	jbgt .L261
	move.l %d4,%d3
	move.l %d5,%a5
	addq.l #4,%a5
	moveq #1,%d5
	jbra .L272
.L273:
	move.l (%a5),%d2
	move.l %d2,-(%sp)
	jbsr strlen
	addq.l #4,%sp
	move.l %d0,%d4
	moveq #2,%d0
	cmp.l %d4,%d0
	jbge .L274
	sub.l %a4,%a4
	jbra .L276
.L274:
	pea 16.w
	clr.l -(%sp)
	move.l %d2,-(%sp)
	jbsr strtoul
	move.l %d3,%a0
	addq.l #1,%d3
	move.b %d0,(%a0)+
	lea (12,%sp),%sp
	jbra .L277
.L278:
	move.l %a4,%a3
	add.l (%a5),%a3
	move.b (%a3),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	lea fromhex,%a2
	jbsr (%a2)
	move.l %d0,%d2
	lsl.l #4,%d2
	move.b 1(%a3),%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,(%sp)
	jbsr (%a2)
	addq.l #4,%sp
	or.b %d2,%d0
	move.l %d3,%a0
	addq.l #1,%d3
	move.b %d0,(%a0)+
	addq.l #2,%a4
.L276:
	cmp.l %a4,%d4
	jbgt .L278
.L277:
	addq.l #1,%d5
	addq.l #4,%a5
.L272:
	cmp.l %d5,%d6
	jbgt .L273
.L279:
	movm.l -36(%fp),#0x3c7c
	unlk %fp
	rts
	.size	do_writemem, .-do_writemem
	.section	.rodata.str1.1
.LC51:
	.string	"Please specify the load address as an argument (in hex).\n"
.LC52:
	.string	"Loading flat binary at 0x%x\n"
.LC53:
	.string	"Unable to load file.\n"
	.text
	.align	2
	.globl	load_flat_executable
	.type	load_flat_executable, @function
load_flat_executable:
	link.w %fp,#-4
	movm.l #0x2030,-(%sp)
	move.l 16(%fp),%a2
	lea cprintf,%a3
	moveq #2,%d0
	cmp.l 12(%fp),%d0
	jbeq .L281
	pea .LC51
	jbsr (%a3)
	jbra .L288
.L281:
	pea 16.w
	clr.l -(%sp)
	move.l 8(%fp),%a0
	move.l 4(%a0),-(%sp)
	jbsr strtoul
	move.l %d0,%d2
	move.l %d0,-(%sp)
	pea .LC52
	jbsr (%a3)
	move.w 12(%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 14(%a2),%d0
	move.l %fp,%a0
	move.l %d0,-(%a0)
	move.l %a0,-(%sp)
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	move.l %a2,-(%sp)
	jbsr f_read
	lea (36,%sp),%sp
	tst.l %d0
	jbne .L284
	move.w 12(%a2),%d1
	move.w %d1,%d0
	swap %d0
	mov.w 14(%a2),%d0
	cmp.l -4(%fp),%d0
	jbne .L284
	moveq #1,%d0
	jbra .L283
.L284:
	pea .LC53
	jbsr cprintf
.L288:
	moveq #0,%d0
	addq.l #4,%sp
.L283:
	movm.l -16(%fp),#0xc04
	unlk %fp
	rts
	.size	load_flat_executable, .-load_flat_executable
	.section	.rodata.str1.1
.LC54:
	.string	"%s: Cannot load: "
.LC55:
	.string	"%s: %d bytes, "
.LC56:
	.string	"ELF.\n"
.LC57:
	.string	"COFF.\n"
.LC58:
	.string	"68K or SYS\n"
.LC59:
	.string	"Command file.\n"
.LC60:
	.string	"unknown format.\n"
.LC61:
	.string	"%s: Cannot read: "
	.text
	.align	2
	.globl	handle_cmd_executable
	.type	handle_cmd_executable, @function
handle_cmd_executable:
	link.w %fp,#-548
	movm.l #0x383c,-(%sp)
	move.l 8(%fp),%a3
	move.l 12(%fp),%d4
	move.l %a3,-(%sp)
	jbsr extend_filename
	addq.l #4,%sp
	tst.l %d0
	jbeq .L290
	pea 1.w
	move.l (%a3),-(%sp)
	move.l %fp,%d3
	add.l #-548,%d3
	move.l %d3,-(%sp)
	jbsr f_open
	move.l %d0,%d2
	subq.l #4,%d0
	lea (12,%sp),%sp
	moveq #1,%d1
	cmp.l %d0,%d1
	jbcc .L290
	lea cprintf,%a2
	tst.l %d2
	jbeq .L293
	move.l (%a3),-(%sp)
	pea .LC54
	jbsr (%a2)
	move.l %d2,-(%sp)
	jbsr f_perror
	moveq #1,%d0
	lea (12,%sp),%sp
	jbra .L295
.L293:
	lea (-4,%fp),%a4
	clr.w (%a4)
	clr.w -2(%fp)
	move.w -536(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -534(%fp),%d0
	move.l %d0,-(%sp)
	move.l (%a3),-(%sp)
	pea .LC55
	move.l %a2,%a5
	jbsr (%a2)
	pea -8(%fp)
	pea 4.w
	move.l %a4,-(%sp)
	move.l %d3,-(%sp)
	jbsr f_read
	move.l %d0,%d2
	clr.l -(%sp)
	move.l %d3,-(%sp)
	jbsr f_lseek
	lea (36,%sp),%sp
	tst.l %d2
	jbne .L296
	pea 4.w
	pea elf_header_bytes
	move.l %a4,-(%sp)
	lea memcmp,%a2
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l %d0
	jbne .L298
	pea .LC56
	jbsr (%a5)
	move.l %d3,-(%sp)
	move.l %d4,-(%sp)
	move.l %a3,-(%sp)
	jbsr load_elf_executable
	jbra .L308
.L298:
	pea 2.w
	pea coff_header_bytes
	move.l %a4,-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l %d0
	jbne .L301
	pea .LC57
	jbsr (%a5)
	move.l %d3,-(%sp)
	move.l %d4,-(%sp)
	move.l %a3,-(%sp)
	jbsr load_coff_executable
.L308:
	lea (16,%sp),%sp
	jbra .L300
.L301:
	pea 2.w
	pea m68k_header_bytes
	move.l %a4,-(%sp)
	jbsr (%a2)
	lea (12,%sp),%sp
	tst.l %d0
	jbne .L303
	pea .LC58
	jbsr (%a5)
	move.l %d3,-(%sp)
	move.l %d4,-(%sp)
	move.l %a3,-(%sp)
	jbsr load_m68k_executable
	jbra .L308
.L303:
	pea 4.w
	move.l %a4,-(%sp)
	jbsr is_cmd_head
	addq.l #8,%sp
	tst.l %d0
	jbeq .L305
	pea .LC59
	jbsr (%a5)
	move.l %d3,-(%sp)
	move.l %d4,-(%sp)
	move.l %a3,-(%sp)
	jbsr load_command_file
	jbra .L308
.L305:
	pea .LC60
	jbsr (%a5)
	move.l %d3,-(%sp)
	move.l %d4,-(%sp)
	move.l %a3,-(%sp)
	jbsr load_flat_executable
	jbra .L308
.L296:
	move.l (%a3),-(%sp)
	pea .LC61
	jbsr (%a2)
	move.l %d2,-(%sp)
	jbsr f_perror
	lea (12,%sp),%sp
.L300:
	pea -548(%fp)
	jbsr f_close
	moveq #1,%d0
	addq.l #4,%sp
	jbra .L295
.L290:
	moveq #0,%d0
.L295:
	movm.l -576(%fp),#0x3c1c
	unlk %fp
	rts
	.size	handle_cmd_executable, .-handle_cmd_executable
	.section	.rodata.str1.1
.LC62:
	.string	"%s: Unknown command.  Try 'help'.\n"
	.text
	.align	2
	.globl	handle_any_command
	.type	handle_any_command, @function
handle_any_command:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d2
	jble .L314
	move.l %d2,-(%sp)
	move.l %a2,-(%sp)
	jbsr handle_cmd_builtin
	addq.l #8,%sp
	tst.l %d0
	jbne .L314
	move.l %d2,-(%sp)
	move.l %a2,-(%sp)
	jbsr handle_cmd_executable
	addq.l #8,%sp
	tst.l %d0
	jbne .L314
	move.l (%a2),-(%sp)
	pea .LC62
	jbsr cprintf
	addq.l #8,%sp
.L314:
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	handle_any_command, .-handle_any_command
	.section	.rodata.str1.1
.LC63:
	.string	"Limiting to %d arguments.\n"
	.text
	.align	2
	.globl	execute_cmd
	.type	execute_cmd, @function
execute_cmd:
	link.w %fp,#-164
	movm.l #0x2030,-(%sp)
	move.l 8(%fp),%a2
	moveq #0,%d2
	lea (-164,%fp),%a3
	move.l %a3,%a1
	jbra .L316
.L317:
	addq.l #4,%a1
	moveq #40,%d0
	cmp.l %d2,%d0
	jbne .L316
	pea 40.w
	pea .LC63
	jbsr cprintf
	clr.b (%a2)
	addq.l #8,%sp
	jbra .L319
.L316:
	tst.b (%a2)
	jbeq .L319
	move.l __ctype_ptr,%a0
	jbra .L321
.L322:
	addq.l #1,%a2
.L321:
	move.b (%a2),%d0
	ext.w %d0
	btst #3,(%a0,%d0.w)
	jbne .L322
	move.l %a2,(%a1)
	addq.l #1,%d2
	addq.l #4,%a3
	jbra .L324
.L325:
	addq.l #1,%a2
.L324:
	move.b (%a2),%d0
	jbeq .L317
	ext.w %d0
	btst #3,(%a0,%d0.w)
	jbeq .L325
.L329:
	clr.b (%a2)+
	move.b (%a2),%d0
	ext.w %d0
	move.l __ctype_ptr,%a0
	btst #3,(%a0,%d0.w)
	jbne .L329
	jbra .L317
.L319:
	clr.w (%a3)
	clr.w 2(%a3)
	move.l %d2,-(%sp)
	pea -164(%fp)
	jbsr handle_any_command
	movm.l -176(%fp),#0xc04
	unlk %fp
	rts
	.size	execute_cmd, .-execute_cmd
	.section	.rodata.str1.1
.LC64:
	.string	"%s\n"
	.text
	.align	2
	.globl	load_command_file
	.type	load_command_file, @function
load_command_file:
	link.w %fp,#0
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.l 16(%fp),%d3
	move.w cmd_level,%d0
	addq.w #1,%d0
	move.w %d0,cmd_level
	cmp.w #4,%d0
	jbls .L348
	moveq #0,%d0
	jbra .L336
.L348:
	move.l %d3,-(%sp)
	pea 256.w
	pea cmd_buffer+4
	jbsr readline
	move.l %d0,%d2
	lea (12,%sp),%sp
	moveq #-1,%d0
	cmp.l %d2,%d0
	jbeq .L337
	pea cmd_buffer+4
	pea .LC64
	jbsr cprintf
	addq.l #8,%sp
	cmp.b #35,cmd_buffer+4.l
	jbeq .L348
	tst.l %d2
	jbeq .L348
	pea cmd_buffer+4
	jbsr execute_cmd
	addq.l #4,%sp
	jbra .L348
.L337:
	subq.w #1,cmd_level
	moveq #1,%d0
.L336:
	move.l -8(%fp),%d2
	move.l -4(%fp),%d3
	unlk %fp
	rts
	.size	load_command_file, .-load_command_file
	.align	2
	.globl	do_set_mode
	.type	do_set_mode, @function
do_set_mode:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.l 8(%fp),%d1
	move.l 16(%fp),%d0
	jbne .L350
	move.l %d1,usermode
	jbra .L353
.L350:
	move.l usermode,%d2
	move.l %d1,usermode
	move.l %d0,-(%sp)
	move.l 12(%fp),-(%sp)
	jbsr handle_any_command
	move.l %d2,usermode
	addq.l #8,%sp
.L353:
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	do_set_mode, .-do_set_mode
	.align	2
	.globl	do_set_supv
	.type	do_set_supv, @function
do_set_supv:
	link.w %fp,#0
	move.l 12(%fp),-(%sp)
	move.l 8(%fp),-(%sp)
	clr.l -(%sp)
	jbsr do_set_mode
	lea (12,%sp),%sp
	unlk %fp
	rts
	.size	do_set_supv, .-do_set_supv
	.align	2
	.globl	do_set_user
	.type	do_set_user, @function
do_set_user:
	link.w %fp,#0
	move.l 12(%fp),-(%sp)
	move.l 8(%fp),-(%sp)
	pea 1.w
	jbsr do_set_mode
	lea (12,%sp),%sp
	unlk %fp
	rts
	.size	do_set_user, .-do_set_user
	.align	2
	.globl	do_dump
	.type	do_dump, @function
do_dump:
	link.w %fp,#0
	movm.l #0x2030,-(%sp)
	move.l 8(%fp),%a2
	pea 16.w
	clr.l -(%sp)
	move.l (%a2),-(%sp)
	lea strtoul,%a3
	jbsr (%a3)
	move.l %d0,%d2
	pea 16.w
	clr.l -(%sp)
	move.l 4(%a2),-(%sp)
	jbsr (%a3)
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	jbsr pretty_dump_memory
	lea (32,%sp),%sp
	movm.l -12(%fp),#0xc04
	unlk %fp
	rts
	.size	do_dump, .-do_dump
	.section	.rodata.str1.1
.LC65:
	.string	"CPM     SYS"
.LC66:
	.string	"No CPM.SYS in ROM found.\n"
.LC67:
	.string	"Bad header on CPM.SYS file.\n"
.LC68:
	.string	"Cannot load CPM.sys out of allowable address range.\n"
	.text
	.align	2
	.globl	do_run_rom_cpm
	.type	do_run_rom_cpm, @function
do_run_rom_cpm:
	link.w %fp,#0
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	pea 11.w
	pea location_zero+49153
	pea .LC65
	jbsr strncmp
	lea (12,%sp),%sp
	tst.l %d0
	jbeq .L361
	pea .LC66
	jbra .L370
.L361:
	cmp.w #24602,location_zero+51200.l
	jbeq .L364
	pea .LC67
.L370:
	jbsr cprintf
	addq.l #4,%sp
	jbra .L369
.L364:
	move.w location_zero+51202,%d0
	move.w %d0,%d1
	swap %d1
	mov.w location_zero+51204,%d1
	move.w location_zero+51206,%a0
	move.w %a0,%d0
	swap %d0
	mov.w location_zero+51208,%d0
	move.w location_zero+51222,%a0
	move.w %a0,%d2
	swap %d2
	mov.w location_zero+51224,%d2
	cmp.l #4095,%d2
	jble .L366
	move.l %d1,%d3
	add.l %d0,%d3
	move.l %d2,%d0
	add.l %d3,%d0
	move.w location_zero+51210,%a0
	move.w %a0,%d1
	swap %d1
	mov.w location_zero+51212,%d1
	add.l %d1,%d0
	cmp.l #1048576,%d0
	jbls .L368
.L366:
	pea .LC68
	jbra .L370
.L368:
	move.l %d3,-(%sp)
	pea location_zero+51228
	move.l %d2,-(%sp)
	jbsr memmove
	move.l %d2,-(%sp)
	clr.l -(%sp)
	jbsr run_program
	lea (20,%sp),%sp
.L369:
	move.l -8(%fp),%d2
	move.l -4(%fp),%d3
	unlk %fp
	rts
	.size	do_run_rom_cpm, .-do_run_rom_cpm
	.align	2
	.globl	rubout
	.type	rubout, @function
rubout:
	link.w %fp,#0
	move.l %a2,-(%sp)
	pea 8.w
	lea _con_out,%a2
	jbsr (%a2)
	pea 32.w
	jbsr (%a2)
	pea 8.w
	jbsr (%a2)
	lea (12,%sp),%sp
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	rubout, .-rubout
	.section	.rodata.str1.1
.LC69:
	.string	"0:/BOOT.CMD"
	.text
	.align	2
	.globl	getline
	.type	getline, @function
getline:
	link.w %fp,#0
	movm.l #0x3830,-(%sp)
	move.l 8(%fp),%a3
	move.l 12(%fp),%a2
	moveq #0,%d4
.L404:
	jbsr sio_get
	move.l %d0,%d3
	tst.l auto_boot_time
	jbeq .L375
	pea 1.w
	jbsr daytime_c
	addq.l #4,%sp
	cmp.l auto_boot_time.l,%d1
	jbcs .L375
	pea .LC69
	move.l %a3,-(%sp)
	jbsr strcpy
	move.l %a3,-(%sp)
	pea .LC64
	jbsr cprintf
	move.l %a3,-(%sp)
	jbsr strlen
	move.l %d0,%d4
	lea (20,%sp),%sp
	jbra .L378
.L375:
	move.b %d3,%d2
	jblt .L404
	clr.l auto_boot_time
	move.b %d3,%d0
	add.b #-32,%d0
	cmp.b #94,%d0
	jbhi .L380
	move.b %d3,(%a3,%d4.l)
	addq.l #1,%d4
	move.b %d3,%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	jbra .L403
.L380:
	cmp.b #13,%d3
	jbeq .L383
	cmp.b #10,%d3
	jbne .L385
.L383:
	pea 13.w
	lea _con_out,%a2
	jbsr (%a2)
	pea 10.w
	jbsr (%a2)
	addq.l #8,%sp
	jbra .L386
.L385:
	cmp.b #8,%d3
	jbeq .L387
	cmp.b #127,%d3
	jbne .L389
.L387:
	tst.l %d4
	jble .L389
	jbsr rubout
	subq.l #1,%d4
	jbra .L382
.L389:
	cmp.b #24,%d2
	jbne .L400
	jbra .L401
.L393:
	jbsr rubout
	subq.l #1,%d4
.L401:
	tst.l %d4
	jbne .L393
	jbra .L394
.L400:
	pea 7.w
.L403:
	jbsr _con_out
	addq.l #4,%sp
.L382:
	tst.b %d2
	jbeq .L386
.L394:
	move.l %a2,%d0
	subq.l #1,%d0
	cmp.l %d4,%d0
	jbgt .L404
.L386:
	clr.b (%a3,%d4.l)
.L378:
	move.l %d4,%d0
	movm.l -20(%fp),#0xc1c
	unlk %fp
	rts
	.size	getline, .-getline
	.section	.rodata.str1.1
.LC70:
	.string	"Auto boot in %d seconds; hit any key to cancel.\r\n"
.LC71:
	.string	"%s> "
	.text
	.align	2
	.globl	main68
	.type	main68, @function
main68:
	link.w %fp,#0
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	jbsr cpu_cache_disable
	moveq #1,%d0
	move.l %d0,usermode
	move.l #49152,0.w
	moveq #0,%d2
	move.l #fat_fs_workarea,%d3
.L406:
	lea drive_status,%a0
	move.b #1,(%a0,%d2.l)
	move.b %d2,%d0
	add.b #48,%d0
	move.b %d0,cmd_buffer+4
	move.b #58,cmd_buffer+5
	clr.b cmd_buffer+6
	clr.l -(%sp)
	pea cmd_buffer+4
	move.l %d3,-(%sp)
	jbsr f_mount
	addq.l #1,%d2
	add.l #554,%d3
	lea (12,%sp),%sp
	moveq #4,%d0
	cmp.l %d2,%d0
	jbne .L406
	move.b nvram+3,%d0
	asr.b #4,%d0
	add.b #65,%d0
	move.b %d0,cmd_buffer+4
	move.b #58,cmd_buffer+5
	clr.b cmd_buffer+6
	pea cmd_buffer+4
	jbsr execute_cmd
	addq.l #4,%sp
	tst.b nvram+17
	jbeq .L408
	clr.l -(%sp)
	pea .LC69
	jbsr f_stat
	addq.l #8,%sp
	tst.l %d0
	jbne .L408
	pea 1.w
	jbsr daytime_c
	moveq #0,%d0
	move.b nvram+17,%d0
	move.l %d0,%d2
	add.l %d1,%d2
	move.l %d2,auto_boot_time
	move.l %d0,-(%sp)
	pea .LC70
	jbsr cprintf
	lea (12,%sp),%sp
	jbra .L420
.L408:
	clr.l auto_boot_time
.L420:
	clr.w cmd_level
	pea 256.w
	pea cmd_buffer+4
	jbsr f_getcwd
	move.b cmd_buffer+4,%d1
	move.b %d1,%d0
	add.b #-48,%d0
	addq.l #8,%sp
	cmp.b #9,%d0
	jbhi .L412
	add.b #19,%d1
	move.b %d1,cmd_buffer+4
.L412:
	tst.l usermode
	jbeq .L414
	moveq #45,%d0
	jbra .L416
.L414:
	moveq #43,%d0
.L416:
	move.l %d0,-(%sp)
	jbsr putch
	pea cmd_buffer+4
	pea .LC71
	jbsr cprintf
	pea 256.w
	pea cmd_buffer+4
	jbsr getline
	pea cmd_buffer+4
	jbsr execute_cmd
	lea (24,%sp),%sp
	jbra .L420
	nop
	.size	main68, .-main68
	.globl	msg_welcome
	.section	.rodata
	.type	msg_welcome, @object
	.size	msg_welcome, 64
msg_welcome:
	.string	"\r\n\r\n        Welcome to the MINI-M68000 System     BIOS 10.2\r\n\r\n"
	.globl	msg_GNU_license
	.type	msg_GNU_license, @object
	.size	msg_GNU_license, 749
msg_GNU_license:
	.ascii	"\r\nThis program is free software: you can redistribute it a"
	.ascii	"nd/or modify\r\nit under the terms of the GNU General Public"
	.ascii	" License as published by\r\nthe Free Software Foundation, ei"
	.ascii	"ther version 3 of the License, or\r\n(at your option) any la"
	.ascii	"ter version.\r\n\r\nThis program is distributed in the hope "
	.ascii	"that it will be useful,\r\nbut WITHOUT ANY WARRANTY; without"
	.ascii	" even the implied warranty of\r\nMERCHANTABILITY or FITNESS "
	.ascii	"FOR A PARTICULAR PURPOSE.  See the\r\nGNU General Public Lic"
	.ascii	"ense for more details.\r\n\r\nYou "
	.string	"should have received a copy of the GNU General Public License\r\nin the file COPYING in the distribution directory along with this\r\nprogram.  If not, see <http://www.gnu.org/licenses/>.\r\n\r\nLicensed for hobbyist use on the RetroBrew MINI-M68000 CPU board.\r\n\r\n"
	.globl	cmd_table
	.section	.rodata.str1.1
.LC72:
	.string	"cd"
.LC73:
	.string	"change directory <dir>"
.LC74:
	.string	"cpm"
.LC75:
	.string	"run ROM CP/M-68"
.LC76:
	.string	"dir"
.LC77:
	.string	"list directory [<vol>:]"
.LC78:
	.string	"dm"
.LC79:
	.string	"synonym for DUMP"
.LC80:
	.string	"dump"
.LC81:
	.string	"dump memory <from> <count>"
.LC82:
	.string	"execute"
.LC83:
	.string	"execute <addr>"
.LC84:
	.string	"help"
.LC85:
	.string	"list this help info"
.LC86:
	.string	"ls"
.LC87:
	.string	"synonym for DIR"
.LC88:
	.string	"rem"
.LC89:
	.string	"remark (in command file)"
.LC90:
	.string	"synonym for SUPV"
.LC91:
	.string	"supv"
.LC92:
	.string	"set Supervisor mode (prefix or command)"
.LC93:
	.string	"today"
.LC94:
	.string	"dispay the date and time"
.LC95:
	.string	"u"
.LC96:
	.string	"synonym for USER"
.LC97:
	.string	"set User mode (prefix or command)"
.LC98:
	.string	"wm"
.LC99:
	.string	"synonym for WRITEMEM"
.LC100:
	.string	"writemem"
.LC101:
	.string	"write memory <addr> [byte ...]"
	.section	.rodata
	.align	2
	.type	cmd_table, @object
	.size	cmd_table, 340
cmd_table:
	.long	.LC72
	.long	1
	.long	1
	.long	do_cd
	.long	.LC73
	.long	.LC74
	.long	0
	.long	1
	.long	do_run_rom_cpm
	.long	.LC75
	.long	.LC76
	.long	0
	.long	1
	.long	do_ls
	.long	.LC77
	.long	.LC78
	.long	2
	.long	2
	.long	do_dump
	.long	.LC79
	.long	.LC80
	.long	2
	.long	2
	.long	do_dump
	.long	.LC81
	.long	.LC82
	.long	1
	.long	2
	.long	do_execute
	.long	.LC83
	.long	.LC84
	.long	0
	.long	0
	.long	help
	.long	.LC85
	.long	.LC86
	.long	0
	.long	1
	.long	do_ls
	.long	.LC87
	.long	.LC88
	.long	0
	.long	0
	.long	do_remark
	.long	.LC89
	.long	.LC38
	.long	0
	.long	0
	.long	do_set_supv
	.long	.LC90
	.long	.LC91
	.long	0
	.long	0
	.long	do_set_supv
	.long	.LC92
	.long	.LC93
	.long	0
	.long	0
	.long	do_today
	.long	.LC94
	.long	.LC95
	.long	0
	.long	0
	.long	do_set_user
	.long	.LC96
	.long	.LC24
	.long	0
	.long	0
	.long	do_set_user
	.long	.LC97
	.long	.LC98
	.long	2
	.long	0
	.long	do_writemem
	.long	.LC99
	.long	.LC100
	.long	2
	.long	0
	.long	do_writemem
	.long	.LC101
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
	.globl	coff_header_bytes
	.type	coff_header_bytes, @object
	.size	coff_header_bytes, 2
coff_header_bytes:
	.byte	1
	.byte	80
	.globl	elf_header_bytes
	.type	elf_header_bytes, @object
	.size	elf_header_bytes, 4
elf_header_bytes:
	.byte	127
	.byte	69
	.byte	76
	.byte	70
	.globl	m68k_header_bytes
	.type	m68k_header_bytes, @object
	.size	m68k_header_bytes, 2
m68k_header_bytes:
	.byte	96
	.byte	26
	.section	.rodata.str1.1
.LC102:
	.string	"CMD"
.LC103:
	.string	"ELF"
.LC104:
	.string	"OUT"
.LC105:
	.string	"68K"
.LC106:
	.string	"SYS"
	.section	.rodata
	.align	4
	.type	exts, @object
	.size	exts, 24
exts:
	.long	.LC102
	.long	.LC103
	.long	.LC104
	.long	.LC105
	.long	.LC106
	.long	0
	.section	.rodata.str1.1
.LC107:
	.string	"Succeeded"
.LC108:
	.string	"A hard error occurred in the low level disk I/O layer"
.LC109:
	.string	"Assertion failed"
.LC110:
	.string	"The physical drive is not operational"
.LC111:
	.string	"Could not find the file"
.LC112:
	.string	"Could not find the path"
.LC113:
	.string	"The path name format is invalid"
.LC114:
	.string	"Access denied due to prohibited access or directory full"
.LC115:
	.string	"Access denied due to prohibited access"
.LC116:
	.string	"The file/directory object is invalid"
.LC117:
	.string	"The physical drive is write protected"
.LC118:
	.string	"The logical drive number is invalid"
.LC119:
	.string	"The volume has no work area"
.LC120:
	.string	"There is no valid FAT volume"
.LC121:
	.string	"The f_mkfs() aborted due to any parameter error"
.LC122:
	.string	"Could not get a grant to access the volume within defined period"
.LC123:
	.string	"The operation is rejected according to the file sharing policy"
.LC124:
	.string	"LFN working buffer could not be allocated"
.LC125:
	.string	"Number of open files > _FS_LOCK"
.LC126:
	.string	"Given parameter is invalid"
	.section	.rodata
	.align	4
	.type	fatfs_errmsg.2196, @object
	.size	fatfs_errmsg.2196, 80
fatfs_errmsg.2196:
	.long	.LC107
	.long	.LC108
	.long	.LC109
	.long	.LC110
	.long	.LC111
	.long	.LC112
	.long	.LC113
	.long	.LC114
	.long	.LC115
	.long	.LC116
	.long	.LC117
	.long	.LC118
	.long	.LC119
	.long	.LC120
	.long	.LC121
	.long	.LC122
	.long	.LC123
	.long	.LC124
	.long	.LC125
	.long	.LC126
	.comm	cmd_buffer,260,1
	.comm	fat_fs_workarea,2216,2
	.comm	auto_boot_time,4,4
	.comm	cmd_level,2,2
	.comm	usermode,4,4
	.ident	"GCC: (GNU) 4.1.1"
