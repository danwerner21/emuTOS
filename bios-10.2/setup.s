#NO_APP
	.file	"setup.c"
	.globl	__modsi3
	.globl	__divsi3
	.text
	.align	2
	.globl	idow
	.type	idow, @function
idow:
	link.w %fp,#-12
	movm.l #0x3830,-(%sp)
	move.l 8(%fp),%d4
	move.l 12(%fp),%a3
	move.l 16(%fp),%d3
	moveq #0,%d0
.L2:
	lea dpm0,%a0
	move.b (%a0,%d0.l),-12(%fp,%d0.l)
	addq.l #1,%d0
	moveq #12,%d1
	cmp.l %d0,%d1
	jbne .L2
	move.l %d3,%d0
	add.l #-1583,%d0
	cmp.l #8416,%d0
	jbhi .L4
	cmp.w #0,%a3
	jble .L4
	cmp.l %a3,%d1
	jblt .L4
	tst.l %d4
	jble .L4
	pea 100.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	move.l %d0,%d1
	moveq #3,%d0
	and.l %d1,%d0
	jbne .L9
	tst.l %d1
	jbeq .L9
	move.b #1,%d0
	jbra .L12
.L9:
	pea 400.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	tst.l %d0
	seq %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
.L12:
	add.b %d0,-1(%fp)
	lea (-3,%a3),%a2
	cmp.w #0,%a2
	jbge .L13
	lea (9,%a3),%a2
	subq.l #1,%d3
.L13:
	moveq #0,%d0
	move.b -12(%a2,%fp.l),%d0
	cmp.l %d4,%d0
	jbge .L15
	moveq #98,%d0
	jbra .L17
.L15:
	pea 100.w
	move.l %d3,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	pea 100.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	move.l %d0,%a0
	moveq #0,%d1
	jbra .L18
.L19:
	moveq #0,%d0
	move.b -12(%fp,%d1.l),%d0
	add.l %d0,%d4
	addq.l #1,%d1
.L18:
	cmp.l %d1,%a2
	jbgt .L19
	move.l %d2,%d0
	add.l %d2,%d0
	add.l %d0,%d0
	add.l %d2,%d0
	add.l %a0,%d0
	move.l %d0,%a1
	add.l %d4,%a1
	move.l %d2,%d0
	jbge .L21
	addq.l #3,%d0
.L21:
	move.l %d0,%d1
	asr.l #2,%d1
	move.l %a0,%d0
	jbge .L22
	addq.l #3,%d0
.L22:
	asr.l #2,%d0
	move.l %d1,%a2
	lea 2(%a2,%d0.l),%a0
	pea 7.w
	pea (%a0,%a1.l)
	jbsr __modsi3
	addq.l #8,%sp
	jbra .L17
.L4:
	moveq #99,%d0
.L17:
	movm.l -32(%fp),#0xc1c
	unlk %fp
	rts
	.size	idow, .-idow
	.globl	__mulsi3
	.align	2
	.globl	calendar_date
	.type	calendar_date, @function
calendar_date:
	link.w %fp,#0
	movm.l #0x3038,-(%sp)
	move.l 8(%fp),%d2
	cmp.l #2299160,%d2
	jbgt .L27
	move.l %d2,%d0
	jbra .L29
.L27:
	move.l %d2,%d0
	add.l %d2,%d0
	add.l %d2,%d0
	move.l %d0,%d1
	lsl.l #5,%d1
	add.l %d1,%d0
	add.l %d2,%d0
	move.l #3652425,-(%sp)
	add.l #-186721625,%d0
	move.l %d0,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d2,%d1
	add.l %d0,%d1
	asr.l #2,%d0
	sub.l %d0,%d1
	move.l %d1,%d0
	addq.l #1,%d0
.L29:
	move.l %d0,%d2
	add.l #1524,%d2
	move.l %d2,%d0
	add.l %d2,%d0
	add.l %d2,%d0
	move.l %d0,%d1
	lsl.l #5,%d1
	add.l %d1,%d0
	move.l %d0,%a0
	add.l %d2,%a0
	lea __divsi3,%a2
	move.l #36525,-(%sp)
	pea -12210(%a0)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%d3
	lea __mulsi3,%a3
	move.l #36525,-(%sp)
	move.l %d0,-(%sp)
	jbsr (%a3)
	addq.w #4,%sp
	move.l #100,(%sp)
	move.l %d0,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	sub.l %d0,%d2
	move.l %d2,%d0
	add.l %d2,%d0
	add.l %d0,%d0
	move.l %d0,%d1
	lsl.l #5,%d1
	sub.l %d0,%d1
	add.l %d2,%d1
	move.l %d1,%d0
	add.l %d1,%d0
	add.l %d0,%d0
	add.l %d0,%d1
	lsl.l #4,%d1
	move.l #306001,-(%sp)
	move.l %d1,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%a4
	move.l #306001,-(%sp)
	move.l %d0,-(%sp)
	jbsr (%a3)
	addq.w #4,%sp
	move.l #10000,(%sp)
	move.l %d0,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l 12(%fp),%a0
	sub.l %d0,%d2
	move.l %d2,(%a0)
	moveq #13,%d0
	cmp.l %a4,%d0
	jblt .L30
	lea (-1,%a4),%a1
	jbra .L32
.L30:
	lea (-13,%a4),%a1
.L32:
	move.l 16(%fp),%a0
	move.l %a1,(%a0)
	moveq #2,%d0
	cmp.l %a1,%d0
	jbge .L33
	move.l %d3,%d0
	add.l #-4716,%d0
	jbra .L35
.L33:
	move.l %d3,%d0
	add.l #-4715,%d0
.L35:
	move.l 20(%fp),%a0
	move.l %d0,(%a0)
	movm.l -20(%fp),#0x1c0c
	unlk %fp
	rts
	.size	calendar_date, .-calendar_date
	.align	2
	.globl	long_time
	.type	long_time, @function
long_time:
	link.w %fp,#0
	movm.l #0x3020,-(%sp)
	move.l 8(%fp),%d3
	lea __divsi3,%a2
	pea 3600.w
	move.l %d3,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l 12(%fp),%a0
	move.l %d0,(%a0)
	move.l %d0,%d2
	lsl.l #5,%d2
	move.l %d2,%d1
	lsl.l #3,%d1
	sub.l %d2,%d1
	add.l %d0,%d1
	lsl.l #4,%d1
	sub.l %d1,%d3
	pea 60.w
	move.l %d3,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l 16(%fp),%a0
	move.l %d0,(%a0)
	add.l %d0,%d0
	add.l %d0,%d0
	move.l %d0,%d1
	lsl.l #4,%d1
	sub.l %d0,%d1
	move.l 20(%fp),%a0
	sub.l %d1,%d3
	move.l %d3,(%a0)
	movm.l -12(%fp),#0x40c
	unlk %fp
	rts
	.size	long_time, .-long_time
	.align	2
	.globl	daytime_c
	.type	daytime_c, @function
daytime_c:
	link.w %fp,#-24
	movm.l #0x3f30,-(%sp)
	move.b 11(%fp),%d4
	move.l timer_ticks,%d0
	move.l %d0,%d1
	add.l %d0,%d1
	add.l %d0,%d1
	move.l %d1,%d0
	lsl.l #3,%d0
	move.l %d1,%d3
	add.l %d0,%d3
	moveq #9,%d0
	asr.l %d0,%d3
	move.l julian_day,%d2
	cmp.b #1,%d4
	jbeq .L40
	cmp.b #3,%d4
	jbls .L42
.L40:
	add.l #-2415386,%d2
	jbra .L43
