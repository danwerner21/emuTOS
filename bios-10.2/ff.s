#NO_APP
	.file	"ff.c"
	.globl	__mulsi3
	.text
	.align	2
	.globl	clust2sect
	.type	clust2sect, @function
clust2sect:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d1
	subq.l #2,%d1
	move.l 16(%a2),%d0
	subq.l #2,%d0
	cmp.l %d1,%d0
	jbhi .L2
	moveq #0,%d0
	jbra .L4
.L2:
	moveq #0,%d0
	move.b 2(%a2),%d0
	move.l %d0,-(%sp)
	move.l %d1,-(%sp)
	jbsr __mulsi3
	addq.l #8,%sp
	add.l 36(%a2),%d0
.L4:
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	clust2sect, .-clust2sect
	.align	2
	.type	ld_clust, @function
ld_clust:
	link.w %fp,#0
	move.l %d2,-(%sp)
	move.l 12(%fp),%a1
	move.b 27(%a1),%d0
	lsl.w #8,%d0
	clr.w %d1
	move.b 26(%a1),%d1
	or.w %d1,%d0
	moveq #0,%d2
	move.w %d0,%d2
	move.l 8(%fp),%a0
	cmp.b #3,(%a0)
	jbne .L7
	move.b 21(%a1),%d0
	lsl.w #8,%d0
	clr.w %d1
	move.b 20(%a1),%d1
	or.w %d1,%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d2
.L7:
	move.l %d2,%d0
	move.l (%sp)+,%d2
	unlk %fp
	rts
	.size	ld_clust, .-ld_clust
	.align	2
	.type	get_fileinfo, @function
get_fileinfo:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%a0
	move.l 12(%fp),%a2
	lea (9,%a2),%a1
	tst.l 16(%a0)
	jbeq .L11
	move.l 20(%a0),%a0
	moveq #0,%d1
.L13:
	move.b (%a0,%d1.l),%d0
	addq.l #1,%d1
	cmp.b #32,%d0
	jbeq .L14
	cmp.b #5,%d0
	jbne .L18
	moveq #-27,%d0
.L18:
	moveq #9,%d2
	cmp.l %d1,%d2
	jbne .L19
	move.b #46,(%a1)+
.L19:
	move.b %d0,(%a1)+
.L14:
	moveq #11,%d0
	cmp.l %d1,%d0
	jbne .L13
	move.b 11(%a0),8(%a2)
	moveq #0,%d2
	move.b 29(%a0),%d2
	lsl.l #8,%d2
	move.b 31(%a0),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 30(%a0),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	or.b 28(%a0),%d1
	or.l %d1,%d2
	move.l %d2,(%a2)
	move.b 25(%a0),%d1
	lsl.w #8,%d1
	clr.w %d0
	move.b 24(%a0),%d0
	or.w %d0,%d1
	move.w %d1,4(%a2)
	move.b 23(%a0),%d1
	lsl.w #8,%d1
	clr.w %d0
	move.b 22(%a0),%d0
	or.w %d0,%d1
	move.w %d1,6(%a2)
.L11:
	clr.b (%a1)
	move.l (%sp)+,%d2
	move.l (%sp)+,%a2
	unlk %fp
	rts
	.size	get_fileinfo, .-get_fileinfo
	.align	2
	.type	get_ldnumber, @function
get_ldnumber:
	link.w %fp,#0
	movm.l #0x303c,-(%sp)
	move.l 8(%fp),%a5
	move.l (%a5),%a2
	cmp.w #0,%a2
	jbeq .L26
	move.l %a2,%d1
	jbra .L28
.L29:
	addq.l #1,%d1
.L28:
	move.l %d1,%a0
	move.b (%a0),%d0
	cmp.b #32,%d0
	jbls .L30
	cmp.b #58,%d0
	jbne .L29
	jbra .L32
.L30:
	cmp.b #58,%d0
	jbne .L33
.L32:
	move.b (%a2),%d0
	ext.w %d0
	move.w %d0,%a0
	lea (-48,%a0),%a1
	moveq #9,%d0
	cmp.l %a1,%d0
	jbcs .L34
	lea (1,%a2),%a0
	cmp.l %a0,%d1
	jbne .L34
	move.b #3,%d0
	cmp.l %a1,%d0
	jbcs .L26
	move.l %a1,%d0
	addq.l #1,%d1
	move.l %d1,(%a5)
	jbra .L38
.L34:
	move.l %d1,%d3
	addq.l #1,%d3
	sub.l %a0,%a0
	lea str.1518,%a4
.L39:
	move.l (%a4),%a3
	move.l %a2,%a1
.L40:
	move.b (%a3)+,%d2
	move.b (%a1)+,%d1
	move.b %d1,%d0
	add.b #-97,%d0
	cmp.b #25,%d0
	jbhi .L41
	add.b #-32,%d1
.L41:
	tst.b %d2
	jbeq .L43
	cmp.b %d2,%d1
	jbne .L45
	jbra .L40
.L43:
	cmp.l %a1,%d3
	jbeq .L46
.L45:
	addq.l #1,%a0
	addq.l #4,%a4
	moveq #4,%d0
	cmp.l %a0,%d0
	jbeq .L26
	jbra .L39
.L46:
	moveq #3,%d0
	cmp.l %a0,%d0
	jbcs .L26
	move.l %a0,%d0
	move.l %d3,(%a5)
	jbra .L38
.L33:
	moveq #0,%d0
	move.b CurrVol,%d0
	jbra .L38
.L26:
	moveq #-1,%d0
.L38:
	movm.l (%sp)+,#0x3c0c
	unlk %fp
	rts
	.size	get_ldnumber, .-get_ldnumber
	.align	2
	.globl	f_chdrive
	.type	f_chdrive, @function
f_chdrive:
	link.w %fp,#0
	pea 8(%fp)
	jbsr get_ldnumber
	addq.l #4,%sp
	tst.l %d0
	jbge .L52
	moveq #11,%d0
	jbra .L54
.L52:
	move.b %d0,CurrVol
	moveq #0,%d0
.L54:
	unlk %fp
	rts
	.size	f_chdrive, .-f_chdrive
	.align	2
	.type	validate, @function
validate:
	link.w %fp,#0
	move.l 8(%fp),%a1
	cmp.w #0,%a1
	jbeq .L57
	move.l (%a1),%a0
	cmp.w #0,%a0
	jbeq .L57
	tst.b (%a0)
	jbeq .L57
	move.w 4(%a1),%d0
	cmp.w 6(%a0),%d0
	jbne .L57
	moveq #0,%d0
	move.b 1(%a0),%d0
	move.l %d0,-(%sp)
	jbsr disk_status
	addq.l #4,%sp
	btst #0,%d0
	jbne .L57
	moveq #0,%d0
	jbra .L63
.L57:
	moveq #9,%d0
.L63:
	unlk %fp
	rts
	.size	validate, .-validate
	.align	2
	.globl	f_closedir
	.type	f_closedir, @function
f_closedir:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l 8(%fp),%a2
	move.l %a2,-(%sp)
	jbsr validate
	addq.l #4,%sp
	tst.l %d0
	jbne .L66
	clr.l (%a2)
.L66:
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	f_closedir, .-f_closedir
	.align	2
	.globl	f_close
	.type	f_close, @function
f_close:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l 8(%fp),%a2
	move.l %a2,-(%sp)
	jbsr validate
	addq.l #4,%sp
	tst.l %d0
	jbne .L70
	clr.l (%a2)
.L70:
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	f_close, .-f_close
	.align	2
	.type	move_window, @function
move_window:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d2
	cmp.l 40(%a2),%d2
	jbne .L74
	moveq #0,%d0
	jbra .L76
