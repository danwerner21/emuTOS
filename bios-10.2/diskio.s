#NO_APP
	.file	"diskio.c"
	.text
	.align	2
	.globl	disk_status
	.type	disk_status, @function
disk_status:
	link.w %fp,#0
	move.b 11(%fp),%d0
	cmp.b #3,%d0
	jbls .L2
	moveq #1,%d0
	jbra .L4
.L2:
	and.l #255,%d0
	lea drive_status,%a0
	move.b (%a0,%d0.l),%d0
	and.l #255,%d0
.L4:
	unlk %fp
	rts
	.size	disk_status, .-disk_status
	.align	2
	.globl	disk_ioctl
	.type	disk_ioctl, @function
disk_ioctl:
	link.w %fp,#-60
	movm.l #0x3020,-(%sp)
	move.l 16(%fp),%a2
	move.b 11(%fp),%d0
	move.b 15(%fp),%d1
	cmp.b #3,%d0
	jbhi .L7
	moveq #0,%d2
	move.b %d0,%d2
	lea drive_status,%a0
	move.b (%a0,%d2.l),%d0
	moveq #3,%d3
	and.l %d3,%d0
	jbeq .L9
	moveq #3,%d0
	jbra .L11
.L9:
	cmp.b #1,%d1
	jbeq .L13
	jbcs .L18
	cmp.b #2,%d1
	jbeq .L14
	cmp.b #4,%d1
	jbne .L7
	jbra .L18
.L14:
	move.l #512,(%a2)
.L18:
	moveq #0,%d0
	jbra .L11
.L13:
	clr.w -60(%fp)
	move.w #11,-58(%fp)
	clr.w -56(%fp)
	addq.w #2,%d2
	move.w %d2,-54(%fp)
	clr.w -28(%fp)
	clr.w -26(%fp)
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
	jbne .L15
	move.w -56(%fp),%d3
	move.w %d3,%d0
	swap %d0
	mov.w -54(%fp),%d0
	move.l %d0,(%a2)
	moveq #-1,%d1
	cmp.l %d0,%d1
	seq %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
	jbra .L11
.L7:
	moveq #4,%d0
	jbra .L11
.L15:
	moveq #-1,%d3
	move.l %d3,(%a2)
	moveq #1,%d0
.L11:
	movm.l -72(%fp),#0x40c
	unlk %fp
	rts
	.size	disk_ioctl, .-disk_ioctl
	.align	2
	.globl	disk_read
	.type	disk_read, @function
disk_read:
	link.w %fp,#-60
	movm.l #0x3c00,-(%sp)
	move.l 12(%fp),%d3
	move.l 16(%fp),%d2
	move.l 20(%fp),%d4
	move.b 11(%fp),%d0
	cmp.b #3,%d0
	jbls .L20
	moveq #4,%d0
	jbra .L22
.L20:
	moveq #0,%d5
	move.b %d0,%d5
	lea drive_status,%a0
	move.b (%a0,%d5.l),%d0
	moveq #3,%d1
	and.l %d1,%d0
	jbeq .L31
	moveq #3,%d0
	jbra .L22
.L30:
	moveq #1,%d0
	jbra .L22
.L25:
	clr.w -60(%fp)
	move.w #12,-58(%fp)
	clr.w -56(%fp)
	move.w %d5,%d0
	addq.w #2,%d0
	move.w %d0,-54(%fp)
	move.l %d2,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-52(%fp)
	move.w %d2,-50(%fp)
	clr.w -48(%fp)
	move.w #1,-46(%fp)
	move.l %d3,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-28(%fp)
	move.w %d3,-26(%fp)
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
	jbne .L30
	addq.l #1,%d2
	subq.l #1,%d4
	add.l #512,%d3
.L31:
	tst.l %d4
	jbne .L25
	moveq #0,%d0
.L22:
	movm.l -76(%fp),#0x3c
	unlk %fp
	rts
	.size	disk_read, .-disk_read
	.align	2
	.globl	disk_initialize
	.type	disk_initialize, @function
disk_initialize:
	link.w %fp,#-60
	move.l %d2,-(%sp)
	move.b 11(%fp),%d2
	cmp.b #3,%d2
	jbls .L33
	moveq #1,%d0
	jbra .L35
.L33:
	clr.w -60(%fp)
	move.w #10,-58(%fp)
	and.l #255,%d2
	clr.w -56(%fp)
	move.w %d2,%d0
	addq.w #2,%d0
	move.w %d0,-54(%fp)
	lea (-60,%fp),%a0
	move.l %a0,-(%sp)
	move.l %a0,-(%sp)
	jbsr bios_call
	move.w -60(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -58(%fp),%d0
	addq.l #8,%sp
	lea drive_status,%a0
	tst.l %d0
	seq %d0
	addq.b #1,%d0
	move.b %d0,(%a0,%d2.l)
	and.l #255,%d0
.L35:
	move.l -64(%fp),%d2
	unlk %fp
	rts
	.size	disk_initialize, .-disk_initialize
	.align	2
	.globl	disk_write
	.type	disk_write, @function
disk_write:
	link.w %fp,#-60
	movm.l #0x3c00,-(%sp)
	move.l 12(%fp),%d3
	move.l 16(%fp),%d2
	move.l 20(%fp),%d4
	move.b 11(%fp),%d0
	cmp.b #3,%d0
	jbls .L41
	moveq #4,%d0
	jbra .L43
.L41:
	moveq #0,%d5
	move.b %d0,%d5
	lea drive_status,%a0
	move.b (%a0,%d5.l),%d0
	moveq #3,%d1
	and.l %d1,%d0
	jbeq .L52
	moveq #3,%d0
	jbra .L43
.L51:
	moveq #1,%d0
	jbra .L43
.L46:
	clr.w -60(%fp)
	move.w #13,-58(%fp)
	clr.w -56(%fp)
	move.w %d5,%d0
	addq.w #2,%d0
	move.w %d0,-54(%fp)
	move.l %d2,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-52(%fp)
	move.w %d2,-50(%fp)
	clr.w -48(%fp)
	move.w #1,-46(%fp)
	move.l %d3,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-28(%fp)
	move.w %d3,-26(%fp)
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
	jbne .L51
	addq.l #1,%d2
	subq.l #1,%d4
	add.l #512,%d3
.L52:
	tst.l %d4
	jbne .L46
	moveq #0,%d0
.L43:
	movm.l -76(%fp),#0x3c
	unlk %fp
	rts
	.size	disk_write, .-disk_write
	.comm	drive_status,4,1
	.ident	"GCC: (GNU) 4.1.1"
