	.file	"daytime.c"
gcc2_compiled.:
__gnu_compiled_c:
.text
.LC0:
	.ascii "\12Date & Time format%d: \11%8x  %8x  ::  %10d  %10d\12\0"
	.even
.globl main
main:
	link.w %a6,#-60
	movm.l #0x3030,-(%sp)
	jsr __main
	moveq.l #0,%d2
	lea bios_call,%a3
	lea cprintf,%a2
	moveq.l #-60,%d3
	add.l %a6,%d3
	.even
.L5:
	moveq.l #20,%d1
	move.l %d1,-60(%a6)
	move.l %d2,-56(%a6)
	move.l %d3,-(%sp)
	move.l %d3,-(%sp)
	jsr (%a3)
	move.l -56(%a6),-(%sp)
	move.l -60(%a6),-(%sp)
	move.l -56(%a6),-(%sp)
	move.l -60(%a6),-(%sp)
	move.l %d2,-(%sp)
	pea .LC0
	jsr (%a2)
	lea (32,%sp),%sp
	addq.l #1,%d2
	moveq.l #3,%d1
	cmp.l %d2,%d1
	jbge .L5
	moveq.l #0,%d0
	movm.l -76(%a6),#0xc0c
	unlk %a6
	rts
