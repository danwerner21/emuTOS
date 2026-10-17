#NO_APP
	.file	"wd37c65.c"
	.text
	.align	2
	.globl	wd_set_ldor
	.type	wd_set_ldor, @function
wd_set_ldor:
	link.w %fp,#0
	move.l %d2,-(%sp)
	lea wd_reg,%a0
	move.b (%a0),%d0
	move.b %d0,%d2
	or.b 11(%fp),%d2
	move.b %d2,(%a0)
	moveq #0,%d1
	move.w fdc_base_port,%d1
	move.l %d1,%a0
	move.b %d2,-32766(%a0)
	and.l #255,%d0
	move.l (%sp)+,%d2
	unlk %fp
	rts
	.size	wd_set_ldor, .-wd_set_ldor
	.align	2
	.globl	wd_clear_ldor
	.type	wd_clear_ldor, @function
wd_clear_ldor:
	link.w %fp,#0
	move.l %d2,-(%sp)
	lea wd_reg,%a0
	move.b (%a0),%d0
	move.b 11(%fp),%d1
	not.b %d1
	move.b %d0,%d2
	and.b %d1,%d2
	move.b %d2,(%a0)
	moveq #0,%d1
	move.w fdc_base_port,%d1
	move.l %d1,%a0
	move.b %d2,-32766(%a0)
	and.l #255,%d0
	move.l (%sp)+,%d2
	unlk %fp
	rts
	.size	wd_clear_ldor, .-wd_clear_ldor
	.align	2
	.globl	wd_set_ldcr
	.type	wd_set_ldcr, @function
wd_set_ldcr:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.l 8(%fp),%d2
	lea wd_reg+1,%a0
	move.b (%a0),%d0
	moveq #0,%d1
	move.w fdc_base_port,%d1
	move.b %d2,(%a0)
	move.l %d1,%a0
	move.b %d2,-32765(%a0)
	and.l #255,%d0
	move.l (%sp)+,%d2
	unlk %fp
	rts
	.size	wd_set_ldcr, .-wd_set_ldcr
	.align	2
	.globl	set_PCAT_mode
	.type	set_PCAT_mode, @function
set_PCAT_mode:
	link.w %fp,#0
	pea 255.w
	jbsr wd_clear_ldor
	moveq #0,%d0
	move.w fdc_base_port,%d0
	move.l %d0,%a0
	move.b -32765(%a0),wd_reg+1
	pea 12.w
	jbsr wd_set_ldor
	addq.l #8,%sp
	unlk %fp
	rts
	.size	set_PCAT_mode, .-set_PCAT_mode
	.align	2
	.globl	floppy_timeout
	.type	floppy_timeout, @function
floppy_timeout:
	link.w %fp,#0
	pea 51.w
	jbsr wd_clear_ldor
	addq.l #4,%sp
	unlk %fp
	rts
	.size	floppy_timeout, .-floppy_timeout
	.align	2
	.globl	wait_for
	.type	wait_for, @function
wait_for:
	link.w %fp,#0
	movm.l #0x3800,-(%sp)
	move.b 11(%fp),%d2
	move.b timeout,%d3
	cmp.b %d3,%d2
	jbls .L12
	st timeout
.L12:
	move.b timeout,%d4
	sub.b %d2,%d4
.L14:
	jbsr usec16
	move.b timeout,%d0
	jbeq .L15
	cmp.b %d0,%d4
	jbcs .L14
.L15:
	cmp.b %d3,%d2
	jbls .L19
	move.b %d3,timeout
.L19:
	movm.l -12(%fp),#0x1c
	unlk %fp
	rts
	.size	wait_for, .-wait_for
	.align	2
	.globl	wd_select
	.type	wd_select, @function
wd_select:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%a2
	tst.b 10(%a2)
	jbne .L22
	moveq #16,%d2
	jbra .L24
.L22:
	moveq #33,%d2
.L24:
	moveq #49,%d0
	and.l %d2,%d0
	move.l %d0,-(%sp)
	jbsr wd_set_ldor
	move.l 16(%a2),%a0
	move.b 2(%a0),timeout
	and.b %d0,%d2
	addq.l #4,%sp
	jbne .L27
	move.l 16(%a2),%a0
	moveq #0,%d0
	move.b 9(%a0),%d0
	move.l %d0,-(%sp)
	jbsr wait_for
	move.l 16(%a2),%a0
	move.b 2(%a0),timeout
	addq.l #4,%sp
.L27:
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	wd_select, .-wd_select
	.comm	fdc_base_port,2,2
	.comm	drive_status_change,4,1
	.comm	drive_ready,4,1
	.comm	disk_table,32,4
	.comm	timeout,1,1
	.comm	wd_reg,2,1
	.ident	"GCC: (GNU) 4.1.1"