.L74:
	pea 1.w
	move.l %d2,-(%sp)
	pea 44(%a2)
	moveq #0,%d0
	move.b 1(%a2),%d0
	move.l %d0,-(%sp)
	jbsr disk_read
	lea (16,%sp),%sp
	tst.l %d0
	jbeq .L77
	moveq #-1,%d2
	moveq #1,%d0
	jbra .L79
.L77:
	moveq #0,%d0
.L79:
	move.l %d2,40(%a2)
.L76:
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	move_window, .-move_window
	.align	2
	.type	check_fs, @function
check_fs:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%a2
	clr.b 4(%a2)
	moveq #-1,%d0
	move.l %d0,40(%a2)
	move.l 12(%fp),-(%sp)
	move.l %a2,-(%sp)
	jbsr move_window
	addq.l #8,%sp
	tst.l %d0
	jbeq .L82
	moveq #3,%d0
	jbra .L84
.L82:
	lea (44,%a2),%a0
	move.b 511(%a0),%d0
	lsl.w #8,%d0
	clr.w %d1
	move.b 510(%a0),%d1
	or.w %d1,%d0
	cmp.w #-21931,%d0
	jbeq .L85
	moveq #2,%d0
	jbra .L84
.L85:
	moveq #0,%d0
	move.b 55(%a0),%d0
	lsl.l #8,%d0
	move.b 57(%a0),%d2
	lsl.w #8,%d2
	swap %d2
	clr.w %d2
	moveq #0,%d1
	move.b 56(%a0),%d1
	swap %d1
	clr.w %d1
	or.l %d1,%d2
	or.b 54(%a0),%d2
	or.l %d2,%d0
	and.l #16777215,%d0
	cmp.l #5521734,%d0
	jbne .L87
	moveq #0,%d0
	jbra .L84
.L87:
	moveq #0,%d1
	move.b 83(%a0),%d1
	lsl.l #8,%d1
	move.b 85(%a0),%d2
	lsl.w #8,%d2
	swap %d2
	clr.w %d2
	moveq #0,%d0
	move.b 84(%a0),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d2
	or.b 82(%a0),%d2
	or.l %d2,%d1
	and.l #16777215,%d1
	cmp.l #5521734,%d1
	seq %d0
	neg.b %d0
	eor.b #1,%d0
	and.l #255,%d0
.L84:
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	check_fs, .-check_fs
	.globl	__udivsi3
	.align	2
	.type	find_volume, @function
find_volume:
	link.w %fp,#-16
	movm.l #0x3f30,-(%sp)
	move.l 8(%fp),%a2
	clr.l (%a2)
	move.l 12(%fp),-(%sp)
	jbsr get_ldnumber
	move.l %d0,%d2
	addq.l #4,%sp
	jbge .L91
	moveq #11,%d0
	jbra .L93
.L91:
	add.l %d2,%d0
	add.l %d0,%d0
	lea FatFs,%a0
	move.l (%a0,%d0.l),%a3
	cmp.w #0,%a3
	jbne .L94
	moveq #12,%d0
	jbra .L93
.L94:
	move.l %a3,(%a2)
	tst.b (%a3)
	jbeq .L96
	moveq #0,%d0
	move.b 1(%a3),%d0
	move.l %d0,-(%sp)
	jbsr disk_status
	addq.l #4,%sp
	btst #0,%d0
	jbeq .L149
.L96:
	clr.b (%a3)
	move.b %d2,1(%a3)
	moveq #0,%d0
	move.b %d2,%d0
	move.l %d0,-(%sp)
	jbsr disk_initialize
	addq.l #4,%sp
	btst #0,%d0
	jbeq .L99
	moveq #3,%d0
	jbra .L93
.L99:
	clr.l -(%sp)
	move.l %a3,-(%sp)
	jbsr check_fs
	addq.l #8,%sp
	cmp.b #1,%d0
	jbeq .L101
	moveq #0,%d7
	jbra .L103
.L101:
	sub.l %a1,%a1
	lea (-16,%fp),%a2
.L104:
	lea 44(%a1,%a3.l),%a0
	lea (446,%a0),%a0
	tst.b 4(%a0)
	jbne .L105
	moveq #0,%d2
	jbra .L107
.L105:
	moveq #0,%d2
	move.b 9(%a0),%d2
	lsl.l #8,%d2
	move.b 11(%a0),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 10(%a0),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	or.b 8(%a0),%d1
	or.l %d1,%d2
.L107:
	move.l %d2,(%a2)+
	lea (16,%a1),%a1
	moveq #64,%d0
	cmp.l %a1,%d0
	jbne .L104
	lea (-16,%fp),%a2
.L109:
	move.l (%a2),%d7
	jbne .L110
	moveq #2,%d0
	jbra .L112
.L110:
	move.l %d7,-(%sp)
	move.l %a3,-(%sp)
	jbsr check_fs
	addq.l #8,%sp
	tst.b %d0
	jbeq .L113
.L112:
	addq.l #4,%a2
	cmp.l %a2,%fp
	jbne .L109
.L103:
	cmp.b #3,%d0
	jbne .L114
	moveq #1,%d0
	jbra .L93
.L114:
	tst.b %d0
	jbne .L116
.L113:
	lea (44,%a3),%a2
	move.b 12(%a2),%d0
	lsl.w #8,%d0
	clr.w %d1
	move.b 11(%a2),%d1
	or.w %d1,%d0
	cmp.w #512,%d0
	jbne .L116
	move.b 23(%a2),%d1
	lsl.w #8,%d1
	clr.w %d0
	move.b 22(%a2),%d0
	or.w %d0,%d1
	jbeq .L118
	moveq #0,%d5
	move.w %d1,%d5
	jbra .L120
.L118:
	moveq #0,%d5
	move.b 37(%a2),%d5
	lsl.l #8,%d5
	move.b 39(%a2),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 38(%a2),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	or.b 36(%a2),%d1
	or.l %d1,%d5
.L120:
	move.l %d5,20(%a3)
	move.b 60(%a3),%d6
	move.b %d6,3(%a3)
	move.b %d6,%d0
	subq.b #1,%d0
	cmp.b #1,%d0
	jbhi .L116
	move.b 57(%a3),%d0
	move.b %d0,2(%a3)
	jbeq .L116
	and.l #255,%d0
	move.l %d0,%d1
	subq.l #1,%d1
	and.l %d1,%d0
	jbne .L116
	move.b 18(%a2),%d4
	lsl.w #8,%d4
	clr.w %d0
	move.b 17(%a2),%d0
	or.w %d0,%d4
	move.w %d4,8(%a3)
	moveq #15,%d0
	and.l %d4,%d0
	jbne .L116
	move.b 20(%a2),%d1
	lsl.w #8,%d1
	clr.w %d0
	move.b 19(%a2),%d0
	or.w %d0,%d1
	jbeq .L125
	moveq #0,%d3
	move.w %d1,%d3
	jbra .L127
.L125:
	moveq #0,%d3
	move.b 33(%a2),%d3
	lsl.l #8,%d3
	move.b 35(%a2),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 34(%a2),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	or.b 32(%a2),%d1
	or.l %d1,%d3
