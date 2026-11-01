









	label	left

	tst.w		d7		
	jump	beq,l_0			

	swap		d0
1:
	swap		d0
	move.l		(a0),d7
	lsl.l		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	swap		d7
	and.w		d6,d7
	not.w		d6



	RandorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7



	nopW

	dbra		d6,2b
3:

	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	moveq		#-1,d6
	lsr.w		d2,d6


	not.w		d6
	and.w		d6,d7
	not.w		d6		

	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0


	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	l_0
	swap		d0
1:
	swap		d0
	move.l		(a0),d7
	lsl.l		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	swap		d7

	not.w		d7		

	and.w		d6,d7
	not.w		d6



	RandorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7

	not.w		d7		




	nopW

	dbra		d6,2b
3:

	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	moveq		#-1,d6
	lsr.w		d2,d6

	not.w		d7		

	not.w		d6
	and.w		d6,d7
	not.w		d6		




	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	right

	addq.l		#2,a2
	neg.w		d1

	tst.w		d7		
	jump	beq,r_0			

	swap		d0
1:
	swap		d0
	move.w		(a0),d7
	lsr.w		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6

	and.w		d6,d7
	not.w		d6



	RandorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:

	move.l		(a0),d7
	lsr.l		d1,d7




	nopW

	addq.l		#2,a0
	dbra		d6,2b
3:


	move.l		(a0),d7
	lsr.l		d1,d7



	moveq		#-1,d6
	lsr.w		d2,d6


	not.w		d6
	and.w		d6,d7
	not.w		d6		

	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	r_0
	swap		d0
1:
	swap		d0
	move.w		(a0),d7
	lsr.w		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6


	not.w		d7		

	and.w		d6,d7
	not.w		d6



	RandorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:

	move.l		(a0),d7
	lsr.l		d1,d7


	not.w		d7		




	nopW

	addq.l		#2,a0
	dbra		d6,2b
3:


	move.l		(a0),d7
	lsr.l		d1,d7


	not.w		d7		



	moveq		#-1,d6
	lsr.w		d2,d6


	not.w		d6
	and.w		d6,d7
	not.w		d6		

	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts



	label	single

	swap		d0
	moveq		#-1,d6
	lsr.w		d3,d6
	move.w		#-1,d4
	lsr.w		d2,d4
	not.w		d4
	and.w		d4,d6


	sub.w		d3,d1			
	jump	blt,sright

	move.w		d6,d3
	not.w		d6

	tst.w		d7		
	jump	beq,s_0			

1:
	move.l		(a0),d7
	lsl.l		d1,d7

	swap		d7
	and.w		d3,d7

	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0

	dbra		d0,1b



	moveq		#1,d0
	rts


	label	s_0
1:
	move.l		(a0),d7
	lsl.l		d1,d7

	swap		d7

	not.w		d7		

	and.w		d3,d7

	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0

	dbra		d0,1b



	moveq		#1,d0
	rts


	label	sright
	neg.w		d1

	move.w		d6,d3
	not.w		d6

	tst.w		d7		
	jump	beq,sr_0		

1:
	move.w		(a0),d7
	lsr.w		d1,d7


	and.w		d3,d7

	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0

	dbra		d0,1b



	moveq		#1,d0
	rts


	label	sr_0
1:
	move.w		(a0),d7
	lsr.w		d1,d7



	not.w		d7		

	and.w		d3,d7

	RandorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif

	add.w		a2,a0

	dbra		d0,1b



	moveq		#1,d0
	rts



	label	left_transp

	tst.w		d7
	jump	beq,l_transp_0		

	swap		d0
1:
	swap		d0
	move.l		(a0),d7
	lsl.l		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	swap		d7
	and.w		d6,d7

	RorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7

	RorW

	dbra		d6,2b
3:

	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d6
	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	l_transp_0
	swap		d0
1:
	swap		d0
	move.l		(a0),d7
	lsl.l		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	swap		d7
	and.w		d6,d7
	not.w		d7			

	RandW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	not.w		d7			

	RandW

	dbra		d6,2b
3:

	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d7
	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	right_transp


	addq.l		#2,a2
	neg.w		d1

	tst.w		d7
	jump	beq,r_transp_0		

	swap		d0
1:
	swap		d0
	move.w		(a0),d7
	lsr.w		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	and.w		d6,d7

	RorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	move.l		(a0),d7
	lsr.l		d1,d7

	RorW

	addq.l		#2,a0
	dbra		d6,2b
3:

	move.l		(a0),d7
	lsr.l		d1,d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d6
	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	r_transp_0
	swap		d0
1:
	swap		d0
	move.w		(a0),d7
	lsr.w		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	and.w		d6,d7
	not.w		d7

	RandW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	move.l		(a0),d7
	lsr.l		d1,d7
	not.w		d7

	RandW

	addq.l		#2,a0
	dbra		d6,2b
3:

	move.l		(a0),d7
	lsr.l		d1,d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d7
	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	single_transp

	swap		d0
	moveq		#-1,d6
	lsr.w		d3,d6
	move.w		#-1,d4
	lsr.w		d2,d4
	not.w		d4
	and.w		d4,d6

	sub.w		d3,d1			
	jump	blt,sright_transp

	tst.w		d7
	jump	beq,s_transp_0		
