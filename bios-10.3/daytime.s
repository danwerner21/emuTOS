#NO_APP
	.file	"daytime.c"
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"\nDate & Time format%d: \t%8x  %8x  ::  %10d  %10d\n"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	link.w %fp,#-60
	move.l %d2,-(%sp)
	moveq #0,%d2
.L2:
	clr.w -60(%fp)
	move.w #20,-58(%fp)
	move.l %d2,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-56(%fp)
	move.w %d2,-54(%fp)
	lea (-60,%fp),%a0
	move.l %a0,-(%sp)
	move.l %a0,-(%sp)
	jbsr bios_call
	move.w -56(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -54(%fp),%d0
	move.w -60(%fp),%a0
	move.w %a0,%d1
	swap %d1
	mov.w -58(%fp),%d1
	move.l %d0,-(%sp)
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	move.l %d1,-(%sp)
	move.l %d2,-(%sp)
	pea .LC0
	jbsr cprintf
	addq.l #1,%d2
	lea (32,%sp),%sp
	moveq #4,%d0
	cmp.l %d2,%d0
	jbne .L2
	clr.b %d0
	move.l -64(%fp),%d2
	unlk %fp
	rts
	.size	main, .-main
	.ident	"GCC: (GNU) 4.1.1"