.L42:
	cmp.b #1,%d4
	jbls .L43
	pea -12(%fp)
	pea -8(%fp)
	pea -4(%fp)
	move.l %d2,-(%sp)
	jbsr calendar_date
	pea -24(%fp)
	pea -20(%fp)
	pea -16(%fp)
	move.l %d3,-(%sp)
	jbsr long_time
	lea (32,%sp),%sp
	move.l -12(%fp),%d2
	cmp.b #2,%d4
	jbne .L45
	lsl.l #4,%d2
	add.l -8(%fp),%d2
	lsl.l #8,%d2
	add.l -4(%fp),%d2
	lsl.l #4,%d2
	pea 7.w
	move.l julian_day,%d1
	addq.l #1,%d1
	move.l %d1,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	add.l %d0,%d2
	move.l -16(%fp),%d0
	lsl.l #8,%d0
	add.l -20(%fp),%d0
	lsl.l #8,%d0
	move.l %d0,%d3
	add.l -24(%fp),%d3
	jbra .L43
.L45:
	lea __divsi3,%a2
	pea 100.w
	move.l %d2,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%d3
	add.l %d3,%d0
	add.l %d3,%d0
	move.l %d0,%d1
	lsl.l #5,%d1
	add.l %d1,%d0
	add.l %d3,%d0
	move.l %d2,%d4
	sub.l %d0,%d4
	move.w #255,%a3
	moveq #99,%d0
	cmp.l %d3,%d0
	jblt .L49
	pea 10.w
	move.l %d3,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	and.l #255,%d0
	move.l %d0,%a3
.L49:
	move.w #255,%a2
	moveq #99,%d1
	cmp.l %d4,%d1
	jblt .L52
	pea 10.w
	move.l %d4,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d4,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	and.l #255,%d0
	move.l %d0,%a2
.L52:
	move.l -8(%fp),%d3
	moveq #0,%d7
	not.b %d7
	moveq #99,%d0
	cmp.l %d3,%d0
	jblt .L55
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	moveq #0,%d7
	move.b %d0,%d7
.L55:
	move.l -4(%fp),%d3
	moveq #0,%d6
	not.b %d6
	moveq #99,%d1
	cmp.l %d3,%d1
	jblt .L58
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	moveq #0,%d6
	move.b %d0,%d6
.L58:
	move.l -16(%fp),%d3
	moveq #0,%d5
	not.b %d5
	moveq #99,%d0
	cmp.l %d3,%d0
	jblt .L61
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	moveq #0,%d5
	move.b %d0,%d5
.L61:
	move.l -20(%fp),%d3
	moveq #0,%d4
	not.b %d4
	moveq #99,%d1
	cmp.l %d3,%d1
	jblt .L64
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	moveq #0,%d4
	move.b %d0,%d4
.L64:
	move.l -24(%fp),%d3
	moveq #0,%d0
	not.b %d0
	moveq #99,%d1
	cmp.l %d3,%d1
	jblt .L67
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	and.l #255,%d0
.L67:
	move.l %a3,%d2
	lsl.l #8,%d2
	move.l %a2,%d1
	or.l %d1,%d2
	lsl.l #8,%d2
	or.l %d7,%d2
	lsl.l #8,%d2
	or.l %d6,%d2
	move.l %d5,%d3
	lsl.l #8,%d3
	or.l %d4,%d3
	lsl.l #8,%d3
	or.l %d0,%d3
.L43:
	move.l %d2,%d0
	clr.l %d1
	or.l %d3,%d1
	movm.l -56(%fp),#0xcfc
	unlk %fp
	rts
	.size	daytime_c, .-daytime_c
	.align	2
	.globl	configure_floppy
	.type	configure_floppy, @function
configure_floppy:
	link.w %fp,#0
	movm.l #0x3f20,-(%sp)
	move.l 8(%fp),%d7
	move.l %d7,%d6
	add.l %d7,%d6
	move.l %d6,%a2
	add.l #nvram+14,%a2
	tst.b (%a2)
	jbeq .L72
	pea 25.w
	jbsr malloc
	move.l %d0,%a1
	lea operation_docb_ptr,%a0
	move.l %d6,%d4
	add.l %d6,%d4
	move.b (%a0,%d4.l),20(%a1)
	move.b 1(%a0,%d4.l),21(%a1)
	move.b 2(%a0,%d4.l),22(%a1)
	move.b 3(%a0,%d4.l),23(%a1)
	move.b (%a2),%d5
	moveq #0,%d0
	move.b %d5,%d0
	add.l %d0,%d0
	add.l %d0,%d0
	lea fdc_parameters,%a0
	move.l (%a0,%d0.l),%d1
	move.l %d1,%d0
	clr.w %d0
	swap %d0
	lsr.w #8,%d0
	move.b %d0,16(%a1)
	move.l %d1,%d0
	clr.w %d0
	swap %d0
	move.b %d0,17(%a1)
	move.l %d1,%d0
	lsr.l #8,%d0
	move.b %d0,18(%a1)
	move.b %d1,19(%a1)
	move.l %d1,%a0
	clr.w %d2
	move.b 11(%a0),%d2
	addq.w #1,%d2
	move.w %d2,%d0
	lsr.w #8,%d0
	move.b %d0,12(%a1)
	and.l #65535,%d2
	move.b %d2,13(%a1)
	move.b #2,14(%a1)
	add.w %d2,%d2
	move.b 16(%a1),%d0
	lsl.w #8,%d0
	swap %d0
	clr.w %d0
	moveq #0,%d1
	move.b 17(%a1),%d1
	swap %d1
	clr.w %d1
	or.l %d0,%d1
	moveq #0,%d0
	move.b 18(%a1),%d0
	lsl.l #8,%d0
	or.l %d1,%d0
	or.b 19(%a1),%d0
	move.l %d0,%a0
	clr.w %d3
	move.b 4(%a0),%d3
	move.b %d3,15(%a1)
	move.l #floppy_ops,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	lsr.w #8,%d1
	move.b %d1,(%a1)
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.b %d1,1(%a1)
	lsr.l #8,%d0
	move.b %d0,2(%a1)
	move.l #floppy_ops,%d0
	moveq #0,%d1
	not.b %d1
	and.l %d1,%d0
	move.b %d0,3(%a1)
	move.b %d5,8(%a1)
	move.l %d6,%a0
	add.l #nvram+13,%a0
	move.b (%a0),9(%a1)
	move.b %d7,10(%a1)
	muls.w %d3,%d2
	and.l #65535,%d2
	clr.b 4(%a1)
	clr.b 5(%a1)
	move.l %d2,%d0
	lsr.l #8,%d0
	move.b %d0,6(%a1)
	move.b %d2,7(%a1)
	lea disk_table,%a0
	move.l %a1,(%a0,%d4.l)
	addq.l #4,%sp
.L72:
	movm.l -28(%fp),#0x4fc
	unlk %fp
	rts
	.size	configure_floppy, .-configure_floppy
	.align	2
	.globl	probe_IDE_disk
	.type	probe_IDE_disk, @function