.L127:
	move.b 15(%a2),%d2
	lsl.w #8,%d2
	clr.w %d0
	move.b 14(%a2),%d0
	or.w %d0,%d2
	jbeq .L116
	moveq #0,%d0
	move.b %d6,%d0
	move.l %d0,-(%sp)
	move.l %d5,-(%sp)
	jbsr __mulsi3
	addq.l #8,%sp
	move.l %d0,%d6
	moveq #0,%d5
	move.w %d2,%d5
	lsr.w #4,%d4
	moveq #0,%d0
	move.w %d4,%d0
	add.l %d5,%d0
	move.l %d6,%d2
	add.l %d0,%d2
	cmp.l %d3,%d2
	jbhi .L116
	moveq #0,%d0
	move.b 2(%a3),%d0
	move.l %d0,-(%sp)
	sub.l %d2,%d3
	move.l %d3,-(%sp)
	jbsr __udivsi3
	addq.l #8,%sp
	tst.l %d0
	jbeq .L116
	cmp.l #4085,%d0
	jbhi .L131
	moveq #1,%d3
	jbra .L133
.L131:
	cmp.l #65525,%d0
	jbhi .L134
	moveq #2,%d3
.L133:
	move.l %d0,%d1
	addq.l #2,%d1
	move.l %d1,16(%a3)
	move.l %d7,24(%a3)
	add.l %d7,%d5
	move.l %d5,28(%a3)
	add.l %d2,%d7
	move.l %d7,36(%a3)
	tst.w 8(%a3)
	jbne .L146
	jbra .L116
.L147:
	moveq #0,%d2
	move.b 45(%a2),%d2
	lsl.l #8,%d2
	move.b 47(%a2),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 46(%a2),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	or.b 44(%a2),%d1
	or.l %d1,%d2
	move.l %d2,32(%a3)
	move.l 16(%a3),%d0
	add.l %d0,%d0
	add.l %d0,%d0
	moveq #3,%d3
	jbra .L138
.L146:
	add.l 28(%a3),%d6
	move.l %d6,32(%a3)
	move.l %d0,%d1
	addq.l #2,%d1
	cmp.b #2,%d3
	jbne .L139
	move.l %d1,%d0
	jbra .L148
.L139:
	move.l %d1,%d0
	add.l %d1,%d0
	add.l %d1,%d0
	lsr.l #1,%d0
	moveq #1,%d2
	and.l %d2,%d1
.L148:
	add.l %d1,%d0
.L138:
	add.l #511,%d0
	moveq #9,%d1
	lsr.l %d1,%d0
	cmp.l 20(%a3),%d0
	jbhi .L116
	move.b %d3,(%a3)
	move.w Fsid,%d0
	addq.w #1,%d0
	move.w %d0,Fsid
	move.w %d0,6(%a3)
	clr.l 12(%a3)
.L149:
	moveq #0,%d0
	jbra .L93
.L116:
	moveq #13,%d0
	jbra .L93
.L134:
	addq.l #2,%d0
	move.l %d0,16(%a3)
	move.l %d7,24(%a3)
	add.l %d7,%d5
	move.l %d5,28(%a3)
	add.l %d2,%d7
	move.l %d7,36(%a3)
	tst.w 8(%a3)
	jbne .L116
	jbra .L147
.L93:
	movm.l -48(%fp),#0xcfc
	unlk %fp
	rts
	.size	find_volume, .-find_volume
	.align	2
	.globl	f_mount
	.type	f_mount, @function
f_mount:
	link.w %fp,#-4
	move.l %d2,-(%sp)
	move.b 19(%fp),%d2
	move.l %fp,%a0
	move.l 12(%fp),-(%a0)
	move.l %a0,-(%sp)
	jbsr get_ldnumber
	addq.l #4,%sp
	tst.l %d0
	jbge .L151
	moveq #11,%d0
	jbra .L153
.L151:
	lea FatFs,%a1
	add.l %d0,%d0
	move.l %d0,%d1
	add.l %d0,%d1
	move.l (%a1,%d1.l),%a0
	cmp.w #0,%a0
	jbeq .L154
	clr.b (%a0)
.L154:
	move.l 8(%fp),%a0
	cmp.w #0,%a0
	jbeq .L156
	clr.b (%a0)
	move.l 8(%fp),%d0
	move.l %d0,(%a1,%d1.l)
	jbeq .L162
	cmp.b #1,%d2
	jbne .L162
	clr.l -(%sp)
	pea 12(%fp)
	pea 8(%fp)
	jbsr find_volume
	lea (12,%sp),%sp
	jbra .L153
.L156:
	clr.l (%a1,%d1.l)
.L162:
	moveq #0,%d0
.L153:
	move.l -8(%fp),%d2
	unlk %fp
	rts
	.size	f_mount, .-f_mount
	.align	2
	.globl	get_fat
	.type	get_fat, @function
get_fat:
	link.w %fp,#0
	movm.l #0x3830,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d3
	moveq #1,%d0
	cmp.l %d3,%d0
	jbcc .L164
	cmp.l 16(%a2),%d3
	jbcc .L164
	move.b (%a2),%d0
	cmp.b #2,%d0
	jbeq .L168
	cmp.b #3,%d0
	jbeq .L169
	cmp.b #1,%d0
	jbne .L164
	move.l %d3,%d0
	lsr.l #1,%d0
	move.l %d3,%d2
	add.l %d0,%d2
	move.l %d2,%d0
	moveq #9,%d1
	lsr.l %d1,%d0
	add.l 28(%a2),%d0
	move.l %d0,-(%sp)
	move.l %a2,-(%sp)
	lea move_window,%a3
	jbsr (%a3)
	addq.l #8,%sp
	tst.l %d0
	jbne .L170
	move.l %d2,%d0
	and.l #511,%d0
	move.b 44(%a2,%d0.l),%d4
	addq.l #1,%d2
	move.l %d2,%d0
	moveq #9,%d1
	lsr.l %d1,%d0
	add.l 28(%a2),%d0
	move.l %d0,-(%sp)
	move.l %a2,-(%sp)
	jbsr (%a3)
	addq.l #8,%sp
	tst.l %d0
	jbne .L170
	and.l #511,%d2
	moveq #0,%d0
	move.b 44(%a2,%d2.l),%d0
	lsl.l #8,%d0
	or.b %d4,%d0
	btst #0,%d3
	jbeq .L173
	move.l %d0,%d2
	lsr.l #4,%d2
	jbra .L175
.L173:
	move.l %d0,%d2
	and.l #4095,%d2
	jbra .L175
.L168:
	move.l %d3,%d0
	lsr.l #8,%d0
	add.l 28(%a2),%d0
	move.l %d0,-(%sp)
	move.l %a2,-(%sp)
	jbsr move_window
	addq.l #8,%sp
	tst.l %d0
	jbne .L170
	move.l %d3,%d0
	add.l %d3,%d0
	and.l #511,%d0
	lea 44(%a2,%d0.l),%a0
	move.b 1(%a0),%d0
	lsl.w #8,%d0
	clr.w %d1
	move.b (%a0),%d1
	or.w %d1,%d0
	moveq #0,%d2
	move.w %d0,%d2
	jbra .L175
.L169:
	move.l %d3,%d0
	lsr.l #7,%d0
	add.l 28(%a2),%d0
	move.l %d0,-(%sp)
	move.l %a2,-(%sp)
	jbsr move_window
	addq.l #8,%sp
	tst.l %d0
	jbne .L170
	move.l %d3,%d0
	add.l %d3,%d0
	add.l %d0,%d0
	and.l #511,%d0
	lea 44(%a2,%d0.l),%a0
	moveq #0,%d2
	move.b 1(%a0),%d2
	lsl.l #8,%d2
	move.b 3(%a0),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 2(%a0),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	or.b (%a0),%d1
	or.l %d1,%d2
	and.l #268435455,%d2
	jbra .L175
.L164:
	moveq #1,%d2
	jbra .L175
.L170:
	moveq #-1,%d2
.L175:
	move.l %d2,%d0
	movm.l -20(%fp),#0xc1c
	unlk %fp
	rts
	.size	get_fat, .-get_fat
	.align	2
	.globl	f_lseek
	.type	f_lseek, @function