1:
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7

	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts


	label	s_transp_0
	not.w		d6
1:
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7

	not.w		d7
	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts


	label	sright_transp
	neg.w		d1

	tst.w		d7
	jump	beq,sr_transp_0		
1:
	move.w		(a0),d7
	lsr.w		d1,d7

	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts


	label	sr_transp_0
	not.w		d6
1:
	move.w		(a0),d7
	lsr.w		d1,d7

	not.w		d7
	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts



	label	left_xor
	swap		d0
1:
	swap		d0
	move.l		(a0),d7
	lsl.l		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	swap		d7
	and.w		d6,d7
	not.w		d6

	ReorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7

	ReorW

	dbra		d6,2b
3:

	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d6
	and.w		d6,d7

	ReorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	right_xor

	addq.l		#2,a2
	neg.w		d1
	swap		d0
1:
	swap		d0
	move.w		(a0),d7
	lsr.w		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	and.w		d6,d7
	not.w		d6

	ReorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	move.l		(a0),d7
	lsr.l		d1,d7

	ReorW

	addq.l		#2,a0
	dbra		d6,2b
3:

	move.l		(a0),d7
	lsr.l		d1,d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d6
	and.w		d6,d7

	ReorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	single_xor
	sub.w		d3,d1			
	jump	blt,sright_xor

	swap		d0
	moveq		#-1,d6
	lsr.w		d3,d6
	move.w		#-1,d4
	lsr.w		d2,d4
	not.w		d4
	and.w		d4,d6
1:
	move.l		(a0),d7
	lsl.l		d1,d7

	swap		d7
	and.w		d6,d7

	ReorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts


	label	sright_xor
	neg.w		d1
	swap		d0

	moveq		#-1,d6
	lsr.w		d3,d6
	move.w		#-1,d4
	lsr.w		d2,d4
	not.w		d4
	and.w		d4,d6
1:
	move.w		(a0),d7
	lsr.w		d1,d7

	and.w		d6,d7

	ReorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts



	label	left_revtransp

	tst.w		d7
	jump	beq,l_revtransp_0		

	swap		d0
1:
	swap		d0
	move.l		(a0),d7
	lsl.l		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	swap		d7
	not.w		d7
	and.w		d6,d7

	RorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	not.w		d7

	RorW

	dbra		d6,2b
3:

	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	not.w		d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d6
	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	l_revtransp_0
	swap		d0
1:
	swap		d0
	move.l		(a0),d7
	lsl.l		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	swap		d7
	not.w		d7
	and.w		d6,d7
	not.w		d7			

	RandW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7


	RandW

	dbra		d6,2b
3:

	addq.l		#2,a0
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7
	moveq		#-1,d6
	lsr.w		d2,d6

	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	right_revtransp

	addq.l		#2,a2
	neg.w		d1

	tst.w		d7
	jump	beq,r_revtransp_0		

	swap		d0
1:
	swap		d0
	move.w		(a0),d7
	lsr.w		d1,d7
	not.w		d7
	moveq		#-1,d6
	lsr.w		d3,d6
	and.w		d6,d7

	RorW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	move.l		(a0),d7
	lsr.l		d1,d7
	not.w		d7

	RorW

	addq.l		#2,a0
	dbra		d6,2b
3:

	move.l		(a0),d7
	lsr.l		d1,d7
	not.w		d7
	moveq		#-1,d6
	lsr.w		d2,d6
	not.w		d6
	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	r_revtransp_0
	swap		d0
1:
	swap		d0
	move.w		(a0),d7
	lsr.w		d1,d7
	moveq		#-1,d6
	lsr.w		d3,d6
	not.w		d7
	and.w		d6,d7
	not.w		d7

	RandW

	move.w		d0,d6			
	beq		3f
	subq.w		#1,d6
2:
	move.l		(a0),d7
	lsr.l		d1,d7


	RandW

	addq.l		#2,a0
	dbra		d6,2b
3:

	move.l		(a0),d7
	lsr.l		d1,d7
	moveq		#-1,d6
	lsr.w		d2,d6

	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	swap		d0
	dbra		d0,1b

	moveq		#1,d0
	rts


	label	single_revtransp
	swap		d0
	moveq		#-1,d6
	lsr.w		d3,d6
	move.w		#-1,d4
	lsr.w		d2,d4
	not.w		d4
	and.w		d4,d6

	sub.w		d3,d1			
	jump	blt,sright_revtransp

	tst.w		d7
	jump	beq,s_revtransp_0		
1:
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7

	not.w		d7
	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts


	label	s_revtransp_0
	not.w		d6
1:
	move.l		(a0),d7
	lsl.l		d1,d7
	swap		d7


	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts


	label	sright_revtransp
	neg.w		d1

	tst.w		d7
	jump	beq,sr_revtransp_0		
1:
	move.w		(a0),d7
	lsr.w		d1,d7

	not.w		d7
	and.w		d6,d7

	RorWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts


	label	sr_revtransp_0
	not.w		d6
1:
	move.w		(a0),d7
	lsr.w		d1,d7


	or.w		d6,d7

	RandWl

	add.w		a3,a1
	.ifne	both
	add.w		a3,a4
	.endif
	add.w		a2,a0

	dbra		d0,1b

	moveq		#1,d0
	rts

