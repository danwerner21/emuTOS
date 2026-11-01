	opt	l+,c+

*
*	HiSoft BASIC demo library ½ HiSoft 1987
*	version 1.1
*
*	SCS
*
* This library is an example of the procedure to follow when writing a user
* library. These are several routines which use all of the features and
* functions available to the user libraries.
*
* This library was written using DevpacST, the HiSoft assembly language
* development system.


	include	library.h	the standard library include file

	library	STUFF		library name

	xref	get_string	external references
	xref	get_array
	xref	make_string
	xref.l	gl_scratch	this is referenced off global!

	xdef	setbit		the names of the routines in the library
	xdef	getbit
	xdef	straint
	xdef	baint
	xdef	nullterm

	subdef	int,vlng	setbit takes an int and a long-variable
	fn_int	int,lng		getbit function returns an int
	subdef	str,aint,lng	straint takes a string, array of ints
*				and a long
	subdef	aint,aint,lng	baint takes 2 arrays of ints and a long
	subdef	vstr		nullterm takes a string-variable

	option	'uv'		underlines & variable checks

	libstart		the code follows


*
* This statement takes an int and a long as parameters and sets the bit
* specified by the int in the long.
*

setbit	move.l	4(sp),a0	pointer to the long
	move.l	(a0),d1		the long to be set
	move.w	8(sp),d2	which bit?
	ext.l	d2		paranoia
	bset.l	d2,d1		set the bit
	move.l	d1,(a0)		return the value to the variable
	rts


*
* This function takes an int and a long and checks if the bit specified by
* the int is set in the long. 0 is returned if not, -1 if the bit is set.
*

getbit	move.l	4(sp),d1	the long to be tested
	move.w	8(sp),d2	which bit?
	ext.l	d2		paranoia
	btst.l	d2,d1
	beq.s	nope		bit is cleared
	moveq	#-1,tos		set
	rts
nope	moveq	#0,tos		not set
	rts


*
* This routine copies a string into an array of integers.
*
* The descriptors of the string and array are passed, as well as the number
* of bytes to be copied. Checks are made as to the length of the string and
* array, as well as to the number of dimensions in the array.
*
* get_string is used to access the string, get_array to access the array
*

straint	move.l	4(sp),d5	how many bytes to move
	move.l	12(sp),a0	string descriptor
	bsr	get_string
	move.l	a1,-(sp)	save string address
	cmp.l	d4,d5		is amount to move > string?
	ble.s	oklen		no
	move.l	d4,d5		string isn't as long as he says

oklen	move.l	12(sp),a0	array descriptor
	moveq.l	#1,d0		one dimension only
	bsr	get_array
	cmp.l	d4,d5		is source > target?
	ble.s	oktrg1		no
	move.l	d4,d5		target's not big enough

oktrg1	move.l	(sp)+,a1	pop string address
	subq.l	#1,d5		dbf!

shovel	move.b	(a1)+,(a2)+
	dbf	d5,shovel
	rts


*
* This routine copies bytes from an array of integers into seperate
* elements of a target array of ints.
*
* This is useful if an array of ints has been used as a buffer, and the
* byte data needs sorting out. Checks are made as to the length of the
* source and target arrays, as well as to the number of dimensions in
* the arrays.
*
* get_array is used to access the arrays
*


baint	move.l	4(sp),d5	get the number of bytes to move

	move.l	12(sp),a0	the source array descriptor
	moveq	#1,d0		only 1 dimension
	bsr	get_array
	cmp.l	d4,d5		check for size
	ble.s	oksrc
	move.l	d4,d5	
oksrc	move.l	a2,-(sp)	1st element of source

	move.l	12(sp),a0	the target array
	moveq	#1,d0		only 1 dimension
	bsr	get_array
	cmp.l	d4,d5
	ble.s	oktrg
	move.l	d4,d5		it's not big enough

oktrg	move.l	(sp)+,a1	pop source array
	subq.l	#1,d5		dbf!

shovel2	addq.l	#1,a2
	move.b	(a1)+,(a2)+
	dbf	d5,shovel2
	rts


*
* This routine takes a string, null terminates it, and returns the string
*
* Uses get_string, gl_scratch, make_string
*

nullterm
	move.l	4(sp),a0	get the descriptor
	bsr	get_string
	cmp.l	#128,d4		check for size
	blt.s	oksiz
	moveq	#127,d4		reduce size to fit
oksiz	lea	gl_scratch(global),a0
	move.l	a0,a2		save address of copy
	move.w	d4,d5		save string length
	subq.w	#1,d4		subtract 1 for dbf
loop	move.b	(a1)+,(a0)+	copy string
	dbf	d4,loop
	move.l	a2,a1
	move.w	d5,d4
	clr.b	0(a1,d4.l)	null-terminate string
	addq.w	#1,d4		a byte was added
	move.l	4(sp),a0	the descriptor is needed
	bra	make_string	return the string to the variable & then
*				back to BASIC