f_lseek:
	link.w %fp,#0
	movm.l #0x3e30,-(%sp)
	move.l 8(%fp),%a3
	move.l 12(%fp),%d2
	move.l %a3,-(%sp)
	jbsr validate
	move.l %d0,%d5
	addq.l #4,%sp
	jbne .L180
	move.b 7(%a3),%d0
	jbeq .L182
	moveq #0,%d5
	move.b %d0,%d5
	jbra .L180
.L182:
	move.l 12(%a3),%d3
	cmp.l %d3,%d2
	jbcc .L184
	move.l %d2,%d3
.L184:
	move.l 8(%a3),%d0
	clr.l 8(%a3)
	tst.l %d3
	jbeq .L180
	move.l (%a3),%a0
	moveq #0,%d4
	move.b 2(%a0),%d4
	moveq #9,%d1
	lsl.l %d1,%d4
	tst.l %d0
	jbeq .L186
	move.l %d0,%d6
	subq.l #1,%d6
	lea __udivsi3,%a2
	move.l %d4,-(%sp)
	move.l %d3,%a0
	pea -1(%a0)
	jbsr (%a2)
	addq.l #8,%sp
	move.l %d0,%d2
	move.l %d4,-(%sp)
	move.l %d6,-(%sp)
	jbsr (%a2)
	addq.l #8,%sp
	cmp.l %d2,%d0
	jbhi .L186
	move.l %d4,%d0
	neg.l %d0
	and.l %d6,%d0
	move.l %d0,8(%a3)
	sub.l %d0,%d3
	move.l 20(%a3),%d1
	jbra .L189
.L186:
	move.l 16(%a3),%d1
	move.l %d1,20(%a3)
.L189:
	tst.l %d1
	jbne .L209
	jbra .L191
.L192:
	move.l %d1,-(%sp)
	move.l (%a3),-(%sp)
	jbsr get_fat
	move.l %d0,%d1
	addq.l #8,%sp
	moveq #-1,%d0
	cmp.l %d1,%d0
	jbeq .L208
	moveq #1,%d0
	cmp.l %d1,%d0
	jbcc .L210
	move.l (%a3),%a0
	cmp.l 16(%a0),%d1
	jbcc .L210
	move.l %d1,20(%a3)
	add.l %d4,8(%a3)
	sub.l %d4,%d3
.L209:
	cmp.l %d3,%d4
	jbcs .L192
	add.l %d3,8(%a3)
	move.l %d3,%d0
	and.l #511,%d0
	jbeq .L191
	move.l %d1,-(%sp)
	move.l (%a3),-(%sp)
	jbsr clust2sect
	addq.l #8,%sp
	tst.l %d0
	jbne .L200
.L210:
	move.b #2,7(%a3)
	moveq #2,%d5
	jbra .L180
.L200:
	moveq #9,%d1
	lsr.l %d1,%d3
	move.l %d0,%d2
	add.l %d3,%d2
	jbra .L202
.L191:
	moveq #0,%d2
.L202:
	move.l 8(%a3),%d0
	and.l #511,%d0
	jbeq .L180
	cmp.l 24(%a3),%d2
	jbeq .L180
	pea 1.w
	move.l %d2,-(%sp)
	pea 28(%a3)
	move.l (%a3),%a0
	moveq #0,%d0
	move.b 1(%a0),%d0
	move.l %d0,-(%sp)
	jbsr disk_read
	lea (16,%sp),%sp
	tst.l %d0
	jbeq .L205
.L208:
	move.b #1,7(%a3)
	moveq #1,%d5
	jbra .L180
.L205:
	move.l %d2,24(%a3)
.L180:
	move.l %d5,%d0
	movm.l -28(%fp),#0xc7c
	unlk %fp
	rts
	.size	f_lseek, .-f_lseek
	.align	2
	.globl	f_read
	.type	f_read, @function
f_read:
	link.w %fp,#0
	movm.l #0x3f38,-(%sp)
	move.l 8(%fp),%a2
	move.l 16(%fp),%d2
	move.l 20(%fp),%a4
	clr.l (%a4)
	move.l %a2,-(%sp)
	jbsr validate
	move.l %d0,%d6
	addq.l #4,%sp
	jbne .L212
	move.b 7(%a2),%d0
	jbeq .L214
	moveq #0,%d6
	move.b %d0,%d6
	jbra .L212
.L214:
	btst #0,6(%a2)
	jbne .L216
	moveq #7,%d6
	jbra .L212
.L250:
	move.b #2,7(%a2)
	moveq #2,%d6
	jbra .L212
.L252:
	move.b #1,7(%a2)
	moveq #1,%d6
	jbra .L212
.L216:
	move.l 12(%fp),%d7
	move.l 12(%a2),%d5
	sub.l 8(%a2),%d5
	cmp.l %d5,%d2
	jbcc .L253
	move.l %d2,%d5
	jbra .L253
.L220:
	move.l 8(%a2),%d1
	move.l %d1,%d0
	and.l #511,%d0
	jbne .L221
	move.l (%a2),%a0
	move.l %d1,%d0
	moveq #9,%d2
	lsr.l %d2,%d0
	move.b 2(%a0),%d2
	subq.b #1,%d2
	and.b %d0,%d2
	jbne .L223
	tst.l %d1
	jbne .L225
	move.l 16(%a2),%d0
	jbra .L227
.L225:
	move.l 20(%a2),-(%sp)
	move.l %a0,-(%sp)
	jbsr get_fat
	addq.l #8,%sp
.L227:
	moveq #1,%d1
	cmp.l %d0,%d1
	jbcc .L250
	moveq #-1,%d1
	cmp.l %d0,%d1
	jbeq .L252
	move.l %d0,20(%a2)
.L223:
	move.l (%a2),%a3
	move.l 20(%a2),-(%sp)
	move.l %a3,-(%sp)
	jbsr clust2sect
	addq.l #8,%sp
	tst.l %d0
	jbeq .L250
	moveq #0,%d1
	move.b %d2,%d1
	move.l %d0,%d4
	add.l %d1,%d4
	move.l %d5,%d3
	moveq #9,%d2
	lsr.l %d2,%d3
	tst.l %d3
	jbeq .L234
	move.l %d1,%d0
	add.l %d3,%d0
	moveq #0,%d2
	move.b 2(%a3),%d2
	cmp.l %d0,%d2
	jbcc .L236
	move.l %d2,%d3
	sub.l %d1,%d3
.L236:
	move.l %d3,-(%sp)
	move.l %d4,-(%sp)
	move.l %d7,-(%sp)
	moveq #0,%d0
	move.b 1(%a3),%d0
	move.l %d0,-(%sp)
	jbsr disk_read
	lea (16,%sp),%sp
	tst.l %d0
	jbne .L252
	move.l %d3,%d1
	move.b #9,%d0
	lsl.l %d0,%d1
	jbra .L240
.L234:
	cmp.l 24(%a2),%d4
	jbeq .L241
	pea 1.w
	move.l %d4,-(%sp)
	pea 28(%a2)
	moveq #0,%d0
	move.b 1(%a3),%d0
	move.l %d0,-(%sp)
	jbsr disk_read
	lea (16,%sp),%sp
	tst.l %d0
	jbne .L252
.L241:
	move.l %d4,24(%a2)
.L221:
	move.l 8(%a2),%d2
	and.l #511,%d2
	move.l #512,%d0
	sub.l %d2,%d0
	move.l %d5,%d1
	cmp.l %d5,%d0
	jbcc .L244
	move.l %d0,%d1
.L244:
	move.l %d7,%a1
	lea 28(%a2,%d2.l),%a0
	move.l %d1,%d0
	jbra .L245
