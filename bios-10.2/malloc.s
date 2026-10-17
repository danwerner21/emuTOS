#NO_APP
	.file	"malloc.c"
	.text
	.align	2
	.globl	malloc
	.type	malloc, @function
malloc:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.l 8(%fp),%d0
	addq.l #3,%d0
	moveq #-4,%d1
	and.l %d1,%d0
	move.l mem_chain,%d2
	move.l %d2,%d1
	add.l %d0,%d1
	move.l %d1,mem_chain
	move.l %d0,-(%sp)
	clr.l -(%sp)
	move.l %d2,-(%sp)
	jbsr memset
	move.l %d2,%d0
	move.l -4(%fp),%d2
	unlk %fp
	rts
	.size	malloc, .-malloc
	.comm	mem_chain,4,4
	.ident	"GCC: (GNU) 4.1.1"