probe_IDE_disk:
	link.w %fp,#-572
	movm.l #0x38,-(%sp)
	move.l 8(%fp),%a3
	move.l 12(%fp),%a4
	move.l %a3,disk_table+28
	clr.w -60(%fp)
	move.w #10,-58(%fp)
	clr.w -56(%fp)
	move.w #7,-54(%fp)
	lea (-60,%fp),%a0
	move.l %a0,-(%sp)
	move.l %a0,-(%sp)
	jbsr bios_call
	move.w -60(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -58(%fp),%d0
	addq.l #8,%sp
	tst.l %d0
	jbne .L96
	move.b 10(%a3),%d0
	jbne .L76
	btst #0,-53(%fp)
	jbeq .L96
	jbra .L78
.L76:
	cmp.b #16,%d0
	jbne .L78
	btst #1,-53(%fp)
	jbeq .L96
.L78:
	clr.w -60(%fp)
	move.w #11,-58(%fp)
	clr.w -56(%fp)
	move.w #7,-54(%fp)
	move.l %fp,%d0
	add.l #-572,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,-28(%fp)
	move.w %d0,-26(%fp)
	lea (-60,%fp),%a0
	move.l %a0,-(%sp)
	move.l %a0,-(%sp)
	jbsr bios_call
	clr.b (%a4)
	addq.l #8,%sp
	btst #0,-1(%fp)
	jbeq .L81
.L96:
	clr.l disk_table+28
	moveq #0,%d0
	jbra .L80
.L81:
	clr.l disk_table+28
	btst #1,-473(%fp)
	jbeq .L83
	move.w -452(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -450(%fp),%d0
	move.l %d0,-(%sp)
	jbsr bswap
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,4(%a3)
	move.w %d0,6(%a3)
	addq.l #4,%sp
	jbra .L85
.L83:
	clr.w 4(%a3)
	clr.w 6(%a3)
.L85:
	moveq #0,%d0
	move.w -570(%fp),%d0
	move.l %d0,-(%sp)
	lea wswap,%a2
	jbsr (%a2)
	move.w %d0,12(%a3)
	moveq #0,%d0
	move.w -566(%fp),%d0
	move.l %d0,-(%sp)
	jbsr (%a2)
	move.b %d0,14(%a3)
	moveq #0,%d0
	move.w -560(%fp),%d0
	move.l %d0,-(%sp)
	jbsr (%a2)
	move.b %d0,15(%a3)
	pea 16.w
	jbsr malloc
	pea 16.w
	move.l %a3,-(%sp)
	move.l %d0,-(%sp)
	jbsr memmove
	move.l %d0,%a3
	lea (-517,%fp),%a1
	lea (28,%sp),%sp
.L86:
	move.b (%a1),%d0
	move.b -1(%a1),(%a1)
	move.b %d0,-1(%a1)
	addq.l #2,%a1
	lea (-572,%fp),%a2
	lea (95,%a2),%a0
	cmp.l %a1,%a0
	jbne .L86
	move.w #32,%a1
	lea (93,%a2),%a0
.L88:
	move.b (%a0),%d0
	moveq #0,%d1
	move.b %d0,%d1
	cmp.l %d1,%a1
	jbne .L89
	clr.b (%a0)
	tst.b %d0
	jbeq .L89
	subq.l #1,%a0
	move.l %fp,%d0
	add.l #-518,%d0
	cmp.l %a0,%d0
	jbeq .L89
	move.l %d1,%a1
	jbra .L88
.L89:
	pea 40.w
	pea -518(%fp)
	move.l %a4,-(%sp)
	jbsr strncpy
	clr.b 40(%a4)
	move.l %a3,%d0
	lea (12,%sp),%sp
.L80:
	movm.l -584(%fp),#0x1c00
	unlk %fp
	rts
	.size	probe_IDE_disk, .-probe_IDE_disk
	.align	2
	.globl	get_nvram
	.type	get_nvram, @function
get_nvram:
	link.w %fp,#0
	movm.l #0x3030,-(%sp)
	clr.b %d3
	moveq #32,%d2
.L98:
	move.l %d2,-(%sp)
	lea rtc_get_loc,%a2
	jbsr (%a2)
	add.b %d0,%d3
	moveq #31,%d1
	and.l %d2,%d1
	lea nvram,%a3
	move.b %d0,(%a3,%d1.l)
	addq.l #1,%d2
	addq.l #4,%sp
	moveq #63,%d0
	cmp.l %d2,%d0
	jbne .L98
	cmp.b #-94,%d3
	jbne .L100
	clr.l -(%sp)
	jbsr (%a2)
	addq.l #4,%sp
	tst.b %d0
	jbge .L102
.L100:
	clr.b nvram_valid
	pea 31.w
	pea nvram0
	move.l %a3,-(%sp)
	jbsr memcpy
	lea (12,%sp),%sp
	jbra .L104
.L102:
	move.b #1,nvram_valid
.L104:
	movm.l -16(%fp),#0xc0c
	unlk %fp
	rts
	.size	get_nvram, .-get_nvram
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	" %c:  %s\n"
.LC1:
	.string	"Boot at %2u:%02u:%02u on %2u%02u-%02u-%02u   %8luJ %8luT\n"
.LC2:
	.string	"BIOS version 10.2 of 16-May-2016        Mon May 16 17:17:57 PDT 2016\n"
	.text
	.align	2
	.globl	configure
	.type	configure, @function
configure:
	link.w %fp,#-76
	movm.l #0x3f30,-(%sp)
	tst.b nvram_valid
	jbne .L108
	jbsr get_nvram
.L108:
	lea disk_table,%a0
.L110:
	clr.l (%a0)+
	cmp.l #disk_table+32,%a0
	jbne .L110
	moveq #0,%d5
.L112:
	move.l %d5,-(%sp)
	jbsr configure_floppy
	addq.l #1,%d5
	addq.l #4,%sp
	moveq #2,%d0
	cmp.l %d5,%d0
	jbne .L112
	moveq #0,%d7
	lea nvram+5,%a3
	moveq #8,%d6
	jbra .L114
.L115:
	pea 16.w
	clr.l -(%sp)
	pea -32(%fp)
	jbsr memset
	move.b (%a3),%d1
	move.b 1(%a3),%d3
	lea (12,%sp),%sp
	cmp.b #2,%d3
	jbeq .L118
	jbhi .L120
	cmp.b #1,%d3
	jbne .L116
	jbra .L117
.L120:
	cmp.b #3,%d3
	jbeq .L117
	cmp.b #4,%d3
	jbeq .L119
.L116:
	moveq #0,%d2
	jbra .L121
.L117:
	move.l #ppide_ops,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-32(%fp)
	move.l #ppide_ops,%d0
	and.l #65535,%d0
	move.w %d0,-30(%fp)
	move.b #8,-24(%fp)
	jbra .L143
.L118:
	move.l #dide_ops,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-32(%fp)
	move.l #dide_ops,%d0
	and.l #65535,%d0
	move.w %d0,-30(%fp)
	move.b #9,-24(%fp)
	moveq #4,%d2
	jbra .L121
.L119:
	move.l #dualsd_ops,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-32(%fp)
	move.l #dualsd_ops,%d0
	and.l #65535,%d0
	move.w %d0,-30(%fp)
	move.b #12,-24(%fp)
.L143:
	moveq #2,%d2
.L121:
	move.b %d1,-23(%fp)
	moveq #0,%d4
	jbra .L144
.L123:
	move.b %d4,-22(%fp)
	cmp.b #4,%d3
	jbeq .L124
	lea (-74,%fp),%a2
	move.l %a2,-(%sp)
	pea -32(%fp)
	jbsr probe_IDE_disk
	addq.l #8,%sp
	tst.l %d0
	jbeq .L126
	lea disk_table,%a0
	move.l %d0,(%a0,%d6.l)
	addq.l #1,%d5
	addq.l #4,%d6
	move.l %a2,-(%sp)
	move.b %d5,%d0
	add.b #64,%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	pea .LC0
	jbsr cprintf
	lea (12,%sp),%sp
.L126:
	eor.w #16,%d4
.L128:
	moveq #2,%d0
	cmp.l %d2,%d0
	jbne .L144
	add.b #16,-23(%fp)
.L144:
	dbra %d2,.L123
	clr.w %d2
	subq.l #1,%d2
	jbcc .L123
	addq.l #1,%d7
	addq.l #2,%a3
.L114:
	moveq #0,%d0
	move.b nvram+4,%d0
	cmp.l %d7,%d0
	jble .L131
	moveq #7,%d1
	cmp.l %d5,%d1
	jbge .L115
	jbra .L131
.L124:
	addq.l #1,%d4
	jbra .L128
.L131:
	pea -8(%fp)
	jbsr get_rtc_time
	move.l %d0,timer_ticks
	pea -16(%fp)
	jbsr get_rtc_date
	move.l %d0,julian_day
	move.w -4(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -2(%fp),%d0
	move.l %d0,-(%sp)
	move.w -12(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -10(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b -13(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b -14(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b -15(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b -16(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b -5(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b -6(%fp),%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b -7(%fp),%d0
	move.l %d0,-(%sp)
	pea .LC1
	lea cprintf,%a2
	jbsr (%a2)
	lea (44,%sp),%sp
	move.l #.LC2,(%sp)
	jbsr (%a2)
	movm.l -108(%fp),#0xcfc
	unlk %fp
	rts
	.size	configure, .-configure
	.section	.rodata.str1.1
.LC3:
	.string	"Set %s boot device [%c]: "
	.text
	.align	2
	.type	set_boot, @function
set_boot:
	link.w %fp,#-8
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%d2
	move.l 12(%fp),%a2
.L162:
	pea 65(%a2)
	move.l %d2,-(%sp)
	pea .LC3
	jbsr cprintf
	pea 6.w
	pea -6(%fp)
	jbsr getline
	move.b -6(%fp),%d0
	lea (20,%sp),%sp
	jbeq .L148
	ext.w %d0
	move.w %d0,%a1
	move.l __ctype_ptr,%a0
	btst #1,(%a1,%a0.l)
	jbne .L150
	move.l %a1,%a0
	jbra .L152
.L150:
	lea (-32,%a1),%a0
.L152:
	lea (-65,%a0),%a0
	moveq #7,%d0
	cmp.l %a0,%d0
	jbcs .L162
	tst.b -5(%fp)
	jbne .L162
	cmp.w #0,%a0
	jblt .L162
	move.l %a0,%a2
.L148:
	move.l %a2,%d0
	move.l -16(%fp),%d2
	move.l -12(%fp),%a2
	unlk %fp
	rts
	.size	set_boot, .-set_boot
	.section	.rodata.str1.1
.LC4:
	.string	"first"
.LC5:
	.string	"second"
	.text
	.align	2
	.globl	set_boot_order
	.type	set_boot_order, @function
set_boot_order:
	link.w %fp,#0
	move.l %a3,-(%sp)
	move.l %a2,-(%sp)
	lea nvram+3,%a2
	move.b (%a2),%d0
	asr.b #4,%d0
	ext.w %d0
	move.w %d0,%a0
	move.l %a0,-(%sp)
	pea .LC4
	lea set_boot,%a3
	jbsr (%a3)
	lsl.b #4,%d0
	move.b (%a2),%d1
	and.b #15,%d1
	or.b %d0,%d1
	move.b %d1,(%a2)
	lsl.b #4,%d1
	asr.b #4,%d1
	ext.w %d1
	move.w %d1,%a0
	move.l %a0,-(%sp)
	pea .LC5
	jbsr (%a3)
	and.b #15,%d0
	move.b (%a2),%d1
	and.b #-16,%d1
	or.b %d0,%d1
	move.b %d1,(%a2)
	lea (16,%sp),%sp
	move.l -8(%fp),%a2
	move.l -4(%fp),%a3
	unlk %fp
	rts
	.size	set_boot_order, .-set_boot_order
	.section	.rodata.str1.1
.LC6:
	.string	"Autoboot timeout (seconds), 0 disables [%hd]: "
.LC7:
	.string	"Timeout may not be longer than 4 minutes (240 seconds).\n"
	.text
	.align	2
	.globl	set_autoboot
	.type	set_autoboot, @function
set_autoboot:
	link.w %fp,#-16
	move.l %a3,-(%sp)
	move.l %a2,-(%sp)
.L167:
	moveq #0,%d0
	move.b nvram+17,%d0
	move.l %d0,-(%sp)
	pea .LC6
	lea cprintf,%a3
	jbsr (%a3)
	pea 16.w
	lea (-16,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (16,%sp),%sp
	tst.b -16(%fp)
	jbeq .L172
	move.l %a2,-(%sp)
	jbsr atoi
	addq.l #4,%sp
	cmp.l #240,%d0
	jbhi .L170
	move.b %d0,nvram+17
	jbra .L172
.L170:
	pea .LC7
	jbsr (%a3)
	addq.l #4,%sp
	jbra .L167
.L172:
	move.l -24(%fp),%a2
	move.l -20(%fp),%a3
	unlk %fp
	rts
	.size	set_autoboot, .-set_autoboot
	.section	.rodata.str1.1
.LC8:
	.string	"Serial port baud rate (Kbit/sec) [%d]: "
.LC9:
	.string	"Invalid selection; allowable bit rates are:"
.LC10:
	.string	" %d"
.LC11:
	.string	"\n"
	.text
	.align	2
	.globl	set_serial
	.type	set_serial, @function
set_serial:
	link.w %fp,#-16
	movm.l #0x3038,-(%sp)
	moveq #0,%d1
	move.b nvram,%d1
	moveq #0,%d0
	move.b nvram+1,%d0
	lsl.l #8,%d0
	move.l %d1,%a0
	pea (%a0,%d0.l)
	move.l #115200,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
.L174:
	move.l %d2,-(%sp)
	pea .LC8
	jbsr cprintf
	pea 16.w
	lea (-16,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (16,%sp),%sp
	tst.b -16(%fp)
	jbeq .L175
	move.l %a2,-(%sp)
	jbsr atoi
	moveq #0,%d1
	lea rates.2366,%a0
	addq.l #4,%sp
.L177:
	cmp.l (%a0),%d0
	jbne .L178
	moveq #15,%d3
	cmp.l %d1,%d3
	jbeq .L181
	jbra .L180
.L178:
	addq.l #1,%d1
	addq.l #4,%a0
	moveq #15,%d3
	cmp.l %d1,%d3
	jbne .L177
.L181:
	pea .LC9
	lea cprintf,%a2
	jbsr (%a2)
	pea 300.w
	pea .LC10
	jbsr (%a2)
	move.w #1,%a2
	lea (12,%sp),%sp
.L182:
	lea (%a2,%a2.l),%a0
	add.l %a0,%a0
	move.l %a0,%a4
	add.l #rates.2366,%a4
.L183:
	move.l (%a4)+,-(%sp)
	pea .LC10
	lea cprintf,%a3
	jbsr (%a3)
	addq.l #8,%sp
	moveq #6,%d0
	cmp.l %a2,%d0
	jbne .L184
	pea .LC11
	jbsr (%a3)
	move.w #7,%a2
	addq.l #4,%sp
	jbra .L183
.L184:
	addq.l #1,%a2
	moveq #14,%d3
	cmp.l %a2,%d3
	jbcc .L182
	pea .LC11
	jbsr (%a3)
	addq.l #4,%sp
	jbra .L174
.L180:
	move.l %d0,%d2
.L175:
	move.l %d2,-(%sp)
	move.l #115200,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d1
	and.l #-2147483393,%d1
	jbge .L187
	subq.l #1,%d1
	moveq #-1,%d3
	not.b %d3
	or.l %d3,%d1
	addq.l #1,%d1
.L187:
	move.b %d1,nvram
	tst.l %d0
	jbge .L188
	add.l #255,%d0
.L188:
	asr.l #8,%d0
	move.b %d0,nvram+1
	move.l %d2,%d0
	movm.l -36(%fp),#0x1c0c
	unlk %fp
	rts
	.size	set_serial, .-set_serial
	.section	.rodata.str1.1
.LC12:
	.string	"Floppy disk types are:\n   %d  not present\n   %d  1.2M 5.25\"\n   %d  720K 3.5\"\n   %d  1.44M 3.5\"\n"
.LC13:
	.string	"Floppy disk %c type [%d]: "
	.text
	.align	2
	.globl	set_dide_floppy
	.type	set_dide_floppy, @function
set_dide_floppy:
	link.w %fp,#-20
	movm.l #0x303c,-(%sp)
	clr.w %d3
	lea nvram+6,%a5
.L194:
	cmp.b #2,(%a5)
	jbne .L195
	pea 4.w
	pea 3.w
	pea 2.w
	clr.l -(%sp)
	pea .LC12
	jbsr cprintf
	sub.l %a4,%a4
	lea nvram+14,%a3
	lea (20,%sp),%sp
.L197:
	clr.w %d2
	move.b (%a3),%d2
.L218:
	clr.l errno
	move.w %d2,-(%sp)
	clr.w -(%sp)
	pea 65(%a4)
	pea .LC13
	jbsr cprintf
	pea 20.w
	lea (-20,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (20,%sp),%sp
	tst.b -20(%fp)
	jbeq .L199
	move.l %a2,-(%sp)
	jbsr atoi
	move.w %d0,%d2
	addq.l #4,%sp
.L199:
	tst.l errno
	jbne .L218
	moveq #0,%d1
	move.w %d2,%d1
	moveq #29,%d0
	btst %d1,%d0
	jbeq .L218
	move.b %d2,(%a3)
	tst.w %d2
	jbeq .L203
	move.b -1(%a5),%d0
	add.b #10,%d0
	move.b %d0,-1(%a3)
	addq.w #1,%d3
.L205:
	addq.l #1,%a4
	addq.l #2,%a3
	moveq #2,%d0
	cmp.l %a4,%d0
	jbne .L197
.L195:
	addq.l #2,%a5
	cmp.l #nvram+14,%a5
	jbne .L194
	tst.w %d3
	jbne .L207
	clr.b nvram+14
	clr.b nvram+13
	clr.b nvram+16
	clr.b nvram+15
	jbra .L207
.L203:
	clr.b -1(%a3)
	jbra .L205
.L207:
	moveq #0,%d0
	move.w %d3,%d0
	movm.l -44(%fp),#0x3c0c
	unlk %fp
	rts
	.size	set_dide_floppy, .-set_dide_floppy
	.section	.rodata.str1.1
.LC14:
	.string	"The clock is stopped.\n"
.LC15:
	.string	"Time read:  %02x:%02x:%02x\n"
.LC16:
	.string	"Time [hh:mm[:ss]]: "
.LC17:
	.string	"Read in %d:%02d:%02d\n"
	.text
	.align	2
	.globl	Time
	.type	Time, @function
Time:
	link.w %fp,#-80
	movm.l #0x3e30,-(%sp)
	clr.l -(%sp)
	lea rtc_get_loc,%a2
	jbsr (%a2)
	clr.w %d5
	move.b %d0,%d5
	pea 1.w
	jbsr (%a2)
	clr.w %d4
	move.b %d0,%d4
	pea 2.w
	jbsr (%a2)
	clr.w %d6
	move.b %d0,%d6
	moveq #0,%d0
	move.w %d5,%d0
	lea (12,%sp),%sp
	lea cprintf,%a0
	tst.b %d0
	jbge .L220
	pea .LC14
	jbsr (%a0)
	addq.l #4,%sp
	jbra .L241
.L220:
	move.l %d0,-(%sp)
	move.w %d4,-(%sp)
	clr.w -(%sp)
	move.w %d6,-(%sp)
	clr.w -(%sp)
	pea .LC15
	jbsr (%a0)
	lea (16,%sp),%sp
.L241:
	pea .LC16
	jbsr cprintf
	pea 80.w
	lea (-80,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (12,%sp),%sp
	tst.b -80(%fp)
	jbeq .L233
	pea 58.w
	move.l %a2,-(%sp)
	lea strchr,%a3
	jbsr (%a3)
	addq.l #8,%sp
	move.l %d0,%a0
	tst.l %d0
	jbeq .L225
	clr.b (%a0)+
	move.l %a0,%d2
	move.l %a2,-(%sp)
	lea atoi,%a2
	jbsr (%a2)
	move.w %d0,%d6
	pea 58.w
	move.l %d2,-(%sp)
	jbsr (%a3)
	move.l %d0,%a0
	lea (12,%sp),%sp
	tst.l %d0
	jbeq .L227
	clr.b (%a0)+
	move.l %a0,%d3
	move.l %d2,-(%sp)
	jbsr (%a2)
	move.w %d0,%d4
	addq.l #4,%sp
	tst.l %d3
	jbeq .L225
	move.l %d3,-(%sp)
	jbsr (%a2)
	move.w %d0,%d5
.L240:
	addq.l #4,%sp
.L225:
	cmp.w #23,%d6
	jbhi .L241
	cmp.w #59,%d4
	jbhi .L241
	cmp.w #59,%d5
	jbhi .L241
	move.w %d5,-(%sp)
	clr.w -(%sp)
	move.w %d4,-(%sp)
	clr.w -(%sp)
	move.w %d6,-(%sp)
	clr.w -(%sp)
	pea .LC17
	jbsr cprintf
	move.w %d5,%d1
	mulu.w #52429,%d1
	clr.w %d1
	swap %d1
	lsr.w #3,%d1
	move.b %d1,%d3
	lsl.b #4,%d3
	move.w %d1,%d0
	add.w %d1,%d0
	add.w %d0,%d0
	add.w %d1,%d0
	add.w %d0,%d0
	sub.w %d0,%d5
	or.b %d5,%d3
	moveq #127,%d0
	not.b %d0
	or.b %d3,%d0
	move.l %d0,-(%sp)
	clr.l -(%sp)
	lea rtc_set_loc,%a2
	jbsr (%a2)
	move.w %d4,%d1
	mulu.w #52429,%d1
	clr.w %d1
	swap %d1
	lsr.w #3,%d1
	move.b %d1,%d2
	lsl.b #4,%d2
	move.w %d1,%d0
	add.w %d1,%d0
	add.w %d0,%d0
	add.w %d1,%d0
	add.w %d0,%d0
	sub.w %d0,%d4
	or.b %d4,%d2
	and.l #255,%d2
	move.l %d2,-(%sp)
	pea 1.w
	jbsr (%a2)
	lea (32,%sp),%sp
	move.w %d6,%d1
	mulu.w #52429,%d1
	clr.w %d1
	swap %d1
	lsr.w #3,%d1
	move.b %d1,%d2
	lsl.b #4,%d2
	move.w %d1,%d0
	add.w %d1,%d0
	add.w %d0,%d0
	add.w %d1,%d0
	add.w %d0,%d0
	sub.w %d0,%d6
	or.b %d6,%d2
	and.l #255,%d2
	move.l %d2,-(%sp)
	pea 2.w
	jbsr (%a2)
	and.l #255,%d3
	move.l %d3,-(%sp)
	clr.l -(%sp)
	jbsr (%a2)
	lea (16,%sp),%sp
	jbra .L233
.L227:
	move.l %d2,-(%sp)
	jbsr (%a2)
	move.w %d0,%d4
	clr.w %d5
	jbra .L240
.L233:
	movm.l -108(%fp),#0xc7c
	unlk %fp
	rts
	.size	Time, .-Time
	.section	.rodata.str1.1
.LC18:
	.string	"Date read:  %s %02x/%02x/%02x%02x\n"
.LC19:
	.string	"Date [mm/dd/yyyy]: "
.LC20:
	.string	"Binary date:  %d/%d/%d\n"
.LC21:
	.string	"Invalid date entered.  (code %d)\n"
.LC22:
	.string	"BCD date to be set to DS1302:  %02x/%02x/%02x%02x  dow(%x)\n"
	.text
	.align	2
	.globl	Date
	.type	Date, @function
Date:
	link.w %fp,#-84
	movm.l #0x3f3c,-(%sp)
	tst.b nvram_valid
	jbne .L243
	moveq #3,%d2
	moveq #1,%d5
	moveq #1,%d4
	moveq #1,%d3
	moveq #25,%d1
	jbra .L245
.L243:
	pea 3.w
	lea rtc_get_loc,%a2
	jbsr (%a2)
	move.b %d0,%d5
	pea 4.w
	jbsr (%a2)
	move.b %d0,%d4
	pea 5.w
	jbsr (%a2)
	move.b %d0,%d2
	pea 6.w
	jbsr (%a2)
	move.b %d0,%d3
	pea 34.w
	jbsr (%a2)
	move.b %d0,%d1
	move.b %d2,%d0
	subq.b #1,%d0
	lea (20,%sp),%sp
	cmp.b #6,%d0
	jbls .L245
	moveq #8,%d2
.L245:
	moveq #0,%d0
	move.b %d3,%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b %d1,%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b %d5,%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b %d4,%d0
	move.l %d0,-(%sp)
	moveq #0,%d0
	move.b %d2,%d0
	add.l %d0,%d0
	move.l %d0,%a0
	add.l %d0,%a0
	add.l #dow-4,%a0
	move.l (%a0),-(%sp)
	pea .LC18
	lea cprintf,%a5
	jbsr (%a5)
	pea .LC19
	jbsr (%a5)
	pea 80.w
	lea (-80,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (36,%sp),%sp
	tst.b -80(%fp)
	jbeq .L247
	pea 47.w
	move.l %a2,-(%sp)
	lea strchr,%a4
	jbsr (%a4)
	addq.l #8,%sp
	move.l %d0,%a0
	tst.l %d0
	jbeq .L247
	clr.b (%a0)+
	move.l %a0,%d2
	move.l %a2,-(%sp)
	lea atoi,%a3
	jbsr (%a3)
	move.l %d0,%d5
	pea 47.w
	move.l %d2,-(%sp)
	jbsr (%a4)
	move.l %d0,%a2
	lea (12,%sp),%sp
	tst.l %d0
	jbeq .L247
	clr.b (%a2)+
	move.l %d2,-(%sp)
	jbsr (%a3)
	move.l %d0,%d3
	move.l %a2,-(%sp)
	jbsr (%a3)
	move.l %d0,%d6
	move.l %d0,-(%sp)
	move.l %d3,-(%sp)
	move.l %d5,-(%sp)
	pea .LC20
	jbsr (%a5)
	lea (24,%sp),%sp
	moveq #99,%d0
	cmp.l %d5,%d0
	jbge .L251
	st -81(%fp)
	jbra .L253
.L251:
	pea 10.w
	move.l %d5,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d5,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	move.b %d0,-81(%fp)
.L253:
	moveq #99,%d0
	cmp.l %d3,%d0
	jbge .L254
	st -82(%fp)
	jbra .L256
.L254:
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d3,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	or.b %d2,%d0
	move.b %d0,-82(%fp)
.L256:
	lea __divsi3,%a2
	pea 100.w
	move.l %d6,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%d4
	moveq #99,%d0
	cmp.l %d4,%d0
	jbge .L257
	st %d7
	jbra .L259
.L257:
	pea 10.w
	move.l %d4,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d4,-(%sp)
	jbsr __modsi3
	addq.l #8,%sp
	move.b %d0,%d7
	or.b %d2,%d7
.L259:
	lea __modsi3,%a2
	pea 100.w
	move.l %d6,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%d4
	moveq #99,%d0
	cmp.l %d4,%d0
	jbge .L260
	st %d2
	jbra .L262
.L260:
	pea 10.w
	move.l %d4,-(%sp)
	jbsr __divsi3
	addq.l #8,%sp
	move.l %d0,%d2
	lsl.l #4,%d2
	pea 10.w
	move.l %d4,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	or.b %d0,%d2
.L262:
	move.l %d6,-(%sp)
	move.l %d5,-(%sp)
	move.l %d3,-(%sp)
	jbsr idow
	lea (12,%sp),%sp
	lea cprintf,%a0
	cmp.b #7,%d0
	jbls .L263
	and.l #255,%d0
	move.l %d0,-(%sp)
	pea .LC21
	jbsr (%a0)
	moveq #0,%d6
	addq.l #8,%sp
	jbra .L265
.L263:
	addq.b #1,%d0
	moveq #0,%d4
	move.b %d0,%d4
	moveq #0,%d5
	move.b %d2,%d5
	moveq #0,%d6
	move.b %d7,%d6
	moveq #0,%d2
	move.b -82(%fp),%d2
	moveq #0,%d3
	move.b -81(%fp),%d3
	move.l %d4,-(%sp)
	move.l %d5,-(%sp)
	move.l %d6,-(%sp)
	move.l %d2,-(%sp)
	move.l %d3,-(%sp)
	pea .LC22
	jbsr (%a0)
	clr.l -(%sp)
	pea 7.w
	lea rtc_set_loc,%a2
	jbsr (%a2)
	lea (28,%sp),%sp
	move.l %d2,(%sp)
	pea 3.w
	jbsr (%a2)
	move.l %d3,-(%sp)
	pea 4.w
	jbsr (%a2)
	move.l %d4,-(%sp)
	pea 5.w
	jbsr (%a2)
	move.l %d5,-(%sp)
	pea 6.w
	jbsr (%a2)
	move.b %d7,nvram+2
	lea (32,%sp),%sp
	jbra .L265
.L247:
	moveq #0,%d6
.L265:
	move.l %d6,%d0
	movm.l -124(%fp),#0x3cfc
	unlk %fp
	rts
	.size	Date, .-Date
	.section	.rodata.str1.1
.LC23:
	.string	"En"
.LC24:
	.string	"Trickle charge backup is %sabled.\n"
.LC25:
	.string	""
.LC26:
	.string	"Dis"
.LC27:
	.string	"n"
.LC28:
	.string	"s are"
.LC29:
	.string	" is"
.LC30:
	.string	"   %d diode%s used.  A%s %dK resistor is selected.\n"
.LC31:
	.string	"Diode (0,1,2) & Resistor (2,4,8) [d[+r]]: "
	.text
	.align	2
	.globl	set_battery
	.type	set_battery, @function
set_battery:
	link.w %fp,#-80
	movm.l #0x3830,-(%sp)
	pea 8.w
	jbsr rtc_get_loc
	move.b %d0,%d1
	lsr.b #4,%d1
	addq.l #4,%sp
	cmp.b #10,%d1
	seq %d1
	ext.w %d1
	ext.l %d1
	neg.l %d1
	move.b %d0,%d3
	lsr.b #2,%d3
	and.b #3,%d3
	move.b %d0,%d2
	and.b #3,%d2
	sne %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
	and.l %d0,%d1
	move.b %d3,%d0
	subq.b #1,%d0
	cmp.b #1,%d0
	sls %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
	and.l %d1,%d0
	lea cprintf,%a0
	jbeq .L268
	moveq #0,%d1
	move.b %d2,%d1
	moveq #1,%d0
	lsl.l %d1,%d0
	move.b %d0,%d2
	pea .LC23
	pea .LC24
	jbsr (%a0)
	addq.l #8,%sp
	lea .LC25,%a0
	cmp.b #8,%d2
	jbne .L272
	jbra .L270
.L268:
	pea .LC26
	pea .LC24
	jbsr (%a0)
	addq.l #8,%sp
	jbra .L296
.L270:
	lea .LC27,%a0
.L272:
	move.l #.LC28,%d1
	cmp.b #1,%d3
	jbne .L276
	jbra .L274
.L295:
	moveq #0,%d2
	jbra .L279
.L274:
	move.l #.LC29,%d1
.L276:
	moveq #0,%d0
	move.b %d2,%d0
	move.l %d0,-(%sp)
	move.l %a0,-(%sp)
	move.l %d1,-(%sp)
	moveq #3,%d0
	and.l %d3,%d0
	move.l %d0,-(%sp)
	pea .LC30
	jbsr cprintf
	lea (20,%sp),%sp
.L296:
	pea .LC31
	jbsr cprintf
	pea 80.w
	lea (-80,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (12,%sp),%sp
	tst.b -80(%fp)
	jbeq .L295
	pea 43.w
	move.l %a2,-(%sp)
	jbsr strchr
	addq.l #8,%sp
	move.l %d0,%a0
	lea atoi,%a3
	tst.l %d0
	jbeq .L280
	clr.b (%a0)+
	move.l %a0,%d3
	move.l %a2,-(%sp)
	jbsr (%a3)
	move.b %d0,%d4
	addq.l #4,%sp
	tst.l %d3
	jbeq .L282
	move.l %d3,-(%sp)
	jbsr (%a3)
	move.b %d0,%d2
.L298:
	addq.l #4,%sp
.L282:
	cmp.b #2,%d2
	jbeq .L284
	cmp.b #4,%d2
	jbeq .L284
	cmp.b #8,%d2
	jbne .L287
.L284:
	move.b %d4,%d0
	subq.b #1,%d0
	cmp.b #1,%d0
	jbhi .L287
	move.b %d2,%d1
	lsr.b #1,%d1
	cmp.b #4,%d1
	jbne .L289
	moveq #3,%d1
.L289:
	moveq #0,%d0
	move.b %d4,%d0
	add.l %d0,%d0
	add.l %d0,%d0
	or.b #-96,%d1
	or.b %d0,%d1
	jbra .L291
.L287:
	tst.b %d2
	jbeq .L292
	tst.b %d4
	jbne .L296
.L292:
	clr.b %d1
.L291:
	moveq #0,%d2
	move.b %d1,%d2
	move.l %d2,-(%sp)
	pea 8.w
	jbsr rtc_set_loc
	addq.l #8,%sp
	jbra .L279
.L280:
	move.l %a2,-(%sp)
	jbsr (%a3)
	move.b %d0,%d4
	jbra .L298
.L279:
	move.l %d2,%d0
	movm.l -100(%fp),#0xc1c
	unlk %fp
	rts
	.size	set_battery, .-set_battery
	.section	.rodata.str1.1
.LC32:
	.string	"IDE board types are:\n   %d  not present\n   %d  Parallel Port\n   %d  Dual IDE\n   %d  DiskIO v2\n   %d  Dual SD\n"
.LC33:
	.string	"Board #%d type [%d]: "
.LC34:
	.string	"Base port address (hex) [%02x]: "
	.globl	__umodsi3
	.text
	.align	2
	.globl	set_disk_boards
	.type	set_disk_boards, @function
set_disk_boards:
	link.w %fp,#-20
	movm.l #0x3830,-(%sp)
	pea 4.w
	pea 3.w
	pea 2.w
	pea 1.w
	clr.l -(%sp)
	pea .LC32
	jbsr cprintf
	moveq #0,%d3
	lea nvram+5,%a3
	lea (24,%sp),%sp
.L300:
	clr.l errno
.L326:
	moveq #0,%d2
	move.b 1(%a3),%d2
	move.l %d3,%d4
	addq.l #1,%d4
	move.l %d2,-(%sp)
	move.l %d4,-(%sp)
	pea .LC33
	jbsr cprintf
	pea 20.w
	lea (-20,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (20,%sp),%sp
	tst.b -20(%fp)
	jbeq .L302
	move.l %a2,-(%sp)
	jbsr atoi
	move.l %d0,%d2
	addq.l #4,%sp
.L302:
	tst.l errno
	jbne .L326
	moveq #4,%d0
	cmp.l %d2,%d0
	jbcs .L326
	move.b %d2,1(%a3)
	tst.l %d2
	jbne .L327
	move.l %d3,%a0
	add.l %d3,%a0
	add.l #nvram+5,%a0
	clr.b (%a0)
	move.l %d3,%d4
	jbra .L308
.L327:
	moveq #0,%d3
	move.b (%a3),%d3
	move.l %d3,-(%sp)
	pea .LC34
	jbsr cprintf
	pea 20.w
	lea (-20,%fp),%a2
	move.l %a2,-(%sp)
	jbsr getline
	lea (16,%sp),%sp
	tst.b -20(%fp)
	jbeq .L309
	pea 16.w
	clr.l -(%sp)
	move.l %a2,-(%sp)
	jbsr strtoul
	move.l %d0,%d3
	lea (12,%sp),%sp
.L309:
	tst.l errno
	jbne .L327
	move.l %d2,%d0
	add.l %d2,%d0
	add.l %d0,%d0
	lea mods,%a0
	move.l (%a0,%d0.l),-(%sp)
	move.l %d3,-(%sp)
	jbsr __umodsi3
	addq.l #8,%sp
	tst.l %d0
	jbne .L327
	move.b %d3,(%a3)
	addq.l #2,%a3
	move.b #4,%d0
	cmp.l %d4,%d0
	jbeq .L308
	move.l %d4,%d3
	jbra .L300
.L308:
	move.b %d4,nvram+4
	moveq #0,%d0
	move.b %d4,%d0
	movm.l -40(%fp),#0xc1c
	unlk %fp
	rts
	.size	set_disk_boards, .-set_disk_boards
	.section	.rodata.str1.1
.LC35:
	.string	"\nStart of Setup.\n"
.LC36:
	.string	"The MF/PIC UART is %s\n"
.LC37:
	.string	"In"
.LC38:
	.string	"The contents of NVRAM are %svalid.\n"
.LC39:
	.string	"stopped"
.LC40:
	.string	"running"
.LC41:
	.string	"The clock is %s.\n\n"
.LC42:
	.string	"Non-volatile Setup RAM has been updated.\n"
	.text
	.align	2
	.globl	setup
	.type	setup, @function
setup:
	link.w %fp,#0
	movm.l #0x3020,-(%sp)
	move.l 8(%fp),%d0
	jbne .L329
	pea 31.w
	pea nvram0
	pea nvram
	jbsr memcpy
	clr.b nvram_valid
	clr.l -(%sp)
	pea 7.w
	jbsr rtc_set_loc
	lea (20,%sp),%sp
	jbra .L331
.L329:
	moveq #115,%d1
	cmp.l %d0,%d1
	jbeq .L332
	move.b #83,%d1
	cmp.l %d0,%d1
	jbeq .L332
	tst.b nvram_valid
	jbne .L344
.L332:
	pea .LC35
	lea cprintf,%a2
	jbsr (%a2)
	move.b uart_type,%d0
	lsl.l #2,%d0
	and.l #1020,%d0
	lea uart,%a0
	move.l (%a0,%d0.l),-(%sp)
	pea .LC36
	jbsr (%a2)
	lea (12,%sp),%sp
	move.l #.LC25,%d0
	tst.b nvram_valid
	jbne .L338
	move.l #.LC37,%d0
.L338:
	move.l %d0,-(%sp)
	pea .LC38
	jbsr cprintf
	clr.l -(%sp)
	jbsr rtc_get_loc
	lea (12,%sp),%sp
	move.l #.LC39,%d1
	tst.b %d0
	jblt .L341
	move.l #.LC40,%d1
.L341:
	move.l %d1,-(%sp)
	pea .LC41
	jbsr cprintf
	jbsr set_serial
	clr.l -(%sp)
	pea 7.w
	jbsr rtc_set_loc
	jbsr set_battery
	jbsr Date
	jbsr Time
	jbsr set_disk_boards
	jbsr set_dide_floppy
	jbsr set_autoboot
	jbsr set_boot_order
	lea (16,%sp),%sp
.L331:
	clr.b %d3
	moveq #32,%d2
.L342:
	moveq #31,%d0
	and.l %d2,%d0
	lea nvram,%a0
	move.b (%a0,%d0.l),%d0
	and.l #255,%d0
	add.b %d0,%d3
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	lea rtc_set_loc,%a2
	jbsr (%a2)
	addq.l #1,%d2
	addq.l #8,%sp
	moveq #62,%d0
	cmp.l %d2,%d0
	jbne .L342
	moveq #-94,%d0
	sub.b %d3,%d0
	move.b %d0,nvram+30
	and.l #255,%d0
	move.l %d0,-(%sp)
	pea 62.w
	jbsr (%a2)
	pea 128.w
	pea 7.w
	jbsr (%a2)
	move.b #2,nvram_valid
	pea .LC42
	jbsr cprintf
	lea (20,%sp),%sp
.L344:
	movm.l -12(%fp),#0x40c
	unlk %fp
	rts
	.size	setup, .-setup
	.globl	table7
	.section	.rodata
	.type	table7, @object
	.size	table7, 256
table7:
	.byte	0
	.byte	18
	.byte	36
	.byte	54
	.byte	72
	.byte	90
	.byte	108
	.byte	126
	.byte	-112
	.byte	-126
	.byte	-76
	.byte	-90
	.byte	-40
	.byte	-54
	.byte	-4
	.byte	-18
	.byte	50
	.byte	32
	.byte	22
	.byte	4
	.byte	122
	.byte	104
	.byte	94
	.byte	76
	.byte	-94
	.byte	-80
	.byte	-122
	.byte	-108
	.byte	-22
	.byte	-8
	.byte	-50
	.byte	-36
	.byte	100
	.byte	118
	.byte	64
	.byte	82
	.byte	44
	.byte	62
	.byte	8
	.byte	26
	.byte	-12
	.byte	-26
	.byte	-48
	.byte	-62
	.byte	-68
	.byte	-82
	.byte	-104
	.byte	-118
	.byte	86
	.byte	68
	.byte	114
	.byte	96
	.byte	30
	.byte	12
	.byte	58
	.byte	40
	.byte	-58
	.byte	-44
	.byte	-30
	.byte	-16
	.byte	-114
	.byte	-100
	.byte	-86
	.byte	-72
	.byte	-56
	.byte	-38
	.byte	-20
	.byte	-2
	.byte	-128
	.byte	-110
	.byte	-92
	.byte	-74
	.byte	88
	.byte	74
	.byte	124
	.byte	110
	.byte	16
	.byte	2
	.byte	52
	.byte	38
	.byte	-6
	.byte	-24
	.byte	-34
	.byte	-52
	.byte	-78
	.byte	-96
	.byte	-106
	.byte	-124
	.byte	106
	.byte	120
	.byte	78
	.byte	92
	.byte	34
	.byte	48
	.byte	6
	.byte	20
	.byte	-84
	.byte	-66
	.byte	-120
	.byte	-102
	.byte	-28
	.byte	-10
	.byte	-64
	.byte	-46
	.byte	60
	.byte	46
	.byte	24
	.byte	10
	.byte	116
	.byte	102
	.byte	80
	.byte	66
	.byte	-98
	.byte	-116
	.byte	-70
	.byte	-88
	.byte	-42
	.byte	-60
	.byte	-14
	.byte	-32
	.byte	14
	.byte	28
	.byte	42
	.byte	56
	.byte	70
	.byte	84
	.byte	98
	.byte	112
	.byte	-126
	.byte	-112
	.byte	-90
	.byte	-76
	.byte	-54
	.byte	-40
	.byte	-18
	.byte	-4
	.byte	18
	.byte	0
	.byte	54
	.byte	36
	.byte	90
	.byte	72
	.byte	126
	.byte	108
	.byte	-80
	.byte	-94
	.byte	-108
	.byte	-122
	.byte	-8
	.byte	-22
	.byte	-36
	.byte	-50
	.byte	32
	.byte	50
	.byte	4
	.byte	22
	.byte	104
	.byte	122
	.byte	76
	.byte	94
	.byte	-26
	.byte	-12
	.byte	-62
	.byte	-48
	.byte	-82
	.byte	-68
	.byte	-118
	.byte	-104
	.byte	118
	.byte	100
	.byte	82
	.byte	64
	.byte	62
	.byte	44
	.byte	26
	.byte	8
	.byte	-44
	.byte	-58
	.byte	-16
	.byte	-30
	.byte	-100
	.byte	-114
	.byte	-72
	.byte	-86
	.byte	68
	.byte	86
	.byte	96
	.byte	114
	.byte	12
	.byte	30
	.byte	40
	.byte	58
	.byte	74
	.byte	88
	.byte	110
	.byte	124
	.byte	2
	.byte	16
	.byte	38
	.byte	52
	.byte	-38
	.byte	-56
	.byte	-2
	.byte	-20
	.byte	-110
	.byte	-128
	.byte	-74
	.byte	-92
	.byte	120
	.byte	106
	.byte	92
	.byte	78
	.byte	48
	.byte	34
	.byte	20
	.byte	6
	.byte	-24
	.byte	-6
	.byte	-52
	.byte	-34
	.byte	-96
	.byte	-78
	.byte	-124
	.byte	-106
	.byte	46
	.byte	60
	.byte	10
	.byte	24
	.byte	102
	.byte	116
	.byte	66
	.byte	80
	.byte	-66
	.byte	-84
	.byte	-102
	.byte	-120
	.byte	-10
	.byte	-28
	.byte	-46
	.byte	-64
	.byte	28
	.byte	14
	.byte	56
	.byte	42
	.byte	84
	.byte	70
	.byte	112
	.byte	98
	.byte	-116
	.byte	-98
	.byte	-88
	.byte	-70
	.byte	-60
	.byte	-42
	.byte	-32
	.byte	-14
	.globl	nvram0
	.type	nvram0, @object
	.size	nvram0, 31
nvram0:
	.byte	12
	.byte	0
	.byte	32
	.byte	35
	.byte	1
	.byte	68
	.byte	1
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.globl	uart
	.section	.rodata.str1.1
.LC43:
	.string	"Unknown"
.LC44:
	.string	"8250"
.LC45:
	.string	"16450"
.LC46:
	.string	"16550"
.LC47:
	.string	"16550A"
.LC48:
	.string	"16550C"
.LC49:
	.string	"16750"
	.section	.rodata
	.align	4
	.type	uart, @object
	.size	uart, 28
uart:
	.long	.LC43
	.long	.LC44
	.long	.LC45
	.long	.LC46
	.long	.LC47
	.long	.LC48
	.long	.LC49
	.globl	floppy_ops
	.align	2
	.type	floppy_ops, @object
	.size	floppy_ops, 24
floppy_ops:
	.long	floppy_reset
	.long	floppy_info
	.long	floppy_read
	.long	floppy_write
	.long	floppy_verify
	.long	floppy_format
	.globl	ppide_ops
	.align	2
	.type	ppide_ops, @object
	.size	ppide_ops, 24
ppide_ops:
	.long	ppide_reset
	.long	ppide_info
	.long	ppide_read
	.long	ppide_write
	.long	0
	.long	0
	.globl	dide_ops
	.align	2
	.type	dide_ops, @object
	.size	dide_ops, 24
dide_ops:
	.long	dide_reset
	.long	dide_info
	.long	dide_read
	.long	dide_write
	.long	dide_verify
	.long	0
	.globl	dualsd_ops
	.align	2
	.type	dualsd_ops, @object
	.size	dualsd_ops, 24
dualsd_ops:
	.long	dsd_reset
	.long	dsd_info
	.long	dsd_read
	.long	dsd_write
	.long	dsd_verify
	.long	0
	.globl	dow
	.section	.rodata.str1.1
.LC50:
	.string	"Sun"
.LC51:
	.string	"Mon"
.LC52:
	.string	"Tue"
.LC53:
	.string	"Wed"
.LC54:
	.string	"Thu"
.LC55:
	.string	"Fri"
.LC56:
	.string	"Sat"
.LC57:
	.string	"???"
	.section	.rodata
	.align	4
	.type	dow, @object
	.size	dow, 32
dow:
	.long	.LC50
	.long	.LC51
	.long	.LC52
	.long	.LC53
	.long	.LC54
	.long	.LC55
	.long	.LC56
	.long	.LC57
	.align	4
	.type	rates.2366, @object
	.size	rates.2366, 60
rates.2366:
	.long	300
	.long	600
	.long	1200
	.long	1800
	.long	2400
	.long	3600
	.long	4800
	.long	7200
	.long	9600
	.long	14400
	.long	19200
	.long	28800
	.long	38400
	.long	57600
	.long	115200
	.type	dpm0, @object
	.size	dpm0, 12
dpm0:
	.byte	31
	.byte	30
	.byte	31
	.byte	30
	.byte	31
	.byte	31
	.byte	30
	.byte	31
	.byte	30
	.byte	31
	.byte	31
	.byte	28
	.align	4
	.type	mods, @object
	.size	mods, 20
mods:
	.long	1
	.long	4
	.long	32
	.long	32
	.long	2
	.comm	disk_table,32,4
	.comm	fdc_base_port,2,2
	.comm	drive_status_change,4,1
	.comm	drive_ready,4,1
	.comm	nvram,31,1
	.comm	nvram_valid,1,1
	.comm	uart_type,1,1
	.comm	errno,4,4
	.comm	timer_ticks,4,4
	.comm	julian_day,4,4
	.ident	"GCC: (GNU) 4.1.1"