.L246:
	move.b (%a0)+,(%a1)+
.L245:
	dbra %d0,.L246
	clr.w %d0
	subq.l #1,%d0
	jbcc .L246
.L240:
	add.l %d1,%d7
	add.l %d1,8(%a2)
	add.l %d1,(%a4)
	sub.l %d1,%d5
.L253:
	tst.l %d5
	jbne .L220
.L212:
	move.l %d6,%d0
	movm.l -36(%fp),#0x1cfc
	unlk %fp
	rts
	.size	f_read, .-f_read
	.align	2
	.type	dir_next, @function
dir_next:
	link.w %fp,#0
	movm.l #0x3020,-(%sp)
	move.l 8(%fp),%a2
	moveq #0,%d0
	move.w 6(%a2),%d0
	move.l %d0,%d2
	addq.l #1,%d2
	tst.w %d2
	jbeq .L255
	move.l 16(%a2),%d0
	jbeq .L255
	moveq #15,%d3
	and.l %d2,%d3
	jbne .L258
	addq.l #1,%d0
	move.l %d0,16(%a2)
	move.l 12(%a2),%a1
	move.l (%a2),%a0
	cmp.w #0,%a1
	jbne .L260
	moveq #0,%d0
	move.w 8(%a0),%d0
	cmp.l %d2,%d0
	jbhi .L258
	jbra .L255
.L260:
	move.l %d2,%d1
	lsr.l #4,%d1
	moveq #0,%d0
	move.b 2(%a0),%d0
	subq.l #1,%d0
	and.l %d0,%d1
	jbne .L258
	move.l %a1,-(%sp)
	move.l %a0,-(%sp)
	jbsr get_fat
	addq.l #8,%sp
	moveq #1,%d1
	cmp.l %d0,%d1
	jbcs .L263
	moveq #2,%d0
	jbra .L265
.L263:
	moveq #-1,%d1
	cmp.l %d0,%d1
	jbne .L266
	moveq #1,%d0
	jbra .L265
.L266:
	move.l (%a2),%a0
	cmp.l 16(%a0),%d0
	jbcc .L255
	move.l %d0,12(%a2)
	move.l %d0,-(%sp)
	move.l %a0,-(%sp)
	jbsr clust2sect
	addq.l #8,%sp
	move.l %d0,16(%a2)
.L258:
	move.w %d2,6(%a2)
	moveq #44,%d0
	add.l (%a2),%d0
	lsl.l #5,%d3
	add.l %d3,%d0
	move.l %d0,20(%a2)
	moveq #0,%d0
	jbra .L265
.L255:
	moveq #4,%d0
.L265:
	movm.l -12(%fp),#0x40c
	unlk %fp
	rts
	.size	dir_next, .-dir_next
	.align	2
	.type	dir_read, @function
dir_read:
	link.w %fp,#0
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d2
	move.w #4,%a1
	jbra .L271
.L272:
	move.l %d0,-(%sp)
	move.l (%a2),-(%sp)
	jbsr move_window
	move.l %d0,%a1
	addq.l #8,%sp
	tst.l %d0
	jbne .L273
	move.l 20(%a2),%a0
	move.b (%a0),%d1
	jbeq .L275
	move.b 11(%a0),%d0
	cmp.b #-27,%d1
	jbeq .L277
	and.b #63,%d0
	cmp.b #15,%d0
	jbeq .L277
	moveq #31,%d1
	and.l %d1,%d0
	move.b #8,%d1
	cmp.l %d0,%d1
	seq %d0
	ext.w %d0
	ext.l %d0
	neg.l %d0
	cmp.l %d0,%d2
	jbeq .L280
.L277:
	clr.l -(%sp)
	move.l %a2,-(%sp)
	jbsr dir_next
	move.l %d0,%a1
	addq.l #8,%sp
	tst.l %d0
	jbne .L273
.L271:
	move.l 16(%a2),%d0
	jbne .L272
	cmp.w #0,%a1
	jbeq .L280
.L273:
	clr.l 16(%a2)
	jbra .L280
.L275:
	move.w #4,%a1
	jbra .L273
.L280:
	move.l %a1,%d0
	move.l -8(%fp),%d2
	move.l -4(%fp),%a2
	unlk %fp
	rts
	.size	dir_read, .-dir_read
	.align	2
	.type	dir_sdi, @function
dir_sdi:
	link.w %fp,#0
	movm.l #0x3820,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d3
	move.w %d3,6(%a2)
	move.l 8(%a2),%d2
	moveq #1,%d0
	cmp.l %d2,%d0
	jbeq .L284
	move.l (%a2),%a0
	cmp.l 16(%a0),%d2
	jbcc .L284
	tst.l %d2
	jbne .L287
	cmp.b #3,(%a0)
	jbne .L289
	move.l 32(%a0),%d0
	jbne .L291
.L289:
	moveq #0,%d0
	move.w 8(%a0),%d0
	cmp.l %d3,%d0
	jbls .L284
	move.l 32(%a0),%d1
	jbra .L293
.L287:
	move.l %d2,%d0
.L291:
	moveq #0,%d4
	move.b 2(%a0),%d4
	lsl.l #4,%d4
	move.l %d0,%d2
	jbra .L294
.L295:
	move.l %d2,-(%sp)
	move.l (%a2),-(%sp)
	jbsr get_fat
	move.l %d0,%d2
	addq.l #8,%sp
	moveq #-1,%d1
	cmp.l %d0,%d1
	jbeq .L304
	moveq #1,%d0
	cmp.l %d2,%d0
	jbcc .L284
	move.l (%a2),%a0
	cmp.l 16(%a0),%d2
	jbcc .L284
	sub.l %d4,%d3
.L294:
	cmp.l %d3,%d4
	jbls .L295
	move.l %d2,-(%sp)
	move.l (%a2),-(%sp)
	jbsr clust2sect
	addq.l #8,%sp
	move.l %d0,%d1
.L293:
	move.l %d2,12(%a2)
	tst.l %d1
	jbeq .L284
	move.l %d3,%d0
	lsr.l #4,%d0
	add.l %d0,%d1
	move.l %d1,16(%a2)
	moveq #44,%d0
	add.l (%a2),%d0
	moveq #15,%d1
	and.l %d1,%d3
	lsl.l #5,%d3
	add.l %d3,%d0
	move.l %d0,20(%a2)
	moveq #0,%d0
	jbra .L298
.L304:
	moveq #1,%d0
	jbra .L298
.L284:
	moveq #2,%d0
.L298:
	movm.l -16(%fp),#0x41c
	unlk %fp
	rts
	.size	dir_sdi, .-dir_sdi
	.align	2
	.globl	f_readdir
	.type	f_readdir, @function
f_readdir:
	link.w %fp,#-12
	movm.l #0x3020,-(%sp)
	move.l 8(%fp),%a2
	move.l 12(%fp),%d3
	move.l %a2,-(%sp)
	jbsr validate
	move.l %d0,%d2
	addq.l #4,%sp
	jbne .L306
	tst.l %d3
	jbne .L308
	clr.l -(%sp)
	move.l %a2,-(%sp)
	jbsr dir_sdi
	move.l %d0,%d2
	addq.l #8,%sp
	jbra .L306
.L308:
	lea (-12,%fp),%a0
	move.l %a0,24(%a2)
	clr.l -(%sp)
	move.l %a2,-(%sp)
	jbsr dir_read
	addq.l #8,%sp
	moveq #4,%d1
	cmp.l %d0,%d1
	jbne .L310
	clr.l 16(%a2)
	jbra .L312
.L310:
	tst.l %d0
	jbne .L317
.L312:
	move.l %d3,-(%sp)
	move.l %a2,-(%sp)
	jbsr get_fileinfo
	clr.l -(%sp)
	move.l %a2,-(%sp)
	jbsr dir_next
	lea (16,%sp),%sp
	moveq #4,%d1
	cmp.l %d0,%d1
	jbeq .L314
.L317:
	move.l %d0,%d2
	jbra .L306
.L314:
	clr.l 16(%a2)
.L306:
	move.l %d2,%d0
	movm.l -24(%fp),#0x40c
	unlk %fp
	rts
	.size	f_readdir, .-f_readdir
	.align	2
	.globl	f_getcwd
	.type	f_getcwd, @function
f_getcwd:
	link.w %fp,#-64
	movm.l #0x3838,-(%sp)
	move.l 12(%fp),%d4
	move.l 8(%fp),%a0
	clr.b (%a0)
	clr.l -(%sp)
	pea 8(%fp)
	pea -64(%fp)
	jbsr find_volume
	move.l %d0,%d2
	lea (12,%sp),%sp
	jbne .L319
	moveq #-12,%d0
	add.l %fp,%d0
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,-40(%fp)
	move.w %d0,-38(%fp)
	move.w -64(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -62(%fp),%d0
	move.l %d0,%a0
	move.w 12(%a0),-56(%fp)
	move.w 14(%a0),-54(%fp)
	move.l %d4,%a2
	jbra .L321
.L322:
	pea 1.w
	lea (-64,%fp),%a3
	move.l %a3,-(%sp)
	lea dir_sdi,%a4
	jbsr (%a4)
	addq.l #8,%sp
	tst.l %d0
	jbne .L323
	clr.l -(%sp)
	move.l %a3,-(%sp)
	jbsr dir_read
	addq.l #8,%sp
	tst.l %d0
	jbne .L323
	move.w -44(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -42(%fp),%d0
	move.l %d0,-(%sp)
	move.w -64(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -62(%fp),%d0
	move.l %d0,-(%sp)
	jbsr ld_clust
	addq.l #8,%sp
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.w %d1,-56(%fp)
	move.w %d0,-54(%fp)
	clr.l -(%sp)
	move.l %a3,-(%sp)
	jbsr (%a4)
	addq.l #8,%sp
	tst.l %d0
	jbne .L323
.L346:
	clr.l -(%sp)
	lea (-64,%fp),%a3
	move.l %a3,-(%sp)
	jbsr dir_read
	addq.l #8,%sp
	tst.l %d0
	jbne .L327
	move.w -44(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -42(%fp),%d0
	move.l %d0,-(%sp)
	move.w -64(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -62(%fp),%d0
	move.l %d0,-(%sp)
	jbsr ld_clust
	addq.l #8,%sp
	cmp.l %d3,%d0
	jbeq .L329
	clr.l -(%sp)
	move.l %a3,-(%sp)
	jbsr dir_next
	addq.l #8,%sp
	tst.l %d0
	jbeq .L346
.L327:
	moveq #4,%d1
	cmp.l %d0,%d1
	jbeq .L331
	tst.l %d0
	jbne .L323
.L329:
	pea -36(%fp)
	pea -64(%fp)
	jbsr get_fileinfo
	lea (-27,%fp),%a1
	addq.l #8,%sp
.L333:
	tst.b (%a1)+
	jbne .L333
	lea (-36,%fp),%a0
	sub.l %a0,%a1
	lea (-10,%a1),%a3
	lea (-7,%a1),%a0
	cmp.l %a2,%a0
	jbhi .L335
	move.l %a2,%a0
	move.l %a3,%d0
	jbra .L337
.L338:
	subq.l #1,%a0
	subq.l #1,%d0
	move.b -27(%fp,%d0.l),(%a0,%a1.l)
.L337:
	move.l 8(%fp),%a1
	tst.l %d0
	jbne .L338
	move.l %a2,%a0
	sub.l %a3,%a0
	lea (-1,%a0),%a2
	move.b #47,(%a2,%a1.l)
.L321:
	move.w -56(%fp),%d0
	move.w %d0,%d3
	swap %d3
	mov.w -54(%fp),%d3
	tst.l %d3
	jbne .L322
	jbra .L351
.L341:
	move.b #47,(%a1)+
	jbra .L342
.L345:
	move.l 8(%fp),%a0
	move.b (%a2,%a0.l),(%a1)+
	addq.l #1,%a2
	cmp.l %a2,%d4
	jbhi .L345
.L342:
	clr.b (%a1)
	jbra .L319
.L331:
	move.l 8(%fp),%a1
	moveq #2,%d2
	jbra .L342
.L335:
	moveq #17,%d0
.L323:
	move.l 8(%fp),%a1
	move.l %d0,%d2
	jbra .L342
.L351:
	move.l 8(%fp),%a0
	move.b CurrVol,%d1
	add.b #48,%d1
	move.b %d1,(%a0)+
	move.b #58,(%a0)+
	move.l %a0,%a1
	cmp.l %a2,%d4
	jbne .L345
	jbra .L341
.L319:
	move.l %d2,%d0
	movm.l -88(%fp),#0x1c1c
	unlk %fp
	rts
	.size	f_getcwd, .-f_getcwd
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"\"*+,:;<=>?[]|\177"
	.text
	.align	2
	.type	follow_path, @function
follow_path:
	link.w %fp,#0
	movm.l #0x3e38,-(%sp)
	move.l 8(%fp),%a4
	move.l 12(%fp),%a2
	move.b (%a2),%d0
	cmp.b #47,%d0
	jbeq .L353
	cmp.b #92,%d0
	jbne .L355
.L353:
	addq.l #1,%a2
	clr.l 8(%a4)
	jbra .L356
.L355:
	move.l (%a4),%a0
	move.l 12(%a0),8(%a4)
.L356:
	cmp.b #31,(%a2)
	jbhi .L453
	clr.l -(%sp)
	move.l %a4,-(%sp)
	jbsr dir_sdi
	clr.l 20(%a4)
	addq.l #8,%sp
	jbra .L359
.L360:
	addq.l #1,%a2
.L453:
	move.b (%a2),%d0
	cmp.b #47,%d0
	jbeq .L360
	cmp.b #92,%d0
	jbeq .L360
	move.l 24(%a4),%a3
	moveq #0,%d0
.L363:
	move.b #32,(%a3,%d0.l)
	addq.l #1,%d0
	moveq #11,%d1
	cmp.l %d0,%d1
	jbne .L363
	cmp.b #46,(%a2)
	jbeq .L365
	moveq #8,%d6
	moveq #0,%d5
	moveq #0,%d4
	clr.b %d2
	jbra .L455
.L365:
	move.b #46,(%a3)
	move.b 1(%a2),%d0
	cmp.b #46,%d0
	jbeq .L368
	moveq #2,%d1
	jbra .L370
.L368:
	move.b #46,1(%a3)
	move.b 2(%a2),%d0
	cmp.b #46,%d0
	jbeq .L376
	moveq #3,%d1
.L370:
	cmp.b #47,%d0
	jbeq .L374
	cmp.b #92,%d0
	jbeq .L374
	cmp.b #32,%d0
	jbls .L447
	jbra .L376
.L374:
	add.l %d1,%a2
	lea (11,%a3),%a0
	cmp.b #32,%d0
	jbls .L378
	moveq #32,%d0
	jbra .L380
.L378:
	moveq #36,%d0
.L380:
	move.b %d0,(%a0)
	jbra .L381
.L455:
	move.b (%a2,%d5.l),%d1
	addq.l #1,%d5
	cmp.b #32,%d1
	jbls .L382
	cmp.b #47,%d1
	jbeq .L384
	cmp.b #92,%d1
	jbeq .L384
	cmp.b #46,%d1
	jbeq .L387
	cmp.l %d4,%d6
	jbhi .L389
.L387:
	moveq #8,%d0
	cmp.l %d6,%d0
	jbne .L376
	cmp.b #46,%d1
	jbne .L376
	add.b %d2,%d2
	add.b %d2,%d2
	moveq #11,%d6
	moveq #8,%d4
	jbra .L455
.L389:
	tst.b %d1
	jbge .L392
	or.b #3,%d2
	moveq #0,%d0
	move.b %d1,%d0
	lea ExCvt,%a0
	move.b -128(%a0,%d0.l),%d1
.L392:
	moveq #0,%d3
	move.b %d1,%d3
	lea .LC0,%a1
	jbra .L394
.L395:
	addq.l #1,%a1
.L394:
	move.b (%a1),%d0
	jbeq .L396
	ext.w %d0
	move.w %d0,%a0
	cmp.l %a0,%d3
	jbne .L395
	jbra .L376
.L396:
	move.b %d1,%d0
	add.b #-65,%d0
	cmp.b #25,%d0
	jbhi .L398
	or.b #2,%d2
	jbra .L400
.L398:
	move.b %d1,%d0
	add.b #-97,%d0
	cmp.b #25,%d0
	jbhi .L400
	or.b #1,%d2
	add.b #-32,%d1
.L400:
	move.b %d1,(%a3,%d4.l)
	addq.l #1,%d4
	jbra .L455
.L382:
	add.l %d5,%a2
	moveq #4,%d3
.L402:
	tst.l %d4
	jbeq .L376
	cmp.b #-27,(%a3)
	jbne .L404
	move.b #5,(%a3)
.L404:
	moveq #8,%d1
	cmp.l %d6,%d1
	jbne .L406
	add.b %d2,%d2
	add.b %d2,%d2
.L406:
	moveq #0,%d1
	move.b %d2,%d1
	moveq #3,%d0
	and.l %d1,%d0
	moveq #1,%d2
	cmp.l %d0,%d2
	jbne .L408
	or.b #16,%d3
.L408:
	moveq #12,%d0
	and.l %d0,%d1
	moveq #4,%d2
	cmp.l %d1,%d2
	jbne .L410
	or.b #8,%d3
.L410:
	move.b %d3,11(%a3)
	jbra .L381
.L440:
	move.l 16(%a4),-(%sp)
	move.l (%a4),-(%sp)
	jbsr move_window
	addq.l #8,%sp
	tst.l %d0
	jbne .L413
	move.l 20(%a4),%a1
	tst.b (%a1)
	jbeq .L415
	btst #3,11(%a1)
	jbne .L417
	move.l 24(%a4),%a3
	sub.l %a0,%a0
	jbra .L419
.L420:
	addq.l #1,%a0
	moveq #11,%d1
	cmp.l %a0,%d1
	jbeq .L421
.L419:
	move.b (%a3,%a0.l),%d2
	cmp.b (%a1,%a0.l),%d2
	jbeq .L420
	jbra .L417
.L421:
	btst #2,11(%a3)
	jbeq .L448
	jbra .L359
.L417:
	clr.l -(%sp)
	move.l %a4,-(%sp)
	jbsr dir_next
	jbra .L452
.L413:
	move.l 24(%a4),%a0
	move.b 11(%a0),%d1
	moveq #4,%d2
	cmp.l %d0,%d2
	jbne .L359
.L423:
	moveq #0,%d0
	move.b %d1,%d0
	moveq #4,%d1
	and.l %d0,%d1
	btst #5,%d0
	jbeq .L424
	clr.l 8(%a4)
	clr.l 20(%a4)
	tst.l %d1
	jbeq .L453
	moveq #0,%d0
	jbra .L359
.L424:
	tst.l %d1
	jbeq .L427
	moveq #4,%d0
	jbra .L359
.L448:
	btst #4,11(%a1)
	jbeq .L427
	move.l %a1,-(%sp)
	move.l (%a4),-(%sp)
	jbsr ld_clust
	addq.l #8,%sp
	move.l %d0,8(%a4)
	jbra .L453
.L376:
	moveq #6,%d0
	jbra .L359
.L427:
	moveq #5,%d0
	jbra .L359
.L447:
	add.l %d1,%a2
	lea (11,%a3),%a0
	jbra .L378
.L384:
	add.l %d5,%a2
	clr.b %d3
	jbra .L402
.L381:
	clr.l -(%sp)
	move.l %a4,-(%sp)
	jbsr dir_sdi
.L452:
	addq.l #8,%sp
	tst.l %d0
	jbne .L413
	jbra .L440
.L415:
	move.l 24(%a4),%a0
	move.b 11(%a0),%d1
	jbra .L423
.L359:
	movm.l -32(%fp),#0x1c7c
	unlk %fp
	rts
	.size	follow_path, .-follow_path
	.align	2
	.globl	f_stat
	.type	f_stat, @function
f_stat:
	link.w %fp,#-40
	movm.l #0x3020,-(%sp)
	move.l 12(%fp),%d3
	clr.l -(%sp)
	pea 8(%fp)
	lea (-40,%fp),%a2
	move.l %a2,-(%sp)
	jbsr find_volume
	move.l %d0,%d2
	lea (12,%sp),%sp
	jbne .L457
	moveq #-12,%d1
	add.l %fp,%d1
	move.l %d1,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-16(%fp)
	move.w %d1,-14(%fp)
	move.l 8(%fp),-(%sp)
	move.l %a2,-(%sp)
	jbsr follow_path
	move.l %d0,%d2
	addq.l #8,%sp
	jbne .L457
	move.w -20(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -18(%fp),%d0
	tst.l %d0
	jbne .L460
	move.b #6,%d2
	jbra .L457
.L460:
	tst.l %d3
	jbeq .L457
	move.l %d3,-(%sp)
	move.l %a2,-(%sp)
	jbsr get_fileinfo
	addq.l #8,%sp
.L457:
	move.l %d2,%d0
	movm.l -52(%fp),#0x40c
	unlk %fp
	rts
	.size	f_stat, .-f_stat
	.align	2
	.globl	f_opendir
	.type	f_opendir, @function
f_opendir:
	link.w %fp,#-16
	move.l %a2,-(%sp)
	move.l 8(%fp),%a2
	cmp.w #0,%a2
	jbne .L465
	moveq #9,%d0
	jbra .L467
.L465:
	clr.l -(%sp)
	pea 12(%fp)
	pea -4(%fp)
	jbsr find_volume
	lea (12,%sp),%sp
	tst.l %d0
	jbne .L468
	move.l -4(%fp),(%a2)
	lea (-16,%fp),%a0
	move.l %a0,24(%a2)
	move.l 12(%fp),-(%sp)
	move.l %a2,-(%sp)
	jbsr follow_path
	addq.l #8,%sp
	tst.l %d0
	jbne .L470
	move.l 20(%a2),%a0
	cmp.w #0,%a0
	jbeq .L472
	btst #4,11(%a0)
	jbne .L474
	move.b #5,%d0
	jbra .L468
.L474:
	move.l %a0,-(%sp)
	move.l -4(%fp),-(%sp)
	jbsr ld_clust
	addq.l #8,%sp
	move.l %d0,8(%a2)
.L472:
	move.l -4(%fp),%a0
	move.w 6(%a0),4(%a2)
	clr.l -(%sp)
	move.l %a2,-(%sp)
	jbsr dir_sdi
	addq.l #8,%sp
.L470:
	moveq #4,%d1
	cmp.l %d0,%d1
	jbeq .L476
	tst.l %d0
	jbeq .L467
.L468:
	clr.l (%a2)
	jbra .L467
.L476:
	moveq #5,%d0
	jbra .L468
.L467:
	move.l -20(%fp),%a2
	unlk %fp
	rts
	.size	f_opendir, .-f_opendir
	.align	2
	.globl	f_chdir
	.type	f_chdir, @function
f_chdir:
	link.w %fp,#-40
	movm.l #0x3020,-(%sp)
	clr.l -(%sp)
	pea 8(%fp)
	lea (-40,%fp),%a2
	move.l %a2,-(%sp)
	jbsr find_volume
	move.l %d0,%d3
	lea (12,%sp),%sp
	jbne .L480
	moveq #-12,%d1
	add.l %fp,%d1
	move.l %d1,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-16(%fp)
	move.w %d1,-14(%fp)
	move.l 8(%fp),-(%sp)
	move.l %a2,-(%sp)
	jbsr follow_path
	move.l %d0,%d3
	addq.l #8,%sp
	jbne .L482
	move.w -20(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -18(%fp),%d0
	tst.l %d0
	jbne .L484
	move.w -40(%fp),%a0
	move.w %a0,%d0
	swap %d0
	mov.w -38(%fp),%d0
	move.w -32(%fp),%a0
	move.w %a0,%d1
	swap %d1
	mov.w -30(%fp),%d1
	move.l %d0,%a0
	move.l %d1,12(%a0)
	jbra .L480
.L484:
	move.l %d0,%a0
	btst #4,11(%a0)
	jbeq .L486
	move.w -40(%fp),%d1
	move.w %d1,%d2
	swap %d2
	mov.w -38(%fp),%d2
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	jbsr ld_clust
	addq.l #8,%sp
	move.l %d2,%a0
	move.l %d0,12(%a0)
	jbra .L480
.L482:
	moveq #4,%d0
	cmp.l %d3,%d0
	jbne .L480
.L486:
	moveq #5,%d3
.L480:
	move.l %d3,%d0
	movm.l -52(%fp),#0x40c
	unlk %fp
	rts
	.size	f_chdir, .-f_chdir
	.align	2
	.globl	f_open
	.type	f_open, @function
f_open:
	link.w %fp,#-40
	movm.l #0x3830,-(%sp)
	move.l 8(%fp),%a3
	move.b 19(%fp),%d2
	cmp.w #0,%a3
	jbne .L491
	moveq #9,%d4
	jbra .L493
.L491:
	clr.l (%a3)
	clr.l -(%sp)
	pea 12(%fp)
	lea (-40,%fp),%a2
	move.l %a2,-(%sp)
	jbsr find_volume
	move.l %d0,%d4
	lea (12,%sp),%sp
	jbne .L493
	moveq #-12,%d1
	add.l %fp,%d1
	move.l %d1,%d0
	clr.w %d0
	swap %d0
	move.w %d0,-16(%fp)
	move.w %d1,-14(%fp)
	move.l 12(%fp),-(%sp)
	move.l %a2,-(%sp)
	jbsr follow_path
	move.l %d0,%d4
	move.w -20(%fp),%d1
	move.w %d1,%d0
	swap %d0
	mov.w -18(%fp),%d0
	move.l %d0,%a2
	addq.l #8,%sp
	tst.l %d4
	jbne .L493
	tst.l %d0
	jbne .L496
	move.b #6,%d4
	jbra .L493
.L496:
	btst #4,11(%a2)
	jbeq .L498
	moveq #4,%d4
	jbra .L493
.L498:
	and.b #1,%d2
	move.b %d2,6(%a3)
	clr.b 7(%a3)
	move.l %d0,-(%sp)
	move.w -40(%fp),%a0
	move.w %a0,%d3
	swap %d3
	mov.w -38(%fp),%d3
	move.l %d3,-(%sp)
	jbsr ld_clust
	addq.l #8,%sp
	move.l %d0,16(%a3)
	moveq #0,%d2
	move.b 29(%a2),%d2
	lsl.l #8,%d2
	move.b 31(%a2),%d1
	lsl.w #8,%d1
	swap %d1
	clr.w %d1
	moveq #0,%d0
	move.b 30(%a2),%d0
	swap %d0
	clr.w %d0
	or.l %d0,%d1
	or.b 28(%a2),%d1
	or.l %d1,%d2
	move.l %d2,12(%a3)
	clr.l 8(%a3)
	clr.l 24(%a3)
	move.l %d3,(%a3)
	move.l %d3,%a0
	move.w 6(%a0),4(%a3)
.L493:
	move.l %d4,%d0
	movm.l -60(%fp),#0xc1c
	unlk %fp
	rts
	.size	f_open, .-f_open
	.section	.rodata.str1.1
.LC1:
	.string	"C"
.LC2:
	.string	"D"
.LC3:
	.string	"E"
.LC4:
	.string	"F"
	.section	.rodata
	.align	4
	.type	str.1518, @object
	.size	str.1518, 16
str.1518:
	.long	.LC1
	.long	.LC2
	.long	.LC3
	.long	.LC4
	.type	ExCvt, @object
	.size	ExCvt, 128
ExCvt:
	.byte	67
	.byte	85
	.byte	69
	.byte	65
	.byte	65
	.byte	65
	.byte	65
	.byte	67
	.byte	69
	.byte	69
	.byte	69
	.byte	73
	.byte	73
	.byte	73
	.byte	65
	.byte	65
	.byte	69
	.byte	-110
	.byte	-110
	.byte	79
	.byte	79
	.byte	79
	.byte	85
	.byte	85
	.byte	89
	.byte	79
	.byte	85
	.byte	79
	.byte	-100
	.byte	79
	.byte	-98
	.byte	-97
	.byte	65
	.byte	73
	.byte	79
	.byte	85
	.byte	-91
	.byte	-91
	.byte	-90
	.byte	-89
	.byte	-88
	.byte	-87
	.byte	-86
	.byte	-85
	.byte	-84
	.byte	-83
	.byte	-82
	.byte	-81
	.byte	-80
	.byte	-79
	.byte	-78
	.byte	-77
	.byte	-76
	.byte	65
	.byte	65
	.byte	65
	.byte	-72
	.byte	-71
	.byte	-70
	.byte	-69
	.byte	-68
	.byte	-67
	.byte	-66
	.byte	-65
	.byte	-64
	.byte	-63
	.byte	-62
	.byte	-61
	.byte	-60
	.byte	-59
	.byte	65
	.byte	65
	.byte	-56
	.byte	-55
	.byte	-54
	.byte	-53
	.byte	-52
	.byte	-51
	.byte	-50
	.byte	-49
	.byte	-47
	.byte	-47
	.byte	69
	.byte	69
	.byte	69
	.byte	73
	.byte	73
	.byte	73
	.byte	73
	.byte	-39
	.byte	-38
	.byte	-37
	.byte	-36
	.byte	-35
	.byte	73
	.byte	-33
	.byte	79
	.byte	-31
	.byte	79
	.byte	79
	.byte	79
	.byte	79
	.byte	-26
	.byte	-24
	.byte	-24
	.byte	85
	.byte	85
	.byte	85
	.byte	89
	.byte	89
	.byte	-18
	.byte	-17
	.byte	-16
	.byte	-15
	.byte	-14
	.byte	-13
	.byte	-12
	.byte	-11
	.byte	-10
	.byte	-9
	.byte	-8
	.byte	-7
	.byte	-6
	.byte	-5
	.byte	-4
	.byte	-3
	.byte	-2
	.byte	-1
	.local	FatFs
	.comm	FatFs,16,4
	.local	Fsid
	.comm	Fsid,2,2
	.local	CurrVol
	.comm	CurrVol,1,1
	.ident	"GCC: (GNU) 4.1.1"
